
library ieee;
use ieee.std_logic_1164.all;

entity ethertype_decode is
    port (
        clk_i       : in std_logic;
		empty_i     : in std_logic;
		rd_en_o     : out std_logic;
		data_i      : in std_logic_vector(7 downto 0);
		uart_busy_i : in std_logic;
        uart_en_o   : out std_logic;
        uart_data_o : out std_logic_vector(7 downto 0));
end entity;

architecture rtl of ethertype_decode is
   
    type t_state is (
        idle,
        wait_pkt,
        pkt_length_high,
        pkt_length_low,
        mac,
        ether_type_low,
        ether_type_high,
        send_new_line
    );

    signal state : t_state := idle;

    signal mac_count : integer range 0 to 14 := 0;
    signal uart_en : std_logic;
begin

    uart_en_o <= uart_en;

    p_decode : process (clk_i) is
        variable uart_data : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk_i) then
            rd_en_o <= '0';
            uart_en <= '0';
            case state is
                when idle =>
                    -- Mac frames with one empty_i before packet minimum.
                    if empty_i = '1' then
                        state <= wait_pkt;
                    else
                        rd_en_o <= '1';
                    end if;
                when wait_pkt =>
                    if empty_i = '0' then
                        -- start reading out data
                        -- rd_en_o <= '1';
                        state <= pkt_length_high;
                        mac_count <= 0;
                    end if;
                when pkt_length_high =>
                     if uart_busy_i = '0' and uart_en = '0' then
                        rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= data_i;
                        state <= pkt_length_low;
                    end if;

                when pkt_length_low =>
                     if uart_busy_i = '0' and uart_en = '0' then
                        rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= data_i;
                        state <= mac;
                    end if;
                   
                when mac =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        uart_en <= '1';
                        uart_data_o <= data_i;

                        rd_en_o <= '1';
                        mac_count <= mac_count + 1;
                        if mac_count = 11 then
                            state <= ether_type_low;
                        end if;
                    end if;

                when ether_type_low =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= data_i;
                        state <= ether_type_high;
                    end if;

                when ether_type_high =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= data_i;
                        state <= send_new_line;
                    end if;
                
                when send_new_line =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        uart_en <= '1';
                        uart_data_o <= x"0A"; -- New line to end message
                        state <= idle;
                    end if;
            end case;
        end if;
    end process;
end;