library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- library vunit_lib;
-- context vunit_lib.vunit_context;

library osvvm;
context osvvm.osvvmcontext;

library com_lib;
use com_lib.com_pkg.all;

--hdlregression:tb
entity tb_uart_tx_arbiter_osvvm is
    -- generic (runner_cfg : string);
end tb_uart_tx_arbiter_osvvm;

architecture sim of tb_uart_tx_arbiter_osvvm is
    constant c_ports : integer := 2;
    
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
            g_ports => c_ports
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
        procedure pd_set_tx(c_tx_data : std_logic_vector(c_ports-1 downto 0)) is 
        begin
            tx_req_i <= c_tx_data;
            tx_data_vld_i <= c_tx_data;
        end procedure;


    begin
        SetAlertLogName("tb_uart_tx_arbiter_osvvm");
        log("Starting test", INFO, TRUE);

        -- Reset and initialize signals
        tx_req_i <= (others => '0');
        tx_data_vld_i <= (others => '0');
        tx_data_i(0) <= x"41";  -- ASCII 'A'
        tx_data_i(1) <= x"42";  -- ASCII 'B'
        wait for CLK_PERIOD * 5;

        -- Test case 1: Send data from port 0
        log("Test case 1", INFO, TRUE);
        pd_set_tx("01");
        wait for CLK_PERIOD * 10;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"41");
        
        pd_set_tx("00");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        AffirmIfEqual(0, uart_data_o, x"41");
        
        -- Test case 2: Send data from port 1
        log("Test case 2", INFO, TRUE);
        pd_set_tx("10");
        wait for CLK_PERIOD * 10;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"42");
        pd_set_tx("00");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        AffirmIfEqual(0, uart_data_o, x"42");
        
        -- Test case 3: Send data from both ports simultaneously
        log("Test case 3", INFO, TRUE);
        pd_set_tx("11");
        wait for CLK_PERIOD * 10;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"42");
        
        pd_set_tx("01");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"41");
        pd_set_tx("00");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        AffirmIfEqual(0, uart_data_o, x"41");
        
        -- Test case 4: UART busy scenario
        log("Test case 4", INFO, TRUE);
        uart_busy_i <= '1';
        pd_set_tx("01");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        uart_busy_i <= '0';
        wait for CLK_PERIOD * 10;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"41");
        
        pd_set_tx("00");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        AffirmIfEqual(0, uart_data_o, x"41");
        
        -- Test case 5: Request from port 0 followed by port 1
        log("Test case 5", INFO, TRUE);
        pd_set_tx("01");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"41");
        pd_set_tx("10");
        wait for CLK_PERIOD * 10;
        AffirmIfEqual(0, uart_ena_o, '1');
        AffirmIfEqual(0, uart_data_o, x"42");
        pd_set_tx("00");
        wait for CLK_PERIOD * 5;
        AffirmIfEqual(0, uart_ena_o, '0');
        AffirmIfEqual(0, uart_data_o, x"42");
        -- AffirmIfEqual(0, uart_data_o, x"41");
        
        -- End of simulation
        assert false report "End of simulation" severity note;
        ReportAlerts;

        EndOfTestReports;
        if GetAlertCount = 0 then
            log("Test passed", INFO, TRUE);
        end if;
        std.env.stop(GetAlertCount);
        wait;
    end process;

end architecture sim;
