
library ieee;
use ieee.std_logic_1164.all;

library stream_lib;
use stream_lib.stream_pkg.all;
use stream_lib.status_pkg.all;


entity stream_to_status_short is
    Port (  clk_i : in  std_logic;
            stream_i : in  t_stream;
            stream_vld_i : in  std_logic;
            stream_rdy_o : out  std_logic;
            status_o : out  t_status;
            status_vld_o : out  std_logic;
            status_rdy_i : in  std_logic);
end stream_to_status_short;

architecture rtl of stream_to_status_short is

    type t_state is (
        idle_s,
        mac_one_s,
        mac_two_s,
        mac_three_s,
        ether_type_s
    );

    signal state : t_state := idle_s;
    signal mac_count : integer range 0 to 3;
    signal byte : integer range 0 to 3;
    signal status_vld : std_logic;

begin

status_vld_o <= status_vld;

p_stream_to_status : process (clk_i)
begin
    if rising_edge(clk_i) then
        if status_rdy_i = '1' then
            status_vld <= '0';
        end if;
        
        stream_rdy_o <= '0';
        
        case state is
            when idle_s =>
                stream_rdy_o <= '1';
                if status_rdy_i = '1' or status_vld = '0' then
                    if stream_vld_i = '1' and stream_i.tag = SOF and stream_i.data(7 downto 0) = mac_raw_stream then
                        state <= mac_one_s;
                        status_o.data <= stream_to_status_short_status;
                        status_o.tag <= SOF; 
                        status_vld <= '1';
                        byte <= 0;
                    end if;
                end if;
            
            when mac_one_s =>
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    status_o.data <= stream_i.data(31-8*byte downto 24-8*byte);
                    status_o.tag <= DATA;
                    status_vld <= '1';
                    byte <= byte + 1;
                    if byte = 3 then
                        state <= mac_two_s;
                        stream_rdy_o <= '1';
                        byte <= 0;
                    end if;
                end if;
            
            when mac_two_s =>
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    status_o.data <= stream_i.data(31-8*byte downto 24-8*byte);
                    status_o.tag <= DATA;
                    status_vld <= '1';
                    byte <= byte + 1;
                    if byte = 3 then
                        state <= mac_three_s;
                        byte <= 0;
                        stream_rdy_o <= '1';
                    end if;
                end if;
            
            when mac_three_s =>
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    status_o.data <= stream_i.data(31-8*byte downto 24-8*byte);
                    status_o.tag <= DATA;
                    status_vld <= '1';
                    byte <= byte + 1;
                    if byte = 3 then
                        state <= ether_type_s;
                        stream_rdy_o <= '1';
                        byte <= 0;
                    end if;
                end if;
            
            when ether_type_s =>
                if stream_vld_i = '1' and (status_rdy_i = '1' or status_vld = '0') then
                    status_o.data <= stream_i.data(31-8*byte downto 24-8*byte);
                    byte <= byte + 1;
                    status_vld <= '1';
                    if byte = 3 then
                        state <= idle_s;
                        stream_rdy_o <= '1';
                        status_o.tag <= EOF;
                        byte <= 0;
                    end if;
                end if;
 

        end case;
    end if;
end process p_stream_to_status;

end architecture rtl;