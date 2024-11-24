

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library reference_lib;

--hdlregression:tb
entity tb_freq_measure_wrapper is
    generic (runner_cfg : string);
end tb_freq_measure_wrapper;

architecture rtl of tb_freq_measure_wrapper is

    signal clk_i : std_logic := '0';
    signal runing : std_logic := '1';

    signal pps_i : std_logic := '0';
    signal msg_req_o : std_logic := '0';
    signal msg_busy_i : std_logic := '0';
    signal msg_data_o : std_logic_vector(7 downto 0);
    signal msg_data_vld_o : std_logic := '0';
begin

    clk_i <= not clk_i after 10 ns when runing = '1' else '0';

    stimuli : process
    begin
        test_runner_setup(runner, runner_cfg);
        report "Start of test" severity note;
     
        for i in 0 to 9 loop
            wait for 10 us;
            wait until rising_edge(clk_i);
            pps_i <= '1';
            wait for 5 us;
            wait until rising_edge(clk_i);
            pps_i <= '0';
            wait for 5 us;
        end loop;

        runing <= '0';
        assert false report "End of test" severity note;
        test_runner_cleanup(runner);
        wait;
    end process;

    uart_mod : process
    begin
        if msg_req_o = '0' then
            wait until rising_edge(msg_req_o);
        end if;
        wait until rising_edge(clk_i);
        msg_busy_i <= '1';
        wait for 400 ns;
        msg_busy_i <= '0';
    end process;

    check_output: process
    begin
        wait;
    end process;


    dut : entity reference_lib.freq_measure_wrapper
    generic map(
        g_frequency => 1.0e6
    )
    port map(
        clk_i => clk_i,
        pps_i => pps_i,
        msg_req_o => msg_req_o,
        msg_busy_i => msg_busy_i,
        msg_data_o => msg_data_o,
        msg_data_vld_o=> msg_data_vld_o
    );

end rtl;