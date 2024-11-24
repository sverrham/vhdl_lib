

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library reference_lib;

--hdlregression:tb
entity tb_freq_offset_from_count is
    generic (runner_cfg : string);
end tb_freq_offset_from_count;

architecture rtl of tb_freq_offset_from_count is

    constant c_bits : integer := 25;

    signal clk_i : std_logic := '0';
    signal runing : std_logic := '1';

    signal count_i : unsigned(c_bits-1 downto 0) := (others => '0');
    signal count_vld_i : std_logic := '0';
    signal error_ppb_o : signed(c_bits-1 downto 0);
    signal error_ppb_vld_o: std_logic;
begin

    clk_i <= not clk_i after 10 ns when runing = '1' else '0';

    stimuli : process
    begin
        test_runner_setup(runner, runner_cfg);
        report "Start of test" severity note;
     
        wait for 10 us;
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(10000100, c_bits);
        count_vld_i <= '1';
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(0, c_bits);
        count_vld_i <= '0';
        wait for 1 us;
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(10000001, c_bits);
        count_vld_i <= '1';
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(0, c_bits);
        count_vld_i <= '0';
        wait for 1 us;
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(9990000, c_bits);
        count_vld_i <= '1';
        wait until rising_edge(clk_i);
        count_i <= to_unsigned(0, c_bits);
        count_vld_i <= '0';
        wait for 1 us;
        
        runing <= '0';
        assert false report "End of test" severity note;
        test_runner_cleanup(runner);
        wait;
    end process;


    check_output: process
    begin
        wait until rising_edge(error_ppb_vld_o);
        assert error_ppb_o = to_signed(10000, c_bits) report "Unexpected error " & to_hstring(error_ppb_o) & " ppm" severity error;
        wait until rising_edge(error_ppb_vld_o);
        assert error_ppb_o = to_signed(100, c_bits) report "Unexpected error " & to_hstring(error_ppb_o) & " ppm" severity error;
        wait until rising_edge(error_ppb_vld_o);
        assert error_ppb_o = to_signed(-1000000, c_bits) report "Unexpected error " & to_hstring(error_ppb_o) & " ppm" severity error;
    end process;


    dut : entity reference_lib.freq_offset_from_count
    generic map(
        g_frequency => 10.0e6,
        g_bits => c_bits
    )
    port map(
        clk_i => clk_i,
        count_i => count_i,
        count_vld_i => count_vld_i,
        error_ppb_o => error_ppb_o,
        error_ppb_vld_o => error_ppb_vld_o
    );

end rtl;