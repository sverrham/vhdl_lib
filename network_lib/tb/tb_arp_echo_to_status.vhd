
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

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;

entity tb_arp_echo_to_status is
end entity;

architecture rtl of tb_arp_echo_to_status is

    signal clk_i : std_logic := '0';
    signal rst_i : std_logic := '1';
    signal stream_slv : std_logic_vector(33 downto 0);
    signal stream_i : t_stream;
    signal stream_vld_i : std_logic := '0';
    signal stream_rdy_o : std_logic;
    signal status_o : t_status;
    signal status_vld_o : std_logic;
    signal status_rdy_i : std_logic;

    constant STATUS_VVC_IDX : integer := 1;
    constant STREAM_VVC_IDX : integer := 2;
begin

    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

    clock_generator(clk_i, 8 ns);

    p_stimulus : process
    procedure add_data (constant data_input : std_logic_vector(31 downto 0); constant last_word : boolean) is
    begin
        if last_word then
            vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>data_input, tag=>EOF)), "EOF");
        else
            vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>data_input, tag=>DATA)), "DATA");
        end if;

        for i in 0 to 3 loop
            if last_word and i = 3 then
                VLD_RDY_VVC_SB.add_expected(x"0000_000" & "00" & status_to_slv((data=>data_input(31-i*8 downto 24-i*8), tag => EOF)), "DATA");
            else
                VLD_RDY_VVC_SB.add_expected(x"0000_000" & "00" & status_to_slv((data=>data_input(31-i*8 downto 24-i*8), tag => DATA)), "DATA");
            end if;
            vld_rdy_receive(VLD_RDY_VVCT, STATUS_VVC_IDX, "DATA", TO_SB);
        end loop;
    end procedure add_data;

    procedure generate_test_data (constant void : t_void) is
    begin
        vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>x"0000_00" & mac_raw_stream, tag=>SOF)), "SOF");
        VLD_RDY_VVC_SB.add_expected(x"0000_000" & "00" & status_to_slv((data=>X"02", tag=>SOF)), "SOF");
        vld_rdy_receive(VLD_RDY_VVCT, STATUS_VVC_IDX, "SOF", TO_SB);
        add_data(x"01020304", false);
        add_data(x"05060708", false);
        add_data(x"0a0b0c0d", false);
        add_data(x"08060000", false);
        add_data(x"01234567", false); 
        add_data(x"00000000", true); 

    end procedure generate_test_data;

    procedure gen_random_data(constant void : t_void) is
        variable length : integer;
    begin
        length := random(4, 10);
        vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>x"0000_00" & mac_raw_stream, tag=>SOF)), "SOF");
        for i in 0 to length-1 loop
            vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>random(32), tag=>DATA)), "DATA");
        end loop;
        vld_rdy_write(VLD_RDY_VVCT, STREAM_VVC_IDX, stream_to_slv((data=>random(32), tag=>EOF)), "EOF");
        
    end procedure gen_random_data;

    begin
        await_uvvm_initialization(VOID);

        log("Starting test");

        log("Check default values");
        unblock_flag("init_fifo_flag", "unblocking data flag", global_trigger);
        wait for 100 ns;
        wait until rising_edge(clk_i);
        rst_i <= '0';
        wait until rising_edge(clk_i);

        check_value(stream_rdy_o, '1', "stream_rdy_o");
        check_value(status_vld_o, '0', "status_vld_o");
        check_value(status_o.data, x"0", "status_o.data");

        wait for 100 ns;
        wait until rising_edge(clk_i);
        log("Test 1: Send a packet with ethertype 0x0806");
        shared_vld_rdy_vvc_config(RX, STATUS_VVC_IDX).bfm_config.pause_probability := 0.0;
        generate_test_data(void);
        await_completion(ALL_VVCS, 2 us, "Wait for data done");

        shared_vld_rdy_vvc_config(RX, STATUS_VVC_IDX).bfm_config.pause_probability := 0.2;
        gen_random_data(void);
        generate_test_data(void);
        await_completion(ALL_VVCS, 2 us, "Wait for data done");
        
        shared_vld_rdy_vvc_config(RX, STATUS_VVC_IDX).bfm_config.pause_probability := 0.7;
        shared_vld_rdy_vvc_config(TX, STREAM_VVC_IDX).bfm_config.pause_probability := 0.7;
        gen_random_data(void);
        gen_random_data(void);
        generate_test_data(void);
        await_completion(ALL_VVCS, 5 us, "Wait for data done");
        
        shared_vld_rdy_vvc_config(RX, STATUS_VVC_IDX).bfm_config.pause_probability := 0.8;
        shared_vld_rdy_vvc_config(TX, STREAM_VVC_IDX).bfm_config.pause_probability := 0.9;
        generate_test_data(void);
        await_completion(ALL_VVCS, 2 us, "Wait for data done");

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;

    dut : entity work.arp_echo_to_status
        port map (
            clk_i => clk_i,
            rst_i => rst_i,
            stream_i => stream_i,
            stream_vld_i => stream_vld_i,
            stream_rdy_o => stream_rdy_o,
            status_o => status_o,
            status_vld_o => status_vld_o,
            status_rdy_i => status_rdy_i
        );
    
    i_status_vvc : entity vip_vld_rdy.vld_rdy_vvc
        generic map (
            GC_DATA_WIDTH => 10,
            GC_INSTANCE_IDX => STATUS_VVC_IDX)
        port map (
            tx_data => open,
            tx_data_vld => open,
            tx_data_rdy => '0',
            rx_data => status_to_slv(status_o),
            rx_data_vld => status_vld_o,
            rx_data_rdy => status_rdy_i,
            clk => clk_i
            );
 
    i_stream_vvc: entity vip_vld_rdy.vld_rdy_vvc
        generic map (
            GC_DATA_WIDTH => 34,
            GC_INSTANCE_IDX => STREAM_VVC_IDX)
        port map (
            tx_data => stream_slv,  
            tx_data_vld => stream_vld_i,
            tx_data_rdy => stream_rdy_o,
            rx_data => x"0000_0000" & "00",
            rx_data_vld => '0',
            rx_data_rdy => open,
            clk => clk_i
            );

        stream_i <= slv_to_stream(stream_slv);

end architecture;