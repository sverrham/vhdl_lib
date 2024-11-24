library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library vunit_lib;
context vunit_lib.vunit_context;

library com_lib;
use com_lib.com_pkg.all;

entity tb_uart_tx_arbiter_vunit is
    generic (runner_cfg : string);
end tb_uart_tx_arbiter_vunit;

architecture sim of tb_uart_tx_arbiter_vunit is
    signal clk_i        : std_logic := '0';
    signal uart_busy_i  : std_logic := '0';
    signal uart_ena_o   : std_logic;
    signal uart_data_o  : std_logic_vector(7 downto 0);
    
    signal tx_req_i      : std_logic_vector(1 downto 0) := (others => '0');
    signal tx_busy_o     : std_logic_vector(1 downto 0);
    signal tx_data_i     : vec8_array(1 downto 0);
    signal tx_data_vld_i : std_logic_vector(1 downto 0) := (others => '0');

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the uart_tx_arbiter with two input ports
    dut: entity com_lib.uart_tx_arbiter
        generic map (
            g_ports => 2
        )
        port map (
            clk_i => clk_i,
            uart_busy_i => uart_busy_i,
            uart_ena_o => uart_ena_o,
            uart_data_o => uart_data_o,
            tx_req_i => tx_req_i,
            tx_busy_o => tx_busy_o,
            tx_data_i => tx_data_i,
            tx_data_vld_i => tx_data_vld_i
        );

    -- Clock generation process
    clk_proc: process
    begin
        clk_i <= not clk_i;
        wait for CLK_PERIOD / 2;
    end process;

    -- Testbench stimulus process
    stimulus_proc: process
    begin
        test_runner_setup(runner, runner_cfg);
        info("Starting test");

        -- Reset and initialize signals
        tx_req_i <= (others => '0');
        tx_data_vld_i <= (others => '0');
        tx_data_i(0) <= x"41";  -- ASCII 'A'
        tx_data_i(1) <= x"42";  -- ASCII 'B'
        wait for CLK_PERIOD * 5;

        -- Test case 1: Send data from port 0
        info("Test case 1");
        tx_req_i <= "01";
        tx_data_vld_i <= "01";
        wait for CLK_PERIOD * 10;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"41", "Data out correct", ERROR);

        tx_req_i <= "00";
        tx_data_vld_i <= "00";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        check(uart_data_o = x"41", "Data out", ERROR);

        -- Test case 2: Send data from port 1
        info("Test case 2");
        tx_req_i <= "10";
        tx_data_vld_i <= "10";
        wait for CLK_PERIOD * 10;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"42", "Data out correct", ERROR);
        tx_req_i <= "00";
        tx_data_vld_i <= "00";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        check(uart_data_o = x"42", "Data out", ERROR);

        -- Test case 3: Send data from both ports simultaneously
        info("Test case 3");
        tx_req_i <= "11";
        tx_data_vld_i <= "11";
        wait for CLK_PERIOD * 10;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"42", "Data out correct", ERROR);
        tx_req_i <= "01";
        tx_data_vld_i <= "01";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"41", "Data out correct", ERROR);
        tx_req_i <= "00";
        tx_data_vld_i <= "00";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        check(uart_data_o = x"41", "Data out", ERROR);

        -- Test case 4: UART busy scenario
        info("Test case 4");
        uart_busy_i <= '1';
        tx_req_i <= "01";
        tx_data_vld_i <= "01";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        uart_busy_i <= '0';
        wait for CLK_PERIOD * 10;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"41", "Data out correct", ERROR);
        tx_req_i <= "00";
        tx_data_vld_i <= "00";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        check(uart_data_o = x"41", "Data out", ERROR);

        -- Test case 5: Request from port 0 followed by port 1
        info("Test case 5");
        tx_req_i <= "01";
        tx_data_vld_i <= "01";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"41", "Data out correct first", ERROR);
        tx_req_i <= "10";
        tx_data_vld_i <= "10";
        wait for CLK_PERIOD * 10;
        check(uart_ena_o = '1', "En out high", ERROR);
        check(uart_data_o = x"42", "Data out correct second", ERROR);
        tx_req_i <= "00";
        tx_data_vld_i <= "00";
        wait for CLK_PERIOD * 5;
        check(uart_ena_o = '0', "En out low", ERROR);
        check(uart_data_o = x"42", "Data out", ERROR);

        -- End of simulation
        assert false report "End of simulation" severity note;
        test_runner_cleanup(runner);
        wait;
    end process;

end architecture sim;
