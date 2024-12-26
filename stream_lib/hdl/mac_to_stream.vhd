
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stream_lib;
use stream_lib.stream_pkg.all;

-- module to convert from mac to internal stream of data.
-- This is for the interface from this MAC module 
-- https://github.com/sverrham/ethernet_mac.git
-- 
-- internal frame format defined in doc/ethernet_local_frame.md
-- 
-- This strips the pkt length from the ethernet mac module.
-- we add one header word with the SOF tag and the rest is the 
-- ethernet frame.
entity mac_to_stream is
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;
        -- Mac interface
        empty_i : in std_logic;
        rd_en_o : out std_logic;
        data_i  : in std_logic_vector(7 downto 0);
        -- stream interface
        data_o : out t_stream;
        data_vld_o : out std_logic;
        data_rdy_i : in std_logic);
end entity;

architecture rtl of mac_to_stream is

    type t_state is (
        s_idle,
        s_length_high,
        s_length_low,
        s_data
    );

    signal state : t_state;

    signal phase : integer range 0 to 3 := 0;
    signal data_buffer : std_logic_vector(23 downto 0);
    signal pkt_bytes : unsigned(15 downto 0);
    signal pkt_lengt_wrong : boolean;
    signal first_byte : boolean;

    signal data_vld : std_logic;

begin
    data_vld_o <= data_vld;

    p_main : process (clk_i) is
        variable v_data : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk_i) then
            rd_en_o <= '0';
            if data_rdy_i = '1' then
                data_vld <= '0';
            end if;

            case state is
                when s_idle =>
                    if empty_i = '0' then
                        state <= s_length_high;
                        data_o.data <= x"000000" & mac_raw_stream;
                        data_o.tag <= SOF;
                        data_vld <= '1';
                        phase <= 0;
                        pkt_bytes(15 downto 8) <= unsigned(data_i); 
                        rd_en_o <= '1';
                        pkt_lengt_wrong <= false;
                    end if;    

                when s_length_high =>
                    rd_en_o <= '1';
                    pkt_bytes(15 downto 8) <= unsigned(data_i);
                    state <= s_length_low;

                when s_length_low => 
                    rd_en_o <= '1';
                    pkt_bytes(7 downto 0) <= unsigned(data_i) - 1;
                    state <= s_data;

                when s_data =>
                    rd_en_o <= '1';
                    case phase is
                        when 0 to 2 =>
                            pkt_bytes <= pkt_bytes - 1;
                            data_buffer(23-phase*8 downto 16-phase*8) <= data_i;
                            phase <= phase + 1;
                            first_byte <= true;
                        when 3 =>
                            -- Store away byte if we are waiting on ready. use at once if we can.
                            if first_byte then
                                v_data := data_i;
                                first_byte <= false;
                            end if;

                            if data_rdy_i = '1' or data_vld = '0' then
                                pkt_bytes <= pkt_bytes - 1;
                                data_o.data <= data_buffer & v_data ;
                                if pkt_bytes = 0 then
                                    data_o.tag <= EOF;
                                else
                                    data_o.tag <= DATA;
                                end if;
                                data_vld <= '1';
                                phase <= 0;
                            else
                                rd_en_o <= '0';
                            end if;

                        end case;
                    
                    if empty_i = '1' and (data_rdy_i = '1' or data_vld = '0') then
                        pkt_lengt_wrong <= pkt_bytes /= 0;
                        rd_en_o <= '0';
                        state <= s_idle;
                    end if;

            end case;

            if rst_i = '1' then
                state <= s_idle;
                data_vld <= '0';
            end if;
        end if;
    end process;

end architecture;