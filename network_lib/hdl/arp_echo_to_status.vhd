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
        rst_i : in std_logic;
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
        send_data_s --,
    );

    signal state : t_state := idle_s;
    signal mac_count : integer range 0 to 3;
    signal byte : integer range 0 to 3;
    signal status_vld : std_logic;

    signal fifo_stream_data : std_logic_vector(33 downto 0);
    signal fifo_stream_data_vld : std_logic;
    signal fifo_stream_data_rdy : std_logic;
    signal fifo_status_data : std_logic_vector(33 downto 0);
    signal fifo_status_vld : std_logic;
    signal fifo_status_rdy : std_logic;
    signal fifo_full : std_logic;
    signal fifo_almfull : std_logic;
    signal fifo_empty : std_logic;

    signal send_status : std_logic := '0';
    signal clear_fifo : std_logic := '0';
    signal sending_status : std_logic;
    signal clearing_fifo : std_logic;

    constant START_OF_FRAME : std_logic_vector(1 downto 0) := "00";
    constant DATA_WORD : std_logic_vector(1 downto 0) := "01";
    constant END_OF_FRAME : std_logic_vector(1 downto 0) := "11";

    type t_status_state is (
        idle_s,
        send_status_s,
        wait_one_s,
        clear_data_s
    );

    signal send_status_state : t_status_state := idle_s;

begin

status_vld_o <= status_vld;

p_ethertype_to_status : process (clk_i)
begin
    if rising_edge(clk_i) then
        if sending_status = '1' then
            send_status <= '0';
        end if;
        if clearing_fifo = '1' then
            clear_fifo <= '0';
        end if;

        if fifo_stream_data_rdy = '1' then
            fifo_stream_data_vld <= '0';
        end if;

        case state is
            when idle_s =>
                stream_rdy_o <= '1';
                if stream_vld_i = '1' and stream_i.tag = SOF and stream_i.data(7 downto 0) = mac_raw_stream then
                   state <= mac_s;
                   mac_count <= 0;
                end if;
            
            when mac_s =>
                stream_rdy_o <= '1';
                if stream_vld_i = '1' then
                    fifo_stream_data <= START_OF_FRAME & stream_i.data;
                    fifo_stream_data_vld <= '1';
                    mac_count <= mac_count + 1;
                    if mac_count = 2 then
                        state <= ether_type_s;
                    end if;
                end if;
            
            when ether_type_s =>
                stream_rdy_o <= '1';
                if stream_vld_i = '1' then
                    if stream_i.data(31 downto 16) = x"0806" then
                        -- its a arp packet, lets send stuff out.
                        send_status <= '1';
                        fifo_stream_data <= DATA_WORD & stream_i.data;
                        fifo_stream_data_vld <= '1';

                        state <= send_data_s;
                    else
                        fifo_stream_data <= END_OF_FRAME & stream_i.data;
                        state <= idle_s;
                        stream_rdy_o <= '1';
                        clear_fifo <= '1';
                    end if;
                end if;

            when send_data_s =>
                stream_rdy_o <= '1';
                if stream_vld_i = '1' then
                    fifo_stream_data <= DATA_WORD & stream_i.data;
                    fifo_stream_data_vld <= '1';
                    if stream_i.tag = EOF or fifo_almfull = '1' then
                        -- EOF on input stream or.
                        -- Last word, end transmission and go to idle, to not drop data.
                        fifo_stream_data <= END_OF_FRAME & stream_i.data;
                        state <= idle_s;
                    end if;
                end if;
            
        end case;
    end if;
end process;

-- fifo for status output data
  i_fifo_status : entity olo_lib.olo_base_fifo_sync
    generic map (
        Width_g => 34, -- 32 data and one bit to indicate start of frame, and one to indicate end of frame.
        Depth_g => 128, --64,
        AlmFullOn_g => true,
        AlmFullLevel_G => 120 --63 
    )
    port map (
        Clk       => clk_i,
        Rst       => rst_i,
        In_Data   => fifo_stream_data,
        In_Valid  => fifo_stream_data_vld,
        In_Ready  => fifo_stream_data_rdy,
        In_Level  => open,
        Out_data  => fifo_status_data,
        Out_valid => fifo_status_vld,
        Out_Ready => fifo_status_rdy,
        Out_level => open, 
        Full      => fifo_full,
        AlmFull   => fifo_almfull,
        Empty     => fifo_empty
    );

-- Send the status data out, or clear the data.
p_fifo_status : process (clk_i) is
begin
  if rising_edge(clk_i) then
    sending_status <= '0';
    clearing_fifo <= '0';
    fifo_status_rdy <= '0';
        
    if status_rdy_i = '1' then
        status_vld <= '0';
    end if;
    case send_status_state is    
        when idle_s => 
            -- status_vld <= '0';

            if send_status = '1' and (status_rdy_i = '1' or status_vld = '0') then
                sending_status <= '1';
                send_status_state <= send_status_s;
                status_o.data <= arp_ether_type_status;
                status_o.tag <= SOF;
                status_vld <= '1';
                byte <= 0;
            end if;

            if clear_fifo = '1' then
                clearing_fifo <= '1';
                send_status_state <= clear_data_s;
            end if;

        when send_status_s =>
            if fifo_status_vld = '1' and (status_rdy_i = '1' or status_vld = '0') then
                status_o.data <= fifo_status_data(31-8*byte downto 24-8*byte);
                status_vld <= '1';
                status_o.tag <= DATA;

                if byte = 3 then
                    fifo_status_rdy <= '1';
                    byte <= 0;
                    if fifo_status_data(33 downto 32) = END_OF_FRAME then
                        send_status_state <= idle_s;
                        status_o.tag <= EOF;
                    else
                        send_status_state <= wait_one_s;
                    end if;
                else
                    byte <= byte + 1;
                end if;

        end if;

        when wait_one_s =>
            send_status_state <= send_status_s;

        when clear_data_s =>
            fifo_status_rdy <= '1';
            if fifo_empty = '1' or fifo_status_data(33 downto 32) = END_OF_FRAME then
                send_status_state <= idle_s;
                fifo_status_rdy <= '0';
            end if;
    end case;

  end if;
end process;


end architecture;