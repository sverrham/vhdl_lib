--==========================================================================================
-- This VVC was generated with UVVM VVC Generator
--==========================================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

--==========================================================================================
--==========================================================================================
package vld_rdy_bfm_pkg is

  --==========================================================================================
  -- Types and constants for VLD_RDY BFM
  --==========================================================================================
  constant C_BFM_SCOPE : string := "VLD_RDY BFM";

  -- Optional interface record for BFM signals
  
  type t_vld_rdy_rx_if is record
    rx_data : std_logic_vector; -- from dut
    rx_data_vld : std_logic;    -- from dut
    rx_data_rdy : std_logic;    -- to dut
  end record;
   
  -- Configuration record to be assigned in the test harness.
  type t_vld_rdy_bfm_config is
  record
    --<USER_INPUT> Insert all BFM config parameters here
    -- Example:
    id_for_bfm               : t_msg_id; -- To replace default log msg IDs. <USER_INPUT> Adapt name to msg IDs used in this BFM
    -- id_for_bfm_wait          : t_msg_id; -- To replace default log msg IDs. <USER_INPUT> Adapt name to msg IDs used in this BFM
    -- id_for_bfm_poll          : t_msg_id; -- To replace default log msg IDs. <USER_INPUT> Adapt name to msg IDs used in this BFM
    -- max_wait_cycles          : integer;
    -- max_wait_cycles_severity : t_alert_level;
    -- clock_period             : time;
    pause_probability        : real; -- Probability of not setting the valid signal
  end record;

  -- Define the default value for the BFM config
  constant C_VLD_RDY_BFM_CONFIG_DEFAULT : t_vld_rdy_bfm_config := (
    --<USER_INPUT> Insert defaults for all BFM config parameters here
    -- Example:
    id_for_bfm               => ID_BFM,      --<USER_INPUT> Adapt name and ID to msg IDs used in this BFM
    -- id_for_bfm_wait          => ID_BFM_WAIT, --<USER_INPUT> Adapt name and ID to msg IDs used in this BFM
    -- id_for_bfm_poll          => ID_BFM_POLL, --<USER_INPUT> Adapt name and ID to msg IDs used in this BFM
    -- max_wait_cycles          => 10,
    -- max_wait_cycles_severity => failure,
    -- clock_period             => -1 ns
    pause_probability        => 0.0
  );

  --==========================================================================================
  -- BFM procedures
  --==========================================================================================
  --<USER_INPUT> Insert BFM procedure declarations here, e.g. read and write operations
  -- It is recommended to also have an init function which sets the BFM signals to their default state

    -- Procedure to write data out, with valid and ready signals.
    procedure vld_rdy_write(
      signal tx_data : out std_logic_vector;
      signal tx_data_vld : out std_logic;
      signal tx_data_rdy : in std_logic;
      signal clk : in std_logic;
      constant data : std_logic_vector;
      constant config : t_vld_rdy_bfm_config 
    );

    procedure vld_rdy_read(
      signal rx_data : in std_logic_vector;
      signal rx_data_vld : in std_logic;
      signal rx_data_rdy : out std_logic;
      signal clk : in std_logic;
      variable data : out std_logic_vector;
      constant config : t_vld_rdy_bfm_config
    );

end package vld_rdy_bfm_pkg;

package body vld_rdy_bfm_pkg is

  --<USER_INPUT> Insert BFM procedure implementation here.

  -- Procedure to write data out, with valid and ready signals.
  procedure vld_rdy_write(
    signal tx_data : out std_logic_vector;
    signal tx_data_vld : out std_logic;
    signal tx_data_rdy : in std_logic;
    signal clk : in std_logic;
    constant data : std_logic_vector;
    constant config : t_vld_rdy_bfm_config
  ) is
    variable v_rdy : std_logic;
  begin
    tx_data <= data;
    
    tx_data_vld <= '0'; -- Default it low

    -- Should be configurable delay here to simulate backpressure

    -- wait for pause pattern if configured
    if config.pause_probability > 0.0 then
      pause_loop: while true loop
        if real(random(0, 100)) / 100.0 < config.pause_probability then
          wait until rising_edge(clk);
        else
          exit pause_loop;
        end if;
      end loop pause_loop;
    end if;


    tx_data_vld <= '1'; -- Set it high

    wait until rising_edge(clk);

    v_rdy := tx_data_rdy;

    -- loop until ready signal is high
    while v_rdy = '0' loop
      wait until rising_edge(clk);
      v_rdy := tx_data_rdy;
    end loop;

    tx_data_vld <= '0'; -- Set it low

  end procedure vld_rdy_write;


  procedure vld_rdy_read(
    signal rx_data : in std_logic_vector;
    signal rx_data_vld : in std_logic;
    signal rx_data_rdy : out std_logic;
    signal clk : in std_logic;
    variable data : out std_logic_vector;
    constant config : t_vld_rdy_bfm_config
  ) is
  begin
    rx_data_rdy <= '0'; -- Default it low

    -- If valid signal is low wait for it
    if rx_data_vld = '0' then
      wait until rx_data_vld = '1';
    end if;


    -- wait for pause pattern if configured
    if config.pause_probability > 0.0 then
      pause_loop: while true loop
        if real(random(0, 100)) / 100.0 < config.pause_probability then
          wait until rising_edge(clk);
        else
          exit pause_loop;
        end if;
      end loop pause_loop;
    end if;

    rx_data_rdy <= '1'; -- Set it high
    wait until rising_edge(clk);

    data(rx_data'range) := rx_data;
    rx_data_rdy <= '0'; -- Set it low

  end procedure vld_rdy_read;


end package body vld_rdy_bfm_pkg;
