

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Simple counter for clock cycles between pps_i pulses.
--
entity pps_counter is
    generic (
        g_bits : in integer := 32
    );
    port (
        clk_i: in std_logic;
        pps_i: in std_logic;
        last_count_o: out unsigned(g_bits-1 downto 0);
        last_count_vld_o: out std_logic
        );
end pps_counter;

architecture rtl of pps_counter is
    signal count : unsigned(g_bits-1 downto 0) := (others => '0');
    
    signal last_pps : std_logic := '0';
    attribute syn_preserve : boolean;
    attribute syn_preserve of last_pps : signal is true;
begin

    p_count : process (clk_i)
    begin
        if rising_edge(clk_i) then
            last_count_vld_o <= '0';

            if pps_i = '1' and last_pps = '0' then
                count <= (others => '0');
                last_count_o <= count;
                last_count_vld_o <= '1';
            else
                count <= count + 1;
            end if;

            last_pps <= pps_i;
        end if;
    end process p_count;

end rtl;