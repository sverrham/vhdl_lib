
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library stream_lib;
use stream_lib.status_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;


entity tb_vld_rdy_profiler is
end entity;

architecture rtl of tb_vld_rdy_profiler is

    signal clk : std_logic;
    signal vld : std_logic;
    signal rdy : std_logic;
    signal pps : std_logic := '0';
    signal status : t_status;
    signal status_vld: std_logic;
    signal status_rdy: std_logic := '0';

    constant ZEROS : std_logic_vector(31 downto 0) := (others => '0');

begin

    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

    clock_generator(clk, 8 ns);

    p_main : process
        procedure old_test(VOID : t_void) is
        begin
            wait until rising_edge(clk);
            gen_pulse(pps, clk, 2, "set pps two periods to clear the count");
            -- check_value(transitions, ZEROS, "check transitions output with no transitions");

            log("Send some pulses and check the count");
            vld <= '1';
            rdy <= '1';
            wait until rising_edge(clk);
            vld <= '0';
            wait until rising_edge(clk);
            rdy <= '0';
            vld <= '1';
            wait until rising_edge(clk);
            gen_pulse(pps, clk, 1, "gen pps signal");
            check_value(status_vld, '1', "Check valid");
            check_value(status.data, X"01", "check for SOF");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            wait until rising_edge(clk);
            status_rdy <= '1';
            wait until rising_edge(clk);
            wait until rising_edge(clk);

            check_value(status_vld, '1', "Check valid");
            check_value(status.data, X"00", "check for status");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            wait until rising_edge(clk);
            
            check_value(status_vld, '1', "Check valid");
            check_value(status.data, X"00", "check for status");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            wait until rising_edge(clk);

            check_value(status_vld, '1', "Check valid");
            check_value(status.data, X"00", "check for status");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            wait until rising_edge(clk);
            
            check_value(status_vld, '1', "Check valid");
            check_value(status.data, X"01", "check for status");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            wait until rising_edge(clk);
            status_rdy <= '0';
            
            check_value(status_vld, '0', "Check valid");

            gen_pulse(pps, clk, 1, "gen pps signal");
            -- check_value(transitions_vld, '1', "Check valid");
            -- check_value(transitions, ZEROS, "check transitions output with no transitions");
            -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
            -- check_value(transitions_vld, '0', "Check valid");
        end procedure;
    begin
        await_uvvm_initialization(VOID);

        -- old_test(VOID);
        log("Starting simulation");
        wait until rising_edge(clk);
        gen_pulse(pps, clk, 2, "set pps two periods to clear the count");
        -- check_value(transitions, ZEROS, "check transitions output with no transitions");

        log("Send some pulses and check the count");
        vld <= '1';
        rdy <= '1';
        wait until rising_edge(clk);
        vld <= '0';
        wait until rising_edge(clk);
        rdy <= '0';
        vld <= '1';
        wait until rising_edge(clk);
        VLD_RDY_VVC_SB.add_expected(X"00_0000_0001", "expected one word");
        vld_rdy_receive(VLD_RDY_VVCT, 1, "one workd", TO_SB);
        gen_pulse(pps, clk, 1, "gen pps signal");

        await_completion(ALL_VVCS, 1 ms, "Wait for data done");
        
        
        -- check_value(status_vld, '1', "Check valid");
        -- check_value(status.data, X"01", "check for SOF");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- wait until rising_edge(clk);
        -- status_rdy <= '1';
        -- wait until rising_edge(clk);
        -- wait until rising_edge(clk);

        -- check_value(status_vld, '1', "Check valid");
        -- check_value(status.data, X"00", "check for status");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- wait until rising_edge(clk);
        
        -- check_value(status_vld, '1', "Check valid");
        -- check_value(status.data, X"00", "check for status");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- wait until rising_edge(clk);

        -- check_value(status_vld, '1', "Check valid");
        -- check_value(status.data, X"00", "check for status");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- wait until rising_edge(clk);
        
        -- check_value(status_vld, '1', "Check valid");
        -- check_value(status.data, X"01", "check for status");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- wait until rising_edge(clk);
        -- status_rdy <= '0';
        
        -- check_value(status_vld, '0', "Check valid");

        -- gen_pulse(pps, clk, 1, "gen pps signal");
        -- check_value(transitions_vld, '1', "Check valid");
        -- check_value(transitions, ZEROS, "check transitions output with no transitions");
        -- gen_pulse(status_rdy, clk, 1, "gen rdy signal");
        -- check_value(transitions_vld, '0', "Check valid");
        
        report_alert_counters(FINAL);
        std.env.stop;
        wait;

    end process;
    
    i_vld_rdy_profiler : entity stream_lib.vld_rdy_profiler
    port map (
        clk => clk,
        vld => vld,
        rdy => rdy,
        pps => pps,
        status => status,
        status_vld => status_vld,
        status_rdy => status_rdy 
    );

    i_vld_rdy_vvc : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
        GC_DATA_WIDTH => 8,
        GC_INSTANCE_IDX => 1
    )
    port map (
        -- tx_data => status.data,
        -- tx_data_vld => status_vld,
        tx_data_rdy => '1',
        rx_data => status.data,
        rx_data_vld => status_vld,
        rx_data_rdy => status_rdy,
        clk => clk
    );


end architecture;