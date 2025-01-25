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

use work.vld_rdy_bfm_pkg.all;
use work.vvc_cmd_pkg.all;
use work.td_target_support_pkg.all;
use work.transaction_pkg.all;
use work.vvc_sb_pkg.all;

--==========================================================================================
--==========================================================================================
package vvc_methods_pkg is

  --==========================================================================================
  -- Types and constants for the VLD_RDY VVC
  --==========================================================================================
  constant C_VVC_NAME     : string := "VLD_RDY_VVC";

  signal VLD_RDY_VVCT      : t_vvc_target_record := set_vvc_target_defaults(C_VVC_NAME);
  alias  THIS_VVCT         : t_vvc_target_record is VLD_RDY_VVCT;
  alias  t_bfm_config is t_vld_rdy_bfm_config;

  -- Type found in UVVM-Util types_pkg
  constant C_VLD_RDY_INTER_BFM_DELAY_DEFAULT : t_inter_bfm_delay := (
    delay_type                         => NO_DELAY,
    delay_in_time                      => 0 ns,
    inter_bfm_delay_violation_severity => WARNING
  );

  type t_vvc_config is record
    inter_bfm_delay                       : t_inter_bfm_delay; -- Minimum delay between BFM accesses from the VVC. If parameter delay_type is set to NO_DELAY, BFM accesses will be back to back, i.e. no delay.
    cmd_queue_count_max                   : natural;           -- Maximum pending number in command executor before executor is full. Adding additional commands will result in an ERROR.
    cmd_queue_count_threshold             : natural;           -- An alert with severity 'cmd_queue_count_threshold_severity' will be issued if command executor exceeds this count. Used for early warning if command executor is almost full. Will be ignored if set to 0.
    cmd_queue_count_threshold_severity    : t_alert_level;     -- Severity of alert to be initiated if exceeding cmd_queue_count_threshold.
    result_queue_count_max                : natural;
    result_queue_count_threshold          : natural;
    result_queue_count_threshold_severity : t_alert_level;
    bfm_config                            : t_vld_rdy_bfm_config; -- Configuration for the BFM. See BFM quick reference.
    msg_id_panel                          : t_msg_id_panel;    -- VVC dedicated message ID panel.
    unwanted_activity_severity            : t_alert_level;     -- Severity of alert to be initiated if unwanted activity on the DUT outputs is detected.
  end record t_vvc_config;

  type t_vvc_config_array is array (t_channel range <>, natural range <>) of t_vvc_config;

  constant C_VLD_RDY_VVC_CONFIG_DEFAULT : t_vvc_config := (
    inter_bfm_delay                       => C_VLD_RDY_INTER_BFM_DELAY_DEFAULT,
    cmd_queue_count_max                   => C_CMD_QUEUE_COUNT_MAX, --  from adaptation package
    cmd_queue_count_threshold             => C_CMD_QUEUE_COUNT_THRESHOLD,
    cmd_queue_count_threshold_severity    => C_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY,
    result_queue_count_max                => C_RESULT_QUEUE_COUNT_MAX,
    result_queue_count_threshold          => C_RESULT_QUEUE_COUNT_THRESHOLD,
    result_queue_count_threshold_severity => C_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY,
    bfm_config                            => C_VLD_RDY_BFM_CONFIG_DEFAULT,
    msg_id_panel                          => C_VVC_MSG_ID_PANEL_DEFAULT,
    unwanted_activity_severity            => C_UNWANTED_ACTIVITY_SEVERITY
  );

  type t_vvc_status is record
    current_cmd_idx  : natural;
    previous_cmd_idx : natural;
    pending_cmd_cnt  : natural;
  end record t_vvc_status;

  type t_vvc_status_array is array (t_channel range <>, natural range <>) of t_vvc_status;

  constant C_VVC_STATUS_DEFAULT : t_vvc_status := (
    current_cmd_idx  => 0,
    previous_cmd_idx => 0,
    pending_cmd_cnt  => 0
  );

  shared variable shared_vld_rdy_vvc_config : t_vvc_config_array(t_channel'left to t_channel'right, 0 to C_VVC_MAX_INSTANCE_NUM - 1) := (others => (others => C_VLD_RDY_VVC_CONFIG_DEFAULT));
  shared variable shared_vld_rdy_vvc_status : t_vvc_status_array(t_channel'left to t_channel'right, 0 to C_VVC_MAX_INSTANCE_NUM - 1) := (others => (others => C_VVC_STATUS_DEFAULT));
  shared variable VLD_RDY_VVC_SB            : t_generic_sb;

  --==========================================================================================
  -- Methods dedicated to this VVC
  -- - These procedures are called from the testbench in order for the VVC to execute
  --   BFM calls towards the given interface. The VVC interpreter will queue these calls
  --   and then the VVC executor will fetch the commands from the queue and handle the
  --   actual BFM execution.
  --==========================================================================================

  --<USER_INPUT> Please insert the VVC procedure declarations here 
  --Example with single VVC channel: 
  procedure vld_rdy_write (
    signal   VVCT                : inout t_vvc_target_record;
    constant vvc_instance_idx    : in    integer;
    -- constant addr                : in    unsigned;
    constant data                : in    std_logic_vector;
    constant msg                 : in    string;
    constant scope               : in    string         := C_VVC_CMD_SCOPE_DEFAULT;
    constant parent_msg_id_panel : in    t_msg_id_panel := C_UNUSED_MSG_ID_PANEL -- Only intended for usage by parent HVVCs
  );

  --Example with multiple VVC channels: 
  procedure vld_rdy_receive (
    signal   VVCT                : inout t_vvc_target_record;
    constant vvc_instance_idx    : in    integer;
    -- constant channel             : in    t_channel;
    -- constant addr                : in    unsigned;
  --   constant data                : in    std_logic_vector;
    constant msg                 : in    string;
    constant data_routing        : in    t_data_routing := C_DATA_ROUTING_DEFAULT;
    constant alert_level         : in    t_alert_level  := ERROR;
    constant scope               : in    string         := C_VVC_CMD_SCOPE_DEFAULT;
    constant parent_msg_id_panel : in    t_msg_id_panel := C_UNUSED_MSG_ID_PANEL -- Only intended for usage by parent HVVCs
  );

  --==========================================================================================
  -- Transaction info methods
  --==========================================================================================
  procedure set_global_vvc_transaction_info (
    signal   vvc_transaction_info_trigger : inout std_logic;
    variable vvc_transaction_info_group   : inout t_transaction_group;
    constant vvc_cmd                      : in t_vvc_cmd_record;
    constant vvc_config                   : in t_vvc_config;
    constant transaction_status           : in t_transaction_status;
    constant scope                        : in string := C_VVC_CMD_SCOPE_DEFAULT
  );

  procedure set_global_vvc_transaction_info (
    signal   vvc_transaction_info_trigger : inout std_logic;
    variable vvc_transaction_info_group   : inout t_transaction_group;
    constant vvc_cmd                      : in t_vvc_cmd_record;
    constant vvc_result                   : in t_vvc_result;
    constant transaction_status           : in t_transaction_status;
    constant scope                        : in string := C_VVC_CMD_SCOPE_DEFAULT
  );

  procedure reset_vvc_transaction_info (
    variable vvc_transaction_info_group  : inout t_transaction_group;
    constant vvc_cmd                     : in t_vvc_cmd_record
  );

end package vvc_methods_pkg;

package body vvc_methods_pkg is

  --==========================================================================================
  -- Methods dedicated to this VVC
  --==========================================================================================

  --<USER_INPUT> Please insert the VVC procedure implementations here.
  -- These procedures will be used to forward commands to the VVC executor, which will
  -- call the corresponding BFM procedures. 
  -- Example using single channel:
  procedure vld_rdy_write( 
    signal   VVCT                : inout t_vvc_target_record;
    constant vvc_instance_idx    : in    integer;
    constant data                : in    std_logic_vector;
    constant msg                 : in    string;
    constant scope               : in    string         := C_VVC_CMD_SCOPE_DEFAULT;
    constant parent_msg_id_panel : in    t_msg_id_panel := C_UNUSED_MSG_ID_PANEL -- Only intended for usage by parent HVVCs
  ) is
    constant C_PROC_NAME : string := "vld_rdy_write";
    constant C_PROC_CALL : string := C_PROC_NAME & "(" & to_string(VVCT, vvc_instance_idx)  -- First part common for all
            --  & ", " & to_string(addr, HEX, AS_IS, INCL_RADIX) & ", " & to_string(data, HEX, AS_IS, INCL_RADIX) & ")";
             & ", " & to_string(data, HEX, AS_IS, INCL_RADIX) & ")";
    -- variable v_normalised_addr    : unsigned(C_VVC_CMD_ADDR_MAX_LENGTH-1 downto 0) := 
            --  normalize_and_check(addr, shared_vvc_cmd.addr, ALLOW_WIDER_NARROWER, "addr", "shared_vvc_cmd.addr", C_PROC_CALL & " called with too wide addr. " & msg);
    variable v_normalised_data    : std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH-1 downto 0) := 
             normalize_and_check(data, shared_vvc_cmd.data, ALLOW_WIDER_NARROWER, "data", "shared_vvc_cmd.data", C_PROC_CALL & " called with too wide data. " & msg);
    variable v_msg_id_panel : t_msg_id_panel := shared_msg_id_panel;
  begin
  -- Create command by setting common global 'VVCT' signal record and dedicated VVC 'shared_vvc_cmd' record
  -- locking semaphore in set_general_target_and_command_fields to gain exclusive right to VVCT and shared_vvc_cmd
  -- semaphore gets unlocked in await_cmd_from_sequencer of the targeted VVC
    set_general_target_and_command_fields(VVCT, vvc_instance_idx, TX, C_PROC_CALL, msg, QUEUED, WRITE);
    -- shared_vvc_cmd.addr                := v_normalised_addr;
    shared_vvc_cmd.data                := v_normalised_data;
    shared_vvc_cmd.parent_msg_id_panel := parent_msg_id_panel;
    if parent_msg_id_panel /= C_UNUSED_MSG_ID_PANEL then
      v_msg_id_panel := parent_msg_id_panel;
    end if;
    send_command_to_vvc(VVCT, std.env.resolution_limit, scope, v_msg_id_panel);
  end procedure;

  -- Example using multiple channels:
  procedure vld_rdy_receive (
    signal   VVCT                : inout t_vvc_target_record;
    constant vvc_instance_idx    : in    integer;
  --   constant channel             : in    t_channel;
    constant msg                 : in    string;
    constant data_routing        : in    t_data_routing := C_DATA_ROUTING_DEFAULT;
    constant alert_level         : in    t_alert_level  := ERROR;
    constant scope               : in    string         := C_VVC_CMD_SCOPE_DEFAULT;
    constant parent_msg_id_panel : in    t_msg_id_panel := C_UNUSED_MSG_ID_PANEL -- Only intended for usage by parent HVVCs
  ) is
    constant C_PROC_NAME : string := "vld_rdy_receive";
    -- constant C_PROC_CALL : string := C_PROC_NAME & "(" & to_string(VVCT, vvc_instance_idx, channel) & ")";
    constant C_PROC_CALL : string := C_PROC_NAME & "(" & to_string(VVCT, vvc_instance_idx) & ")";
    variable v_msg_id_panel : t_msg_id_panel := shared_msg_id_panel;
  begin
  -- Create command by setting common global 'VVCT' signal record and dedicated VVC 'shared_vvc_cmd' record
  -- locking semaphore in set_general_target_and_command_fields to gain exclusive right to VVCT and shared_vvc_cmd
  -- semaphore gets unlocked in await_cmd_from_sequencer of the targeted VVC
    set_general_target_and_command_fields(VVCT, vvc_instance_idx, RX, C_PROC_CALL, msg, QUEUED, READ);
    shared_vvc_cmd.alert_level         := alert_level;
    shared_vvc_cmd.data_routing        := data_routing;
    shared_vvc_cmd.parent_msg_id_panel := parent_msg_id_panel;
    if parent_msg_id_panel /= C_UNUSED_MSG_ID_PANEL then
      v_msg_id_panel := parent_msg_id_panel;
    end if;
    send_command_to_vvc(VVCT, std.env.resolution_limit, scope, v_msg_id_panel);
  end procedure;

  --==========================================================================================
  -- Transaction info methods
  --==========================================================================================
  procedure set_global_vvc_transaction_info (
    signal   vvc_transaction_info_trigger : inout std_logic;
    variable vvc_transaction_info_group   : inout t_transaction_group;
    constant vvc_cmd                      : in t_vvc_cmd_record;
    constant vvc_config                   : in t_vvc_config;
    constant transaction_status           : in t_transaction_status;
    constant scope                        : in string := C_VVC_CMD_SCOPE_DEFAULT
  ) is
  begin
  -- <USER_INPUT> Please insert the VVC operations here with the appropriate fields.
  --  case vvc_cmd.operation is
  --    when WRITE | READ =>
  --      vvc_transaction_info_group.bt.operation          := vvc_cmd.operation;
  --      vvc_transaction_info_group.bt.address            := vvc_cmd.addr;
  --      vvc_transaction_info_group.bt.data               := vvc_cmd.data;
  --      vvc_transaction_info_group.bt.vvc_meta.msg       := vvc_cmd.msg;
  --      vvc_transaction_info_group.bt.vvc_meta.cmd_idx   := vvc_cmd.cmd_idx;
  --      vvc_transaction_info_group.bt.transaction_status := transaction_status;
  --      gen_pulse(vvc_transaction_info_trigger, 0 ns, "pulsing global vvc transaction info trigger", scope, ID_NEVER);

  --    when others =>
  --      alert(TB_ERROR, "VVC operation not recognized", scope);
  --  end case;

    wait for 0 ns;
  end procedure set_global_vvc_transaction_info;

  procedure set_global_vvc_transaction_info (
    signal   vvc_transaction_info_trigger : inout std_logic;
    variable vvc_transaction_info_group   : inout t_transaction_group;
    constant vvc_cmd                      : in t_vvc_cmd_record;
    constant vvc_result                   : in t_vvc_result;
    constant transaction_status           : in t_transaction_status;
    constant scope                        : in string := C_VVC_CMD_SCOPE_DEFAULT
  ) is
  begin
  -- <USER_INPUT> Please insert the VVC operations here with the appropriate fields.
  --  case vvc_cmd.operation is
  --    when READ =>
  --      vvc_transaction_info_group.bt.data               := vvc_result;
  --      vvc_transaction_info_group.bt.transaction_status := transaction_status;
  --      gen_pulse(vvc_transaction_info_trigger, 0 ns, "pulsing global vvc transaction info trigger", scope, ID_NEVER);

  --    when others =>
  --      alert(TB_ERROR, "VVC operation does not update vvc_result ", scope);
  --  end case;

    wait for 0 ns;
  end procedure set_global_vvc_transaction_info;

  procedure reset_vvc_transaction_info (
    variable vvc_transaction_info_group  : inout t_transaction_group;
    constant vvc_cmd                     : in t_vvc_cmd_record
  ) is
  begin
  -- <USER_INPUT> Please insert the VVC operations here.
  --  case vvc_cmd.operation is
  --    when WRITE | READ =>
  --      vvc_transaction_info_group.bt := C_BASE_TRANSACTION_SET_DEFAULT;

  --    when others =>
  --      null;
  --  end case;

    wait for 0 ns;
  end procedure reset_vvc_transaction_info;

end package body vvc_methods_pkg;
