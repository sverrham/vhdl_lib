

library ieee;
use ieee.std_logic_1164.all;

-- This module should get an arp message and create an arp reply if it matchees the IP address
-- Input should be only the arp message, stripped of the ethernet header with ehternet type.
-- if IP matches the ip.
-- This module is made simple to only support IPv4.
-- some there is expectations of protocol 0x0800 in 
entity arp_reply is
    generic (
        g_ip_addr : std_logic_vector(31 downto 0) := x"C0A80232"; -- 192.168.2.50
        g_mac_addr : std_logic_vector(47 downto 0) := x"BAAD00020001"
    );
    port (
        clk_i       : in std_logic;
        rst_i       : in std_logic;
		vld_i       : in std_logic;
		rdy_o       : out std_logic;
		data_i      : in std_logic_vector(7 downto 0);
        data_o      : out std_logic_vector(7 downto 0);
        vld_o       : out std_logic;
        rdy_i       : in std_logic
    );
end entity;

architecture rtl of arp_reply is

    type t_state is (
        s_idle,
        s_check_arp_for_me,
        s_sender_mac,
        s_sender_ip,
        s_target_mac,
        s_target_ip,
        s_reply_arp,
        s_send_rest
    );

    signal state : t_state := s_idle;

    signal check_count : integer range 0 to 28;

    type t_8b_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant arp_message_beginning : t_8b_array(0 to 7) := (0 => x"00",
                                                           1 => x"01",
                                                           2 => x"08",
                                                           3 => x"00",
                                                           4 => x"06",
                                                           5 => x"04",
                                                           6 => x"00",
                                                           7 => x"01");


    signal sender_mac : t_8b_array(0 to 5);
    signal sender_ip  : t_8b_array(0 to 3);

    constant ip_addr : t_8b_array(0 to 3) := (0 => g_ip_addr(31 downto 24),
                                              1 => g_ip_addr(23 downto 16),
                                              2 => g_ip_addr(15 downto 8),
                                              3 => g_ip_addr(7 downto 0));
                                        
    constant mac_addr : t_8b_array(0 to 5) := (0 => g_mac_addr(47 downto 40),
                                               1 => g_mac_addr(39 downto 32),
                                               2 => g_mac_addr(31 downto 24),
                                               3 => g_mac_addr(23 downto 16),
                                               4 => g_mac_addr(15 downto 8),
                                               5 => g_mac_addr(7 downto 0));
begin

    rdy_o <= vld_i when state /= s_reply_arp else '0';

    p_main : process (clk_i) is 
    begin
        if rising_edge(clk_i) then
            if rst_i then
                state <= s_idle;
                vld_o <= '0';
                data_o <= (others => '0');
            else
                vld_o <= '0';
                case state is
                    when s_idle =>
                        -- assume data is filtered before so we only get the arp ethernet packet.
                        if vld_i = '1' and data_i = arp_message_beginning(0) then
                            state <= s_check_arp_for_me;
                            check_count <= 1; -- initialise the byte counter.
                        end if;
                    when s_check_arp_for_me =>
                        if vld_i = '1' then
                            check_count <= check_count + 1;
                            if check_count = 7 then
                                state <= s_sender_mac;
                                check_count <= 0;
                            end if;

                            if data_i /= arp_message_beginning(check_count) then
                                state <= s_idle;
                            end if;
                        end if;
                    
                    when s_sender_mac => 
                        if vld_i = '1' then
                            sender_mac(check_count) <= data_i;
                            check_count <= check_count + 1;
                            if check_count = 5 then
                                state <= s_sender_ip;
                                check_count <= 0;
                            end if;
                        end if; 

                    when s_sender_ip => 
                        if vld_i = '1' then
                            sender_ip(check_count) <= data_i;
                            check_count <= check_count + 1;
                            if check_count = 3 then
                                state <= s_target_mac;
                                check_count <= 0;
                            end if;
                        end if;

                    when s_target_mac =>
                        if vld_i = '1' then
                            check_count <= check_count + 1;
                            if check_count = 5 then
                                state <= s_target_ip;
                                check_count <= 0;
                            end if;
                        end if;

                    when s_target_ip =>
                        if vld_i = '1' then
                            check_count <= check_count + 1;
                            if check_count = 3 then
                                state <= s_reply_arp;
                                check_count <= 0;
                            end if;

                            if ip_addr(check_count) /= data_i then
                                state <= s_idle;
                            end if;
                        end if;

                    when s_reply_arp =>
                        if vld_o = '0' or rdy_i = '1' then
                            vld_o <= '1';
                            check_count <= check_count + 1;
                            if check_count < 7 then
                                data_o <= arp_message_beginning(check_count);
                            elsif check_count = 7 then
                                data_o <= x"02"; -- Reply operation
                            elsif check_count < 14 then
                                data_o <= mac_addr(check_count - 8);
                            elsif check_count < 18 then
                                data_o <= ip_addr(check_count - 14);
                            elsif check_count < 24 then
                                data_o <= sender_mac(check_count - 18);
                            elsif check_count < 28 then
                                data_o <= sender_ip(check_count - 24); 
                            end if;

                            if check_count = 27 then
                                state <= s_send_rest;
                            end if;
                        end if;
                    
                    when s_send_rest =>
                        -- just send rest of data.
                        if vld_o = '0' or rdy_i = '1' then
                            vld_o <= '1';
                            data_o <= data_i;
                        end if;

                end case;
            end if;
        end if;
    end process;

end architecture;