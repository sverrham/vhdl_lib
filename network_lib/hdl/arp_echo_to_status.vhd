library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library stream_lib;
use stream_lib.stream_pkg.all;
use stream_lib.status_pkg.all;

library olo_lib;
use olo_lib.olo_base_pkg_array.all;

-- Module that takes in a stream with raw ethernet data from the mac.
-- if it is an arp packet, ethertype 0x0806 then we send the full packet
-- out on the status interface.
--
-- This is basically just to debug the path and see if we decode the messages
-- correct.
-- With this working it is easier to move on the the modules actually replying to 
-- the arp messages. 
--
-- This module will be quite blocking unless we add a fifo for the output.
--
entity arp_echo_to_status is
    port (
        clk_i : in std_logic;
        stream_i : in t_stream;
        stream_vld_i : in std_logic;
        stream_rdy_o : out std_logic;
        status_o : out t_status := (data => x"00", tag => UDEF);
        status_vld_o : out std_logic;
        status_rdy_i : in std_logic
    );
end entity;

architecture rtl of arp_echo_to_status is

    type t_state is (
        idle_s,
        mac_s,
        ether_type_s,
        send_mac_s,
        send_data_s,
        wait_data_s
    );

    signal state : t_state := idle_s;
    signal mac_count : integer range 0 to 3;
    signal mac_words : StlvArray32_t(2 downto 0);
    signal byte : integer range 0 to 3;
    signal status_vld : std_logic;
begin

status_vld_o <= status_vld;

p_ethertype_to_status : process (clk_i)
begin
    if rising_edge(clk_i) then
        if status_rdy_i = '1' then
            status_vld <= '0';
        end if;
        case state is
            when idle_s =>
                status_vld <= '0';
                stream_rdy_o <= '1';
                if stream_vld_i = '1' and stream_i.tag = SOF and stream_i.data(7 downto 0) = mac_raw_stream then
                   state <= mac_s;
                   mac_count <= 0;
                end if;
            
            when mac_s =>
                stream_rdy_o <= '1';
                if stream_vld_i = '1' then
                    mac_words(mac_count) <= stream_i.data;
                    mac_count <= mac_count + 1;
                    if mac_count = 2 then
                        state <= ether_type_s;
                        stream_rdy_o <= '0';
                    end if;
                end if;
            
            when ether_type_s =>
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    if stream_i.data(31 downto 16) = x"0806" then
                        -- its a arp packet, lets send stuff out.
                        status_o.data <= arp_ether_type_status;
                        status_o.tag <= SOF;
                        status_vld <= '1';
                        state <= send_mac_s;
                        byte <= 0;
                        mac_count <= 0;
                    else
                        state <= idle_s;
                        stream_rdy_o <= '1';
                    end if;
                end if;

            when send_mac_s =>
                if status_rdy_i = '1' or status_vld = '0' then
                    status_o.data <= mac_words(mac_count)(31-8*byte downto 24-8*byte);
                    status_o.tag <= DATA;
                    status_vld <= '1';

                    if byte = 3 then
                        mac_count <= mac_count + 1;
                        byte <= 0;
                        if mac_count = 2 then
                            state <= send_data_s;
                        end if;
                    else
                        byte <= byte + 1;
                    end if;

                end if;

            when send_data_s =>
                stream_rdy_o <= '0';
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    status_o.data <= stream_i.data(31-8*byte downto 24-8*byte);
                    status_o.tag <= DATA;
                    status_vld <= '1';
                    
                    if byte = 3 then
                        stream_rdy_o <= '1';
                        byte <= 0;
                        state <= wait_data_s;
                    else                        
                        byte <= byte + 1;
                    end if;

                    if stream_i.tag = EOF and byte = 3 then
                        status_o.tag <= EOF;
                        state <= idle_s;
                    end if;
                end if;
            
            when wait_data_s =>
                stream_rdy_o <= '0';
                state <= send_data_s;

        end case;
    end if;
end process;

end architecture;