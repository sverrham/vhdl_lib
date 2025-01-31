

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stream_lib;
use stream_lib.status_pkg.all;

-- Module to profile a valid ready bus.
-- with clock frequency and bus width it calculates bus utilization and bitrates.
entity vld_rdy_profiler is
    port (
        clk   : in std_logic;

        vld : in std_logic;
        rdy : in std_logic;

        pps : in std_logic; -- Pulse per second signal, measurement period.

        status : out t_status;
        status_vld : out std_logic;
        status_rdy : in  std_logic
    );
end entity vld_rdy_profiler;

architecture rtl of vld_rdy_profiler is

    type t_state is (idle_s, send_transitions_s);
    signal state : t_state;

    signal count : unsigned(31 downto 0) := (others => '0');
    signal transitions : std_logic_vector(31 downto 0);

    signal status_vld_reg : std_logic := '0';
begin

-- count transitions, and report between each pps
process (clk)
begin
    if rising_edge(clk) then
        if pps = '1' then
            count <= (others => '0');
        elsif vld = '1' and rdy = '1' then
            count <= count + 1;
        end if;
    end if;
end process;

status_vld <= status_vld_reg;

send_status : process (clk)
    variable transition : integer range 0 to 3;
begin
    if rising_edge(clk) then
        if status_rdy = '1' then
            status_vld_reg <= '0';
        end if;

        case state is
            when idle_s => 
                if pps = '1' and status_vld_reg = '0' then
                    transitions <= std_logic_vector(count);
                    status_vld_reg <= '1';
                    status.data <= vld_rdy_profiler_status; 
                    status.tag <= SOF;
                    state <= send_transitions_s;
                    transition := 0;
                end if;

            when send_transitions_s =>
                if status_vld_reg = '0' or status_rdy = '1' then
                    status_vld_reg <= '1';
                    if transition = 3 then
                        status.tag <= EOF;
                        status.data <= transitions(7 downto 0);
                        state <= idle_s;
                    else
                        status.tag <= DATA;
                        status.data <= transitions(31-transition*8 downto 24-transition*8);
                        transition := transition + 1;
                    end if;
                end if;

        end case;

    end if;
end process;


end architecture;