
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stream_lib;
use stream_lib.stream_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;


entity tb_mac_to_stream is
end entity;

architecture rtl of tb_mac_to_stream is

    signal clk : std_logic;
    signal rst : std_logic := '0';
    signal empty : std_logic;
    signal rd_en : std_logic;
    signal data_i : std_logic_vector(7 downto 0);
    signal data_vld : std_logic;
    signal data_rdy : std_logic;
    signal data_o : t_stream;
    signal pause_vld : std_logic := '0';

    constant clk_period : time := 12.5 ns;

    constant gen_data_fifo_idx :  integer := 0;
    constant check_data_fifo_idx :  integer := 1;


    constant buffer_size_bits: integer := 512;
   
    signal valid_probability : integer := 100;

begin
    p_input_data : process
    begin
        await_unblock_flag("mac_data_flag", 1 us, "waiting for mac_data_flag to be unlocked");
        --generate data, emulating the mac interface. 
        empty <= '1';
        -- Wait for data
        wait_data_loop : while uvvm_fifo_get_count(gen_data_fifo_idx) = 0 loop
            wait until rising_edge(clk);
            data_i <= uvvm_fifo_get(gen_data_fifo_idx, data_i'length);
        end loop wait_data_loop;
        
        empty <= '0';

        while uvvm_fifo_get_count(gen_data_fifo_idx) /= 0 loop
            if rd_en = '1' then
                data_i <= uvvm_fifo_get(gen_data_fifo_idx, data_i'length);
            end if;
            wait until falling_edge(clk);
        end loop;

    end process;

    p_check_output_data : process
        variable v_expected : t_stream;
    begin
        await_unblock_flag("mac_data_flag", 1 us, "waiting for mac_data_flag to be unlocked");
        log("Getting data");

        get_data_loop : while true loop 
            wait until falling_edge(clk);
            if data_vld and data_rdy then
                -- Check data against expected
                v_expected := slv_to_stream(uvvm_fifo_get(check_data_fifo_idx, 32+2));
                check_value(data_o.data, v_expected.data, "check output data as expected");
                if data_o.tag /= v_expected.tag then
                    alert(TB_ERROR, "wrong tag, received: " & stream_tag_to_string(data_o.tag) & " expected: " & stream_tag_to_string(v_expected.tag));                    
                end if;

            end if;
        end loop get_data_loop; 

        wait;    
    end process;

    p_pause_pattern : process 
        variable v_percent : integer range 0 to 100;
    begin
        wait until rising_edge(clk);
        v_percent := random(0, 100);
        pause_vld <= '0';
        if v_percent < valid_probability then
            pause_vld <= '1';
        end if;
    end process p_pause_pattern;

    data_rdy <= data_vld and pause_vld;


    p_main : process
        function to_slv(value : integer; length : integer) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(value, length));
        end function;

        procedure pd_gen_testdata  (constant void : t_void ) is
            variable v_check_data : std_logic_vector(31 downto 0);
            variable v_data : std_logic_vector(7 downto 0);
            variable v_tag : t_stream_tag;
            variable v_data_bytes : std_logic_vector(15 downto 0);
            variable v_pkt_length : natural;
        begin
            -- header
            uvvm_fifo_put(check_data_fifo_idx, stream_to_slv((data=>x"00000001", tag=>SOF)));

            v_pkt_length := 24;
            v_data_bytes := to_slv(v_pkt_length, 16);
            uvvm_fifo_put(gen_data_fifo_idx, x"00"); --Extra byte, bug in mac?
            uvvm_fifo_put(gen_data_fifo_idx, v_data_bytes(15 downto 8));
            uvvm_fifo_put(gen_data_fifo_idx, v_data_bytes(7 downto 0));

            for i in 0 to v_pkt_length-1 loop
                v_data := to_slv(i, 8);
                uvvm_fifo_put(gen_data_fifo_idx, v_data);
                v_check_data(31-(8*(i mod 4)) downto 24 - (8 * (i mod 4))) := v_data;
                if  i mod 4 = 3 then  
                    log(to_string(i) & " Pushing data: " & to_hstring(v_check_data));
                    if i = 23 then
                        v_tag := EOF;
                        log("EOF added");
                    else
                        v_tag := DATA;
                    end if;
                    
                    uvvm_fifo_put(check_data_fifo_idx, stream_to_slv((data=>v_check_data, tag => v_tag)));
                end if;
            end loop;

        end procedure;
    begin
        log("Starting simulation");
        gen_pulse(rst, clk, 10, "Rst signal");
        uvvm_fifo_init(gen_data_fifo_idx, buffer_size_bits-1);
        uvvm_fifo_init(check_data_fifo_idx, buffer_size_bits-1);
        unblock_flag("mac_data_flag", "unblocking data flag", global_trigger);
        
        log("Check defaults");
        check_value(rd_en, '0', "Mac read en out should be low");
        check_value(data_vld, '0', "data_vld_o should default be low");


        log("Test readout frame no pause pattern.");
        valid_probability <= 100;
        pd_gen_testdata(VOID);

        wait for 1 us;
        check_value(uvvm_fifo_get_count(check_data_fifo_idx), 0, "Check all verfication data is consumed");

        log("Test readout frame with pause pattern.");
        valid_probability <= 10;
        pd_gen_testdata(VOID);
        
        wait for 1 us;
        check_value(uvvm_fifo_get_count(check_data_fifo_idx), 0, "Check all verfication data is consumed");

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;

    --------
    -- Clocking
    --------
    clock_generator(clk, clk_period);

    ------------
    -- DUT
    ------------
    i_mac_to_stream_inst: entity stream_lib.mac_to_stream
     port map(
        clk_i => clk,
        rst_i => rst,
        empty_i => empty,
        rd_en_o => rd_en,
        data_i => data_i,
        data_o => data_o,
        data_vld_o => data_vld,
        data_rdy_i => data_rdy
    );


end architecture;