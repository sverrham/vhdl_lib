
-- hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;

entity vvc_tb is
end entity vvc_tb;

architecture rtl of vvc_tb is

    signal clk : std_logic := '0';

    signal tx_data : std_logic_vector(31 downto 0);
    signal tx_data_vld : std_logic;
    signal tx_data_rdy : std_logic := '0';

    -- signal rx_data : std_logic_vector(31 downto 0);
    -- signal rx_data_vld : std_logic;
    -- signal rx_data_rdy : std_logic;

    constant clock_period : time := 8 ns;
begin


    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

    clock_generator(clk, clock_period);

    main : process

        procedure base_test(VOID : t_void) is
        begin
            log("Base test");
 
            vld_rdy_write(VLD_RDY_VVCT, 1, x"12345678", "Something"); 
            insert_delay(VLD_RDY_VVCT, 1, TX, 100 ns);
            vld_rdy_write(VLD_RDY_VVCT, 1, x"12345679", "Something"); 
            
            VLD_RDY_VVC_SB.add_expected(X"0012345678", "expect 1");
            VLD_RDY_VVC_SB.add_expected(X"0012345679", "expect 2");
            

            vld_rdy_receive(VLD_RDY_VVCT, 1, "Something else", TO_SB);
            -- v_cmd_idx := get_last_received_cmd_idx(VLD_RDY_VVCT, 1, RX, "last command");
            -- await_completion(VLD_RDY_VVCT, 1, RX, v_cmd_idx, 100 ns, "fetch read result");
            -- fetch_result(VLD_RDY_VVCT, 1, RX, v_cmd_idx, v_data, v_is_ok, "fetch result"); 
            -- log("Result: " & to_hstring(v_data));

            vld_rdy_receive(VLD_RDY_VVCT, 1, "Something else 2", TO_SB);
            -- v_cmd_idx := get_last_received_cmd_idx(VLD_RDY_VVCT, 1, RX, "last command");
            -- await_completion(VLD_RDY_VVCT, 1, RX, v_cmd_idx, 200 ns, "fetch read result");
            -- fetch_result(VLD_RDY_VVCT, 1, RX, v_cmd_idx, v_data, v_is_ok, "fetch result"); 
            -- log("Result 2: " & to_hstring(v_data));


            await_completion(ALL_VVCS, 1 ms, "Wait for data done");

            check_value(VLD_RDY_VVC_SB.is_empty(VOID), ERROR, "SB is not empty");
            VLD_RDY_VVC_SB.report_counters(VOID);

            VLD_RDY_VVC_SB.reset("Clear SB for next test");

        end procedure;

        procedure test_with_pause_pattern(channel : t_sub_channel) is
            variable start_time : time;
            variable end_time : time;
            variable seed : std_logic_vector(31 downto 0);
            variable data_to_send : std_logic_vector(31 downto 0);
            variable loops : integer;
        begin
            log("Testing with pause pattern TX");
            shared_vld_rdy_vvc_config(channel, 1).bfm_config.pause_probability := 0.5;
            -- Test should not finish in number of transaction cycles.
            loops := 10;
            start_time := now;
            -- loop and send/verify receive 4 words
            for i in 1 to loops loop
                -- seed := X"5555_5678";
                seed := random(32);
                data_to_send := std_logic_vector(unsigned(seed)+i);
                vld_rdy_write(VLD_RDY_VVCT, 1, data_to_send, "Something"); 
                VLD_RDY_VVC_SB.add_expected(X"00" & data_to_send, "expect 1");
                vld_rdy_receive(VLD_RDY_VVCT, 1, "Something else", TO_SB);
            end loop;

            await_completion(ALL_VVCS, 1 ms, "Wait for data done");

            end_time := now;
            check_value_in_range(end_time - start_time, clock_period* (loops + 1), clock_period*100, "Test should not finish in number of transaction cycles");

            check_value(VLD_RDY_VVC_SB.is_empty(VOID), ERROR, "SB is not empty");
            VLD_RDY_VVC_SB.report_counters(VOID);

            shared_vld_rdy_vvc_config(channel, 1).bfm_config.pause_probability := 0.0;
            VLD_RDY_VVC_SB.reset("Clear SB for next test");


        end procedure;

        procedure test_throughput(cycles_between: integer) is
            variable start_time : time;
            variable end_time : time;
            variable seed : std_logic_vector(31 downto 0);
            variable data_to_send : std_logic_vector(31 downto 0);
            variable loops : integer;
        begin
            log("Test that we can send and receive in same cycle");
            loops := 10; 
            start_time := now;
            for i in 1 to loops loop
                seed := X"5555_5678";
                data_to_send := std_logic_vector(unsigned(seed)+i);
                vld_rdy_write(VLD_RDY_VVCT, 1, data_to_send, "Something"); 
                VLD_RDY_VVC_SB.add_expected(X"00" & data_to_send, "expect 1");
                vld_rdy_receive(VLD_RDY_VVCT, 1, "Something else", TO_SB);
                insert_delay(VLD_RDY_VVCT, 1, TX, clock_period*cycles_between);
                
            end loop; 
            await_completion(ALL_VVCS, 1 ms, "Wait for data done");
            end_time := now;
            check_value(end_time - start_time, clock_period * (loops * (cycles_between+1)), "two cycle pr transaction only");

            check_value(VLD_RDY_VVC_SB.is_empty(VOID), ERROR, "SB is not empty");
            VLD_RDY_VVC_SB.report_counters(VOID);
        end procedure;

    begin
        await_uvvm_initialization(VOID);
        log("init done");

        ------------------------------
        base_test(VOID);
        ------------------------------
        test_with_pause_pattern(TX);
        ------------------------------
        test_with_pause_pattern(RX);
        ------------------------------
        test_throughput(0);
        test_throughput(1);
        test_throughput(2);
        ------------------------------

        await_uvvm_completion(1 ns);
        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process main;


    i_vld_rdy_vvc : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
        GC_DATA_WIDTH => 32,
        GC_INSTANCE_IDX => 1
    )
    port map (
        tx_data => tx_data,
        tx_data_vld => tx_data_vld,
        tx_data_rdy => tx_data_rdy,
        rx_data => tx_data,
        rx_data_vld => tx_data_vld,
        rx_data_rdy => tx_data_rdy,
        clk => clk
    );




end architecture;