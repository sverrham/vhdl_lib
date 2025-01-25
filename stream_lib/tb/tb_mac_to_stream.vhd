
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stream_lib;
use stream_lib.stream_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;


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

    constant clk_period : time := 12.5 ns;
    constant gen_data_fifo_idx :  integer := 0;
    constant buffer_size_bits: integer := 512;
   
    constant STREAM_VVC_IDX : integer := 1;

begin
    
    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

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

    p_main : process
        function to_slv(value : integer; length : integer) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(value, length));
        end function;


        procedure expect_receive(constant data : std_logic_vector; constant msg : string) is
        begin
            VLD_RDY_VVC_SB.add_expected("000000" & data, msg);
            vld_rdy_receive(VLD_RDY_VVCT, STREAM_VVC_IDX, msg, TO_SB);
        end procedure expect_receive;


        procedure pd_gen_testdata  (constant void : t_void ) is
            variable v_check_data : std_logic_vector(31 downto 0);
            variable v_data : std_logic_vector(7 downto 0);
            variable v_tag : t_stream_tag;
            variable v_data_bytes : std_logic_vector(15 downto 0);
            variable v_pkt_length : natural;
        begin
            -- header
            expect_receive(stream_to_slv((data=>x"0000_0001", tag=>SOF)), "SOF");

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
                    
                    expect_receive(stream_to_slv((data=>v_check_data, tag => v_tag)), "Data");
                end if;
            end loop;

        end procedure;
    begin
        await_uvvm_initialization(VOID);

        log("Starting simulation");
        gen_pulse(rst, clk, 10, "Rst signal");
        uvvm_fifo_init(gen_data_fifo_idx, buffer_size_bits-1);
        unblock_flag("mac_data_flag", "unblocking data flag", global_trigger);
        
        log("Check defaults");
        check_value(rd_en, '0', "Mac read en out should be low");
        check_value(data_vld, '0', "data_vld_o should default be low");


        log("Test readout frame no pause pattern.");
        shared_vld_rdy_vvc_config(RX, STREAM_VVC_IDX).bfm_config.pause_probability := 0.0;
        pd_gen_testdata(VOID);
        await_completion(ALL_VVCS, 1 us, "Wait for data done");

        log("Test readout frame with pause pattern.");
        shared_vld_rdy_vvc_config(RX, STREAM_VVC_IDX).bfm_config.pause_probability := 0.9;
        pd_gen_testdata(VOID);
        await_completion(ALL_VVCS, 1 us, "Wait for data done");

        check_value(VLD_RDY_VVC_SB.is_empty(VOID), ERROR, "SB is not empty");
        VLD_RDY_VVC_SB.report_counters(VOID);
 
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

    i_vld_rdy_vvc : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
        GC_DATA_WIDTH => 34,
        GC_INSTANCE_IDX => STREAM_VVC_IDX 
    )
    port map (
        tx_data => open,
        tx_data_vld => open,
        tx_data_rdy => '0',
        rx_data => stream_to_slv(data_o),
        rx_data_vld => data_vld,
        rx_data_rdy => data_rdy,
        clk => clk
    );



end architecture;