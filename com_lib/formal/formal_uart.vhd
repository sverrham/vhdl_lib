library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity formal_uart is

   port (
      clk_i    : in  std_logic;
      tx_ena   : in  std_logic;
      tx_data  : in  std_logic_vector(7 downto 0);
      rx       : in  std_logic;
      rx_busy  : out  std_logic;
      rx_error : out  std_logic;
      rx_data  : out  std_logic_vector(7 downto 0);
      rx_vld   : out  std_logic;
      tx_busy  : out std_logic;
      tx       : out std_logic
   );
end entity;

architecture rtl of formal_uart is


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
   -- Check that busy is high until valid is asserted.
   rx_busy_until_vld : assert (always (rx_busy -> rx_busy until rx_vld));

   -- Check that low on rx when rx is not busy starts an rx reception
   -- We state here that the rx signal needs to be low for 4 consecutive cycles to 
   -- trigger the property, this is for the over sampling in the implementation.
   rx_start : assert (always {not rx and not rx_busy;not rx[*4]} |-> rx_busy until rx_vld);

   -- Check that tx_ena cases tx_busy next clock cycle and that tx_busy is high 1 or more cycles.
   tx_en_to_busy : assert (always ({tx_ena} |=> {tx_busy[+]}));

   -- Check that a tx_ena causes tx line to go low
   tx_en_to_tx_transmit : assert (always ({tx_ena and not tx_busy} |=> {tx[*0 to 4];not tx}));


   -----------------------------------------------------------------
   -- DUT
   -----------------------------------------------------------------
   dut : entity work.uart
      generic map(
         clk_freq  => 24_000_000,
         baud_rate => 12_000_000, -- for sim speed
         os_rate   => 4, -- for sim speed
         parity    => 0
      )
      port map(
         clk      => clk_i,
         reset_n  => '1',
         tx_ena   => tx_ena,
         tx_data  => tx_data,
         rx       => rx,
         rx_busy  => rx_busy,
         rx_error => rx_error,
         rx_data  => rx_data,
         rx_vld   => rx_vld,
         tx_busy  => tx_busy,
         tx       => tx
      );

end architecture;
