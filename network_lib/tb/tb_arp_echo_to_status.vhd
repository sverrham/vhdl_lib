
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stream_lib;
use stream_lib.stream_pkg.all;
use stream_lib.status_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;


entity tb_arp_echo_to_status is
end entity;

architecture rtl of tb_arp_echo_to_status is

    signal clk_i : std_logic := '0';
    signal stream_i : t_stream;
    signal stream_vld_i : std_logic := '0';
    signal stream_rdy_o : std_logic;
    signal status_o : t_status;
    signal status_vld_o : std_logic;
    signal status_rdy_i : std_logic;

    signal pause_vld : std_logic := '1';
    signal valid_probability : integer := 100;

    constant gen_data_fifo_idx :  integer := 0;
    constant status_data_fifo_idx :  integer := 1;
    constant buffer_size_bits: integer := 512;
begin

    clock_generator(clk_i, 8 ns);

    p_input_data : process
        variable data : std_logic_vector(33 downto 0);
    begin
        await_unblock_flag("init_fifo_flag", 1 us, "waiting for init_fifo_flag to be unlocked");
        
        stream_vld_i <= '0';

        -- Wait for data
        wait_data_loop : while uvvm_fifo_get_count(gen_data_fifo_idx) = 0 loop
            wait until rising_edge(clk_i);
        end loop wait_data_loop;
        data := uvvm_fifo_get(gen_data_fifo_idx, data'length);
        stream_i <= slv_to_stream(data);
        stream_vld_i <= '1';
        
        while uvvm_fifo_get_count(gen_data_fifo_idx) /= 0 loop
            if stream_vld_i = '1' and stream_rdy_o = '1' then
                data := uvvm_fifo_get(gen_data_fifo_idx, data'length);
                stream_i <= slv_to_stream(data);
                stream_vld_i <= '0';
            elsif stream_vld_i = '0' then
                stream_vld_i <= '1';
            end if;
            wait until rising_edge(clk_i);
        end loop;

    end process;

    p_pause_pattern : process
        variable v_percent : integer range 0 to 100;
    begin
        wait until rising_edge(clk_i);
        v_percent := random(0, 100);
        pause_vld <= '0';
        if v_percent < valid_probability then
            pause_vld <= '1';
        end if;
    end process;
    
    status_rdy_i <= '1' and pause_vld;
    
    p_check_output : process
        variable data : std_logic_vector(7 downto 0);
    begin

        while true loop
            wait until rising_edge(clk_i);
            -- wait for output data, check it when it comes and we accept it.
            if status_vld_o = '1' and status_rdy_i = '1' then
                data := uvvm_fifo_get(status_data_fifo_idx, data'length);
                check_value(status_o.data, data, "status_o.data");
            end if;
        end loop;  
    end process;


    p_stimulus : process
    procedure add_data (constant data_input : std_logic_vector(31 downto 0)) is
    begin
        uvvm_fifo_put(gen_data_fifo_idx, stream_to_slv((data=>data_input, tag=>DATA)));
        for i in 0 to 3 loop
            uvvm_fifo_put(status_data_fifo_idx, data_input(31-i*8 downto 24-i*8));
        end loop;
    end procedure add_data;

    procedure generate_test_data (constant void : t_void) is
    begin
        uvvm_fifo_put(gen_data_fifo_idx, stream_to_slv((data=>x"000000" & mac_raw_stream, tag=>SOF)));
        uvvm_fifo_put(status_data_fifo_idx, x"02");
        add_data(x"01020304");
        add_data(x"05060708");
        add_data(x"0a0b0c0d");
        add_data(x"08060000");
        add_data(x"01234567"); 
        uvvm_fifo_put(gen_data_fifo_idx, stream_to_slv((data=>x"00000000", tag=>EOF)));

    end procedure generate_test_data;

    begin
        log("Starting test");
        log("Check default values");
        uvvm_fifo_init(gen_data_fifo_idx, buffer_size_bits-1);
        uvvm_fifo_init(status_data_fifo_idx, buffer_size_bits-1);
        unblock_flag("init_fifo_flag", "unblocking data flag", global_trigger);
        wait for 100 ns;
        wait until rising_edge(clk_i);

        check_value(stream_rdy_o, '1', "stream_rdy_o");
        check_value(status_vld_o, '0', "status_vld_o");
        check_value(status_o.data, x"0", "status_o.data");

        wait for 100 ns;
        wait until rising_edge(clk_i);
        log("Test 1: Send a packet with ethertype 0x0806");
        valid_probability <= 25;
        generate_test_data(void);

        wait for 1 us;
        check_value(uvvm_fifo_get_count(gen_data_fifo_idx), 0, "gen_data_fifo_idx");
        check_value(uvvm_fifo_get_count(status_data_fifo_idx), 0, "gen_data_fifo_idx");

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;

    dut : entity work.arp_echo_to_status
        port map (
            clk_i => clk_i,
            stream_i => stream_i,
            stream_vld_i => stream_vld_i,
            stream_rdy_o => stream_rdy_o,
            status_o => status_o,
            status_vld_o => status_vld_o,
            status_rdy_i => status_rdy_i
        );

end architecture;