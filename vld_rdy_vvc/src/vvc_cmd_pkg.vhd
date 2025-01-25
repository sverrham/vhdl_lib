--==========================================================================================
-- This VVC was generated with UVVM VVC Generator
--==========================================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

use work.transaction_pkg.all;

--==========================================================================================
--==========================================================================================
package vvc_cmd_pkg is

  alias t_operation is work.transaction_pkg.t_operation;

  --==========================================================================================
  -- t_vvc_cmd_record
  -- - Record type used for communication with the VVC
  --==========================================================================================
  type t_vvc_cmd_record is record
    -- VVC dedicated fields
    --<USER_INPUT> Insert all data types needed to transport data to the BFM here.
    -- This includes data field, address field, constraints (e.g. timeout), etc.
    -- Example: 
    data                      : std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH-1 downto 0);
    -- max_receptions            : integer;
    -- timeout                   : time;
    -- Common VVC fields
    operation                 : t_operation;
    proc_call                 : string(1 to C_VVC_CMD_STRING_MAX_LENGTH);
    msg                       : string(1 to C_VVC_CMD_STRING_MAX_LENGTH);
    data_routing              : t_data_routing;
    cmd_idx                   : natural;
    command_type              : t_immediate_or_queued;
    msg_id                    : t_msg_id;
    gen_integer_array         : t_integer_array(0 to 1); -- Increase array length if needed
    gen_boolean               : boolean; -- Generic boolean
    timeout                   : time;
    alert_level               : t_alert_level;
    delay                     : time;
    quietness                 : t_quietness;
    parent_msg_id_panel       : t_msg_id_panel;
  end record t_vvc_cmd_record;

  constant C_VVC_CMD_DEFAULT : t_vvc_cmd_record := (
    --<USER_INPUT> Set the fields you added to the t_vvc_cmd_record above to their default value here
    -- Example:
    data                      => (others => '0'),
    -- max_receptions            => 1,
    -- timeout                   => 0 ns,
    -- Common VVC fields
    operation                 => NO_OPERATION,
    proc_call                 => (others => NUL),
    msg                       => (others => NUL),
    data_routing              => NA,
    cmd_idx                   => 0,
    command_type              => NO_COMMAND_TYPE,
    msg_id                    => NO_ID,
    gen_integer_array         => (others => -1),
    gen_boolean               => false,
    timeout                   => 0 ns,
    alert_level               => FAILURE,
    delay                     => 0 ns,
    quietness                 => NON_QUIET,
    parent_msg_id_panel       => C_UNUSED_MSG_ID_PANEL
  );

  --==========================================================================================
  -- shared_vvc_cmd
  -- - Shared variable used for transmitting VVC commands
  --==========================================================================================
  shared variable shared_vvc_cmd : t_vvc_cmd_record := C_VVC_CMD_DEFAULT;

  --==========================================================================================
  -- t_vvc_result, t_vvc_result_queue_element, t_vvc_response and shared_vvc_response :
  --
  -- - Used for storing the result of a BFM procedure called by the VVC,
  --   so that the result can be transported from the VVC to for example a sequencer via
  --   fetch_result() as described in uvvm_vvc_framework/Common_VVC_Methods QuickRef.
  -- - t_vvc_result includes the return value of the procedure in the BFM. It can also
  --   be defined as a record if multiple values shall be transported from the BFM
  --==========================================================================================
  subtype  t_vvc_result is std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH - 1 downto 0);

  type t_vvc_result_queue_element is record
    cmd_idx       : natural;   -- from UVVM handshake mechanism
    result        : t_vvc_result;
  end record t_vvc_result_queue_element;

  type t_vvc_response is record
    fetch_is_accepted    : boolean;
    transaction_result   : t_transaction_result;
    result               : t_vvc_result;
  end record t_vvc_response;

  shared variable shared_vvc_response : t_vvc_response;

  --==========================================================================================
  -- t_last_received_cmd_idx :
  -- - Used to store the last queued cmd in VVC interpreter.
  --==========================================================================================
  type t_last_received_cmd_idx is array (t_channel range <>, natural range <>) of integer;

  --==========================================================================================
  -- shared_vvc_last_received_cmd_idx
  --  - Shared variable used to get last queued index from VVC to sequencer
  --==========================================================================================
  shared variable shared_vvc_last_received_cmd_idx : t_last_received_cmd_idx(t_channel'left to t_channel'right, 0 to C_VVC_MAX_INSTANCE_NUM - 1) := (others => (others => -1));

  --==========================================================================================
  -- Procedures
  --==========================================================================================
  --function to_string (
  --  result : t_vvc_result
  --) return string;

end package vvc_cmd_pkg;

package body vvc_cmd_pkg is

  -- Custom to_string overload needed when result is of a record type
  --function to_string (
  --  result : t_vvc_result
  --) return string is
  --begin
  --  <USER_INPUT> Set the record fields from the t_vvc_result here
  --   Example:
  --   return to_string(result.data_array'length) & " Words";
  --end function to_string;

end package body vvc_cmd_pkg;
