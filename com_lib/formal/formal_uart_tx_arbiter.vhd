library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library com_lib;
use com_lib.com_pkg.all;

entity formal_uart_tx_arbiter is
   generic (
      g_ports : integer := 4
   );
   port (
      clk_i : in std_logic;

      uart_busy_i : in  std_logic;
      uart_ena_o  : out std_logic;
      uart_data_o : out std_logic_vector(7 downto 0);

      tx_req_i      : in  std_logic_vector(g_ports-1 downto 0);
      tx_busy_o     : out std_logic_vector(g_ports-1 downto 0);
      tx_data_i     : in  vec8_array(g_ports-1 downto 0);
      tx_data_vld_i : in  std_logic_vector(g_ports-1 downto 0)
   );
end entity;

architecture rtl of formal_uart_tx_arbiter is


begin

   -----------------------------------------------------------------
   -- Clock
   -----------------------------------------------------------------
   default clock is rising_edge(clk_i);

   -----------------------------------------------------------------
   -- Assumptions
   -----------------------------------------------------------------


   -----------------------------------------------------------------------------
   -- Properties
   -----------------------------------------------------------------------------
   gen_for_ports :
   for i in 0 to g_ports-1 generate
      grant : assert (always ({tx_req_i(i) and uart_busy_i} |-> {tx_busy_o(i)} until not uart_busy_i));

      ena : assert (always ({tx_req_i(i); tx_req_i(i) and not tx_busy_o(i)[->]; tx_req_i(i) and tx_data_vld_i(i)} |=> {uart_ena_o}));

   end generate;


   -----------------------------------------------------------------
   -- DUT
   -----------------------------------------------------------------
   dut : entity work.uart_tx_arbiter
      generic map(
         g_ports => g_ports
      )
      port map(
         clk_i         => clk_i,
         uart_busy_i   => uart_busy_i,
         uart_ena_o    => uart_ena_o,
         uart_data_o   => uart_data_o,
         tx_req_i      => tx_req_i,
         tx_busy_o     => tx_busy_o,
         tx_data_i     => tx_data_i,
         tx_data_vld_i => tx_data_vld_i
      );

end architecture;
