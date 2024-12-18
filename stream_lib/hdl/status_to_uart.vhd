
library ieee;
use ieee.std_logic_1164.all;

library stream_lib;
use stream_lib.status_pkg.all;

library olo_lib;
use olo_lib.olo_base_pkg_array.all;

-- Encapsulate status messages and send them out, expected to be sent on uart.
--
-- Encapsulation to enable splitting the messages when received on uart.
-- Simple encapsulation end with /r/n just so a terminal will split them out.
-- Also add simple encapsulation start SHA and end AHS so messages will be 
-- encapsulated with:
--  SHA <message> ASH/r/n
entity status_to_uart is
    port (
        clk   : in std_logic;
        rst : in std_logic;
        pps : in std_logic;
        status : in t_status;
        status_vld : in std_logic;
        status_rdy : out std_logic;
        uart_data : out std_logic_vector(7 downto 0);
        uart_data_vld : out std_logic;
        uart_data_rdy : in std_logic
    );
end entity;

architecture rtl of status_to_uart is

    type t_state is (header_s, data_s, end_s, rn_s);
    signal state : t_state;

    signal header : StlvArray8_t(0 to 2) := (x"53", x"48", x"41"); -- SHA
    signal rn : StlvArray8_t(0 to 1) := (x"0D", x"0A"); --\r\n
    signal uart_data_vld_reg : std_logic;

    -- Debug
    signal status_message_no_sof : std_logic;
    signal pps_seen : std_logic;
    signal stuck_in_data : std_logic; 
begin

    uart_data_vld <= uart_data_vld_reg;

   process (clk)
    variable byte : integer range 0 to 3 := 0;
   begin
    if rising_edge(clk) then
        if uart_data_rdy = '1' then
            uart_data_vld_reg <= '0';
        end if;
        status_rdy <= '0';
        
        case state is      
            when header_s =>
                pps_seen <= '0';

                if status_vld = '1' then
                    -- we should only have SOF if we have valid data here
                    if status.tag /= SOF then
                        status_message_no_sof <= '1';
                    end if;
                   
                    -- send out the header
                    if uart_data_vld_reg = '0' or uart_data_rdy = '1' then
                        uart_data <= header(byte);
                        uart_data_vld_reg <= '1';
                        byte := byte + 1;
                    end if;

                    if byte = 3 then
                        state <= data_s;
                        byte := 0;
                    end if; 
                    
                end if;
            when data_s =>
                -- debug if we see two pps we are stuck here.
                if pps = '1' then
                    pps_seen <= '1';
                    if pps_seen = '1' then
                        stuck_in_data <= '1';
                        state <= end_s; -- just finish the framing.
                    end if;
                end if;

                -- send data on input channel until EOF
                if status_vld = '1' then
                    if uart_data_vld_reg = '0' or uart_data_rdy = '1' then
                        status_rdy <= '1';
                        uart_data <= status.data;
                        uart_data_vld_reg <= '1';

                        if status.tag = EOF then
                            state <= end_s;
                        end if;
                    end if;

                end if;

            when end_s => 
                -- Send the framing
                -- send out the header
                if uart_data_vld_reg = '0' or uart_data_rdy = '1' then
                    uart_data <= header(2-byte);
                    uart_data_vld_reg <= '1';
                    byte := byte + 1;
                end if;

                if byte = 3 then
                    state <= rn_s;
                    byte := 0;
                end if; 

            when rn_s =>
                if uart_data_vld_reg = '0' or uart_data_rdy = '1' then
                    uart_data <= rn(byte);
                    uart_data_vld_reg <= '1';
                    byte := byte + 1;
                end if;

                if byte = 2 then
                    state <= header_s;
                    byte := 0;
                end if; 

            end case;

            if rst = '1' then
                state <= header_s;
                status_rdy <= '0';
                uart_data_vld_reg <= '0';
            end if;
    end if;
   end process; 

end architecture;