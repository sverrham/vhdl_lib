--==========================================================================================
-- This VVC was generated with UVVM VVC Generator
--==========================================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

use work.vld_rdy_bfm_pkg.all;
use work.transaction_pkg.all;

--==========================================================================================
entity vld_rdy_vvc is
  generic (
    --<USER_INPUT> Insert interface specific generic constants here
    -- Example: 
    -- GC_ADDR_WIDTH                            : integer range 1 to C_VVC_CMD_ADDR_MAX_LENGTH;
    GC_DATA_WIDTH                            : integer range 1 to C_VVC_CMD_DATA_MAX_LENGTH;
    GC_INSTANCE_IDX                          : natural;
    GC_VLD_RDY_BFM_CONFIG                    : t_vld_rdy_bfm_config      := C_VLD_RDY_BFM_CONFIG_DEFAULT;
    GC_CMD_QUEUE_COUNT_MAX                   : natural                   := C_CMD_QUEUE_COUNT_MAX;
    GC_CMD_QUEUE_COUNT_THRESHOLD             : natural                   := C_CMD_QUEUE_COUNT_THRESHOLD;
    GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY    : t_alert_level             := C_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY;
    GC_RESULT_QUEUE_COUNT_MAX                : natural                   := C_RESULT_QUEUE_COUNT_MAX;
    GC_RESULT_QUEUE_COUNT_THRESHOLD          : natural                   := C_RESULT_QUEUE_COUNT_THRESHOLD;
    GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY : t_alert_level             := C_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY
  );
  port (
    --<USER_INPUT> Insert BFM interface signals here
    -- Example: 
    -- vld_rdy_vvc_if              : inout t_vld_rdy_if := init_vld_rdy_if_signals(GC_ADDR_WIDTH, GC_DATA_WIDTH); 
    tx_data              : out std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    tx_data_vld          : out std_logic;
    tx_data_rdy          : in std_logic;
    rx_data              : in std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    rx_data_vld          : in std_logic;
    rx_data_rdy          : out std_logic;
    -- VVC control signals: 
    -- rst                         : in std_logic; -- Optional VVC Reset
    clk                         : in std_logic
  );
end entity vld_rdy_vvc;

--==========================================================================================
--==========================================================================================
architecture struct of vld_rdy_vvc is
 
begin


  -- VLD_RDY RX VVC
  i1_vld_rdy_rx: entity work.vld_rdy_rx_vvc
  generic map (
    --<USER_INPUT> Insert interface specific generic constants here
    -- Example: 
    GC_DATA_WIDTH                             => GC_DATA_WIDTH,
    GC_INSTANCE_IDX                           => GC_INSTANCE_IDX,
    GC_CHANNEL                                => RX,
    GC_VLD_RDY_BFM_CONFIG                     => GC_VLD_RDY_BFM_CONFIG,
    GC_CMD_QUEUE_COUNT_MAX                    => GC_CMD_QUEUE_COUNT_MAX,
    GC_CMD_QUEUE_COUNT_THRESHOLD              => GC_CMD_QUEUE_COUNT_THRESHOLD,
    GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY     => GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY,
    GC_RESULT_QUEUE_COUNT_MAX                 => GC_RESULT_QUEUE_COUNT_MAX,
    GC_RESULT_QUEUE_COUNT_THRESHOLD           => GC_RESULT_QUEUE_COUNT_THRESHOLD,
    GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY  => GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY
  )
  port map (
  --<USER_INPUT> Please insert the proper interface needed for this leaf VVC
  -- Example:
    -- vld_rdy_vvc_if         => vld_rdy_vvc_if,
    -- rst                 => rst,  -- Optional VVC Reset
    rx_data             => rx_data,
    rx_data_vld         => rx_data_vld,
    rx_data_rdy         => rx_data_rdy,
    clk                 => clk
  );


  -- VLD_RDY TX VVC
  i1_vld_rdy_tx: entity work.vld_rdy_tx_vvc
  generic map (
    --<USER_INPUT> Insert interface specific generic constants here
    -- Example: 
    GC_DATA_WIDTH                             => GC_DATA_WIDTH,
    GC_INSTANCE_IDX                           => GC_INSTANCE_IDX,
    GC_CHANNEL                                => TX,
    GC_VLD_RDY_BFM_CONFIG                     => GC_VLD_RDY_BFM_CONFIG,
    GC_CMD_QUEUE_COUNT_MAX                    => GC_CMD_QUEUE_COUNT_MAX,
    GC_CMD_QUEUE_COUNT_THRESHOLD              => GC_CMD_QUEUE_COUNT_THRESHOLD,
    GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY     => GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY,
    GC_RESULT_QUEUE_COUNT_MAX                 => GC_RESULT_QUEUE_COUNT_MAX,
    GC_RESULT_QUEUE_COUNT_THRESHOLD           => GC_RESULT_QUEUE_COUNT_THRESHOLD,
    GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY  => GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY
  )
  port map (
  --<USER_INPUT> Please insert the proper interface needed for this leaf VVC
  -- Example:
    tx_data             => tx_data,
    tx_data_vld         => tx_data_vld,
    tx_data_rdy         => tx_data_rdy,
    -- rst                 => rst,  -- Optional VVC Reset
    clk                 => clk
  );


  -- psl default clock is rising_edge (clk);
  -- psl assert always
  --   tx_data_vld = '1' and tx_data_rdy = '0' -> next tx_data_vld = '1' and stable(tx_data);

end struct;

