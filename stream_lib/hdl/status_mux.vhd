
library ieee;
use ieee.std_logic_1164.all;

library stream_lib;
use stream_lib.status_pkg.all;


-- Mux module to select between different status sources
-- stays on one source from status SOF until EOF on that source.
-- does a round robin between the sources.
-- Number of inputs defined byt the generic STATUS_MUX_SOURCES
-- if a stream has valid data but its not SOF we will discard the data until we get a SOF.
-- Discarding data will be done one word at a time before checking other sources so it does not deadlock.
entity status_mux is
    generic (
        STATUS_MUX_SOURCES : integer := 2
    );
    port (
        clk            : in std_logic;
        rst            : in std_logic;
        status_in_vld  : in std_logic_vector(STATUS_MUX_SOURCES-1 downto 0);
        status_in_rdy  : out std_logic_vector(STATUS_MUX_SOURCES-1 downto 0);
        status_in      : in t_status_array(STATUS_MUX_SOURCES-1 downto 0);
        status_out_vld : out std_logic;
        status_out_rdy : in  std_logic;
        status_out     : out t_status
    );
end entity;

architecture rtl of status_mux is

    type t_state is (idle_s, data_s, discard_s);
    signal state : t_state;
    signal current_source : integer := 0;
    signal status_out_vld_reg : std_logic;

begin
  
    status_out_vld <= status_out_vld_reg;

    process (state, current_source, status_out_vld_reg, status_out_rdy) Is
    begin
      for i in 0 to STATUS_MUX_SOURCES-1 loop
        if current_source = i and (state = data_s or state = discard_s) and (status_out_vld_reg = '0' or status_out_rdy = '1') then
          status_in_rdy(i) <= '1';
        else
          status_in_rdy(i) <= '0';
        end if;
      end loop; 
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if status_out_rdy = '1' then
          status_out_vld_reg <= '0';
        end if;

        -- status_in_rdy <= (others => '0');
        case state is
          when idle_s =>
            -- loop through all sources until we find a valid active source.
            -- Discard data if active data but not SOF
            
            if current_source = STATUS_MUX_SOURCES-1 then
              current_source <= 0;
            else
              current_source <= current_source + 1;
            end if;

            if status_in_vld(current_source) = '1' then
              if status_in(current_source).tag = SOF then
                -- Found a valid source, move to data state.
                state <= data_s;
                current_source <= current_source;
              else
                -- Discard data.
                -- status_in_rdy(current_source) <= '1';
                state <= discard_s;
                current_source <= current_source;
              end if;
            end if;

          when discard_s =>
            -- Discards one word of data.
            -- Changes input so we check for data on other sources.
            if current_source = STATUS_MUX_SOURCES-1 then
              current_source <= 0;
            else
              current_source <= current_source + 1;
            end if;

            state <= idle_s;

          when data_s =>
            -- Send out data from current source until we get EOF.
            if status_in_vld(current_source) = '1' and (status_out_vld_reg = '0' or status_out_rdy = '1') then
              status_out <= status_in(current_source);
              status_out_vld_reg <= '1';
              -- status_in_rdy(current_source) <= '1';
              if status_in(current_source).tag = EOF then
                state <= idle_s;
                if current_source = STATUS_MUX_SOURCES-1 then
                  current_source <= 0;
                else
                  current_source <= current_source + 1;
                end if;
              end if;
            end if;

            end case;
          
          if rst = '1' then
            state <= idle_s;
            current_source <= 0;
            status_out_vld_reg <= '0';
          end if;
        end if;
    end process;

end architecture;

