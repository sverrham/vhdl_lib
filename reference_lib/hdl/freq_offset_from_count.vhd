
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Calculates the ppb error from expected count.
-- 
-- Input is count in the expected frequency g_frequency over one second.
-- The measurement period 1s is expected to be correct.
entity freq_offset_from_count is
    generic (
        g_frequency : in real;
        g_bits : in integer := 32
    );
    port (
        clk_i: in std_logic;
        count_i: in unsigned(g_bits-1 downto 0);
        count_vld_i: in std_logic;
        error_ppb_o : out signed(g_bits-1 downto 0);
        error_ppb_vld_o : out std_logic
        );
end freq_offset_from_count;

architecture rtl of freq_offset_from_count is

    constant c_expected_count : unsigned(g_bits-1 downto 0) := to_unsigned(natural(g_frequency), g_bits);
    constant c_ppm : integer range 0 to 100 := natural(g_frequency/1.0e6);
    
    constant c_bits_2 : integer := g_bits-2;
    signal offset : integer range -(2**30)-1 to 2**30; ---2_147_483_646 to 2_147_483_647;
    signal error_ppb : signed(g_bits-1 downto 0) := (others => '0');

    type state_type is (idle, calc_error, output_error);
    signal state : state_type := idle;
begin

    p_error : process (clk_i)
    variable v_offset : signed(g_bits-1 downto 0);
    variable v_error_ppm : signed(g_bits-1 downto 0);
    begin
        if rising_edge(clk_i) then
            error_ppb_vld_o <= '0';
            case state is
                when idle =>
                    if count_vld_i = '1' then
                        state <= calc_error;
                        v_offset := signed(count_i - c_expected_count);
                        offset <= to_integer(v_offset);
                    end if;

                when calc_error =>
                    state <= output_error;
                    v_error_ppm := to_signed(offset * 1000, g_bits);
                    error_ppb <= v_error_ppm / c_ppm;

                when output_error =>
                    state <= idle;
                    error_ppb_o <= error_ppb;
                    error_ppb_vld_o <= '1';
            end case;
        end if;
    end process;
    

end rtl;