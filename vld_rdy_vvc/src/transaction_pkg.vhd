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
package transaction_pkg is

  --==========================================================================================
  -- t_operation
  -- - VVC and BFM operations
  --==========================================================================================
  type t_operation is (
    -- UVVM common
    NO_OPERATION,
    AWAIT_COMPLETION,
    AWAIT_ANY_COMPLETION,
    ENABLE_LOG_MSG,
    DISABLE_LOG_MSG,
    FLUSH_COMMAND_QUEUE,
    FETCH_RESULT,
    INSERT_DELAY,
    TERMINATE_CURRENT_COMMAND, 
    -- VVC local
    --<USER_INPUT> Expand this type with enums for BFM procedures.
    -- Example: 
    -- TRANSMIT, RECEIVE, EXPECT
    WRITE, READ 
  );

  --<USER_INPUT> Create constants for the maximum sizes to use in this VVC.
  -- You can create VVCs with smaller sizes than these constants, but not larger.
  -- For example, given a VVC with parallel data bus and address bus, constraints
  -- should be added for maximum data length and address length.
  -- Note: if these constants are to be flexible, create similar constants in adaptations_pkg
  -- and use them to assign these constants, see other UVVM VIPs for guidance on how it's done.
  -- Example:
  constant C_VVC_CMD_DATA_MAX_LENGTH   : natural := 40;
  --constant C_VVC_CMD_ADDR_MAX_LENGTH   : natural := 32;
  constant C_VVC_CMD_STRING_MAX_LENGTH : natural := 300;
  constant C_VVC_MAX_INSTANCE_NUM      : natural := C_MAX_VVC_INSTANCE_NUM;
  constant C_DATA_ROUTING_DEFAULT      : t_data_routing := NA;
  --==========================================================================================
  -- Transaction info types, constants and global signal
  --==========================================================================================

  -- VVC Meta
  type t_vvc_meta is record
    msg     : string(1 to C_VVC_CMD_STRING_MAX_LENGTH);
    cmd_idx : integer;
  end record t_vvc_meta;

  constant C_VVC_META_DEFAULT : t_vvc_meta := (
    msg     => (others => ' '),
    cmd_idx => -1
  );

  -- NOTE:
  --   If compound transaction is needed see example usage in Bitvis VIP SBI.
  --   If sub transaction is needed see example usage in Bitvis VIP Avalon-MM.
  -- Base transaction
  type t_base_transaction is record
    operation           : t_operation;
    --<USER_INPUT> Insert transaction information here.
    --address             : unsigned(C_VVC_CMD_ADDR_MAX_LENGTH-1 downto 0);
    --data                : std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH-1 downto 0);
    vvc_meta            : t_vvc_meta;
    transaction_status  : t_transaction_status;
  end record t_base_transaction;

  constant C_BASE_TRANSACTION_SET_DEFAULT : t_base_transaction := (
    operation           => NO_OPERATION,
    --<USER_INPUT> Insert transaction information here.
    --address             => (others => '0'),
    --data                => (others => '0'),
    vvc_meta            => C_VVC_META_DEFAULT,
    transaction_status  => INACTIVE
  );

  -- Transaction group
  type t_transaction_group is record
    bt : t_base_transaction;
  end record t_transaction_group;

  constant C_TRANSACTION_GROUP_DEFAULT : t_transaction_group := (
    bt => C_BASE_TRANSACTION_SET_DEFAULT
  );

  subtype t_sub_channel is t_channel range RX to TX;

  -- Global vvc_transaction_info trigger signal
  type t_vld_rdy_transaction_trigger_array is array (t_sub_channel range <>, natural range <>) of std_logic;
  signal global_vld_rdy_vvc_transaction_trigger : t_vld_rdy_transaction_trigger_array(t_sub_channel'left to t_sub_channel'right, 0 to C_VVC_MAX_INSTANCE_NUM - 1) := (others => (others => '0'));

  -- Shared vvc_transaction_info info variable
  type t_vld_rdy_transaction_group_array is array (t_sub_channel range <>, natural range <>) of t_transaction_group;
  shared variable shared_vld_rdy_vvc_transaction_info : t_vld_rdy_transaction_group_array(t_sub_channel'left to t_sub_channel'right, 0 to C_VVC_MAX_INSTANCE_NUM - 1) := (others => (others => C_TRANSACTION_GROUP_DEFAULT));

end package transaction_pkg;
