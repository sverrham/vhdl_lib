
library ieee;
use ieee.std_logic_1164.all;


-- Module to look at data from the mac, and if the packet is an arp packet, ethertype 0x0806
-- then send the packet out on output interface.
-- 
entity arp_echo is
    port (
        clk_i       : in std_logic;
		empty_i     : in std_logic;
		rd_en_o     : out std_logic;
		data_i      : in std_logic_vector(7 downto 0);
		uart_busy_i : in std_logic;
        uart_en_o   : out std_logic;
        uart_data_o : out std_logic_vector(7 downto 0));
end entity;

architecture rtl of arp_echo is
   
    type t_state is (
        idle,
        wait_pkt,
        pkt_length_high,
        pkt_length_low,
        mac,
        ether_type_high,
        ether_type_low,
        send_mac,
        send_ether_type_high,
        send_ether_type_low,
        send_rest,
        send_new_line
    );

    signal state : t_state := idle;

    signal mac_count : integer range 0 to 20 := 0;
    signal uart_en : std_logic;

    type mac_data_t is array (natural range <>) of std_logic_vector(7 downto 0);
    signal mac_data : mac_data_t(0 to 11);

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
                        state <= pkt_length_high;
                        mac_count <= 0;
                        rd_en_o <= '1';
                    end if;
                when pkt_length_high =>
                    rd_en_o <= '1';
                    state <= pkt_length_low;

                when pkt_length_low =>
                    rd_en_o <= '1';
                    state <= mac;
                   
                when mac =>
                    rd_en_o <= '1';
                    mac_data(mac_count) <= data_i;
                    mac_count <= mac_count + 1;
                    if mac_count = 11 then
                        state <= ether_type_high;
                    end if;

                when ether_type_high =>
                    rd_en_o <= '1';
                    if data_i = x"08" then -- high byte arp ether type.
                        state <= ether_type_low;
                    else
                        state <= idle;
                    end if;

                when ether_type_low =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        if data_i = x"06" then
                            state <= send_mac;
                            mac_count <= 1;
                            uart_en <= '1';
                            uart_data_o <= mac_data(0);
                        else
                            state <= idle;
                        end if;
                    end if;

                when send_mac =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        uart_en <= '1';
                        uart_data_o <= mac_data(mac_count);
                        mac_count <= mac_count + 1;
                        if mac_count = 11 then
                            state <= send_ether_type_high;
                        end if;
                    end if;

                when send_ether_type_high =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        uart_en <= '1';
                        uart_data_o <= x"08";
                        state <= send_ether_type_low;
                    end if;

                when send_ether_type_low =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        -- rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= x"06";
                        state <= send_rest;
                    end if;

                when send_rest =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        rd_en_o <= '1';
                        uart_en <= '1';
                        uart_data_o <= data_i;
                        if empty_i = '1' then
                            rd_en_o <= '0';
                            state <= send_new_line;
                            uart_data_o <= x"0A"; -- New line to end message
                        end if;
                    end if;

                when send_new_line =>
                    if uart_busy_i = '0' and uart_en = '0' then
                        state <= idle;
                    end if;
            end case;
        end if;
    end process;
end;