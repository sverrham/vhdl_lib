

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library reference_lib;

--hdlregression:tb
entity tb_pps_counter is
    generic (runner_cfg : string);
end tb_pps_counter;

architecture rtl of tb_pps_counter is

    constant c_bits : integer := 25;

    signal clk_i : std_logic := '0';
    signal pps_i : std_logic := '0';
    signal runing : std_logic := '1';

    signal last_count_o: unsigned(c_bits-1 downto 0);
    signal last_count_vld_o: std_logic;
begin

    clk_i <= not clk_i after 100 ns when runing = '1' else '0';

    stimuli : process
    begin
        test_runner_setup(runner, runner_cfg);
        report "Start of test" severity note;
        for i in 0 to 10 loop
            wait for 10 ms;
            pps_i <= '1';
            wait for 1 us;
            pps_i <= '0';
        end loop;

        runing <= '0';
        assert false report "End of test" severity note;
        test_runner_cleanup(runner);
        wait;
    end process;


    check_output: process
    begin
        wait until rising_edge(last_count_vld_o);
        assert last_count_o /= to_unsigned(0, c_bits) report "Unexpected count" severity error;
    end process;

    dut : entity reference_lib.pps_counter
    generic map(
        g_bits => c_bits
    )
    port map(
        clk_i => clk_i,
        pps_i => pps_i,
        last_count_o => last_count_o,
        last_count_vld_o => last_count_vld_o
    );

end rtl;