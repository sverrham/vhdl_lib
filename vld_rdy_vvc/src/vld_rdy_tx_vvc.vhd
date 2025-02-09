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
use work.vvc_methods_pkg.all;
use work.vvc_cmd_pkg.all;
use work.td_target_support_pkg.all;
use work.td_vvc_entity_support_pkg.all;
use work.td_cmd_queue_pkg.all;
use work.td_result_queue_pkg.all;
use work.transaction_pkg.all;
use work.vvc_sb_support_pkg.all;

--==========================================================================================
--==========================================================================================
entity vld_rdy_tx_vvc is
  generic (
    --<USER_INPUT> Insert interface specific generic constants here
    -- Example: 
    -- GC_ADDR_WIDTH                            : integer range 1 to C_VVC_CMD_ADDR_MAX_LENGTH;
    GC_DATA_WIDTH                            : integer range 1 to C_VVC_CMD_DATA_MAX_LENGTH;
    GC_INSTANCE_IDX                          : natural;
    GC_CHANNEL                               : t_channel;
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
    tx_data : out std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    tx_data_vld : out std_logic := '0';
    tx_data_rdy : in std_logic;
    -- VVC control signals: 
    -- rst                         : in std_logic; -- Optional VVC Reset
    clk                         : in std_logic
  );
end entity vld_rdy_tx_vvc;

--==========================================================================================
--==========================================================================================
architecture behave of vld_rdy_tx_vvc is

  constant C_SCOPE      : string       := get_scope_for_log(C_VVC_NAME, GC_INSTANCE_IDX, GC_CHANNEL);
  constant C_VVC_LABELS : t_vvc_labels := assign_vvc_labels(C_SCOPE, C_VVC_NAME, GC_INSTANCE_IDX, GC_CHANNEL);

  signal executor_is_busy       : boolean := false;
  signal queue_is_increasing    : boolean := false;
  signal last_cmd_idx_executed  : natural := 0;
  signal terminate_current_cmd  : t_flag_record;
  --<USER_INPUT> Uncomment if the VVC has a valid signal, e.g. tvalid in AXI-Stream
  -- signal clock_period           : time;

  -- Instantiation of the element dedicated executor
  shared variable command_queue : work.td_cmd_queue_pkg.t_generic_queue;
  shared variable result_queue  : work.td_result_queue_pkg.t_generic_queue;

  alias vvc_config : t_vvc_config is shared_vld_rdy_vvc_config(GC_CHANNEL, GC_INSTANCE_IDX);
  alias vvc_status : t_vvc_status is shared_vld_rdy_vvc_status(GC_CHANNEL, GC_INSTANCE_IDX);
  -- Transaction info
  alias vvc_transaction_info_trigger        : std_logic           is global_vld_rdy_vvc_transaction_trigger(GC_CHANNEL, GC_INSTANCE_IDX);
  alias vvc_transaction_info                : t_transaction_group is shared_vld_rdy_vvc_transaction_info(GC_CHANNEL, GC_INSTANCE_IDX);
  -- VVC Activity
  signal entry_num_in_vvc_activity_register : integer;

begin

  assert GC_CHANNEL = TX report "GC_CHANNEL must be set accordingly to the VVC, i.e. TX" severity failure;

  --==========================================================================================
  -- Constructor
  -- - Set up the defaults and show constructor if enabled
  --==========================================================================================
  work.td_vvc_entity_support_pkg.vvc_constructor(C_SCOPE, GC_INSTANCE_IDX, vvc_config, command_queue, result_queue, GC_VLD_RDY_BFM_CONFIG,
                  GC_CMD_QUEUE_COUNT_MAX, GC_CMD_QUEUE_COUNT_THRESHOLD, GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY,
                  GC_RESULT_QUEUE_COUNT_MAX, GC_RESULT_QUEUE_COUNT_THRESHOLD, GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY,
                  C_VVC_MAX_INSTANCE_NUM);
  --==========================================================================================


  --==========================================================================================
  -- Command interpreter
  -- - Interpret, decode and acknowledge commands from the central sequencer
  --==========================================================================================
  cmd_interpreter : process is
    variable v_cmd_has_been_acked : boolean; -- Indicates if acknowledge_cmd() has been called for the current shared_vvc_cmd
    variable v_local_vvc_cmd      : t_vvc_cmd_record := C_VVC_CMD_DEFAULT;
    variable v_msg_id_panel       : t_msg_id_panel;
  begin

    -- 0. Initialize the process prior to first command
    work.td_vvc_entity_support_pkg.initialize_interpreter(terminate_current_cmd, global_awaiting_completion);
    -- initialise shared_vvc_last_received_cmd_idx for channel and instance
    shared_vvc_last_received_cmd_idx(GC_CHANNEL, GC_INSTANCE_IDX) := 0;

    -- Register VVC in vvc activity register
    entry_num_in_vvc_activity_register <= shared_vvc_activity_register.priv_register_vvc(name     => C_VVC_NAME,
                                                                                         channel  => GC_CHANNEL,
                                                                                         instance => GC_INSTANCE_IDX);
    -- Set initial value of v_msg_id_panel to msg_id_panel in config
    v_msg_id_panel := vvc_config.msg_id_panel;

    -- Then for every single command from the sequencer
    loop  -- basically as long as new commands are received

      -- 1. wait until command targeted at this VVC. Must match VVC name, instance and channel (if applicable)
      --    releases global semaphore
      -------------------------------------------------------------------------
      work.td_vvc_entity_support_pkg.await_cmd_from_sequencer(C_VVC_LABELS, vvc_config, THIS_VVCT, VVC_BROADCAST, global_vvc_busy, global_vvc_ack, v_local_vvc_cmd);
      v_cmd_has_been_acked := false; -- Clear flag
      -- Update shared_vvc_last_received_cmd_idx with received command index
      shared_vvc_last_received_cmd_idx(GC_CHANNEL, GC_INSTANCE_IDX) := v_local_vvc_cmd.cmd_idx;
      -- Select between a provided msg_id_panel via the vvc_cmd_record from a VVC with a higher hierarchy or the
      -- msg_id_panel in this VVC's config. This is to correctly handle the logging when using Hierarchical-VVCs.
      v_msg_id_panel := get_msg_id_panel(v_local_vvc_cmd, vvc_config);

      -- 2a. Put command on the executor if intended for the executor
      -------------------------------------------------------------------------
      if v_local_vvc_cmd.command_type = QUEUED then
        work.td_vvc_entity_support_pkg.put_command_on_queue(v_local_vvc_cmd, command_queue, vvc_status, queue_is_increasing);

      -- 2b. Otherwise command is intended for immediate response
      -------------------------------------------------------------------------
      elsif v_local_vvc_cmd.command_type = IMMEDIATE then
        case v_local_vvc_cmd.operation is

          when DISABLE_LOG_MSG =>
            uvvm_util.methods_pkg.disable_log_msg(v_local_vvc_cmd.msg_id, vvc_config.msg_id_panel, to_string(v_local_vvc_cmd.msg) & format_command_idx(v_local_vvc_cmd), C_SCOPE, v_local_vvc_cmd.quietness);

          when ENABLE_LOG_MSG =>
            uvvm_util.methods_pkg.enable_log_msg(v_local_vvc_cmd.msg_id, vvc_config.msg_id_panel, to_string(v_local_vvc_cmd.msg) & format_command_idx(v_local_vvc_cmd), C_SCOPE, v_local_vvc_cmd.quietness);

          when FLUSH_COMMAND_QUEUE =>
            work.td_vvc_entity_support_pkg.interpreter_flush_command_queue(v_local_vvc_cmd, command_queue, vvc_config, vvc_status, C_VVC_LABELS);

          when TERMINATE_CURRENT_COMMAND =>
            work.td_vvc_entity_support_pkg.interpreter_terminate_current_command(v_local_vvc_cmd, vvc_config, C_VVC_LABELS, terminate_current_cmd, executor_is_busy);

          when FETCH_RESULT =>
            work.td_vvc_entity_support_pkg.interpreter_fetch_result(result_queue, entry_num_in_vvc_activity_register, v_local_vvc_cmd, vvc_config, C_VVC_LABELS, shared_vvc_response);

          when others =>
            tb_error("Unsupported command received for IMMEDIATE execution: '" & to_string(v_local_vvc_cmd.operation) & "'", C_SCOPE);

        end case;

      else
        tb_error("command_type is not IMMEDIATE or QUEUED", C_SCOPE);
      end if;

      -- 3. Acknowledge command after running or queuing the command
      -------------------------------------------------------------------------
      if not v_cmd_has_been_acked then
        work.td_target_support_pkg.acknowledge_cmd(global_vvc_ack, v_local_vvc_cmd.cmd_idx);
      end if;

    end loop;
    wait;
  end process cmd_interpreter;
  --==========================================================================================


  --==========================================================================================
  -- Command executor
  -- - Fetch and execute the commands
  --==========================================================================================
  cmd_executor : process is
    constant C_EXECUTOR_ID                            : natural := 0;
    variable v_cmd                                    : t_vvc_cmd_record;
    -- variable v_result                              : t_vvc_result; -- See vvc_cmd_pkg
    variable v_timestamp_start_of_current_bfm_access  : time    := 0 ns;
    variable v_timestamp_start_of_last_bfm_access     : time    := 0 ns;
    variable v_timestamp_end_of_last_bfm_access       : time    := 0 ns;
    variable v_command_is_bfm_access                  : boolean := false;
    variable v_prev_command_was_bfm_access            : boolean := false;
    variable v_msg_id_panel                           : t_msg_id_panel;
    -- variable v_normalised_addr    : unsigned(GC_ADDR_WIDTH-1 downto 0) := (others => '0');
    variable v_normalised_data    : std_logic_vector(GC_DATA_WIDTH-1 downto 0) := (others => '0');

  begin

    -- 0. Initialize the process prior to first command
    -------------------------------------------------------------------------
    work.td_vvc_entity_support_pkg.initialize_executor(terminate_current_cmd);

    -- Set initial value of v_msg_id_panel to msg_id_panel in config
    v_msg_id_panel := vvc_config.msg_id_panel;

    loop

      -- update vvc activity
      update_vvc_activity_register(global_trigger_vvc_activity_register, vvc_status, INACTIVE, entry_num_in_vvc_activity_register, C_EXECUTOR_ID, last_cmd_idx_executed, command_queue.is_empty(VOID), C_SCOPE);

      -- 1. Set defaults, fetch command and log
      -------------------------------------------------------------------------
      work.td_vvc_entity_support_pkg.fetch_command_and_prepare_executor(v_cmd, command_queue, vvc_config, vvc_status, queue_is_increasing, executor_is_busy, C_VVC_LABELS);

      -- update vvc activity
      update_vvc_activity_register(global_trigger_vvc_activity_register, vvc_status, ACTIVE, entry_num_in_vvc_activity_register, C_EXECUTOR_ID, last_cmd_idx_executed, command_queue.is_empty(VOID), C_SCOPE);

      -- Select between a provided msg_id_panel via the vvc_cmd_record from a VVC with a higher hierarchy or the
      -- msg_id_panel in this VVC's config. This is to correctly handle the logging when using Hierarchical-VVCs.
      v_msg_id_panel := get_msg_id_panel(v_cmd, vvc_config);

      -- Check if command is a BFM access
      v_prev_command_was_bfm_access := v_command_is_bfm_access; -- save for inter_bfm_delay
      --<USER_INPUT> Replace this if statement with a check of the current v_cmd.operation, in order to set v_cmd_is_bfm_access to true if this is a BFM access command
      -- Example:
      -- if v_cmd.operation = WRITE or v_cmd.operation = READ or v_cmd.operation = CHECK or v_cmd.operation = POLL_UNTIL then 
      if true then  -- Replace this line with actual check
        v_command_is_bfm_access := true;
      else
        v_command_is_bfm_access := false;
      end if;

      -- Insert delay if needed
      work.td_vvc_entity_support_pkg.insert_inter_bfm_delay_if_requested(vvc_config                         => vvc_config,
                                                                         command_is_bfm_access              => v_prev_command_was_bfm_access,
                                                                         timestamp_start_of_last_bfm_access => v_timestamp_start_of_last_bfm_access,
                                                                         timestamp_end_of_last_bfm_access   => v_timestamp_end_of_last_bfm_access,
                                                                         scope                              => C_SCOPE,
                                                                         msg_id_panel                       => v_msg_id_panel);

      if v_command_is_bfm_access then
        v_timestamp_start_of_current_bfm_access := now;
      end if;

      -- 2. Execute the fetched command
      -------------------------------------------------------------------------
      case v_cmd.operation is  -- Only operations in the dedicated record are relevant

        -- VVC dedicated operations
        --===================================

        --<USER_INPUT>: Insert BFM procedure calls here
        -- Example:
          when WRITE =>
        --     -- Set vvc transaction info
            set_global_vvc_transaction_info(vvc_transaction_info_trigger, vvc_transaction_info, v_cmd, vvc_config, IN_PROGRESS, C_SCOPE);

        --     v_normalised_addr := normalize_and_check(v_cmd.addr, v_normalised_addr, ALLOW_WIDER_NARROWER, "addr", "shared_vvc_cmd.addr", "vld_rdy_write() called with too wide address. " & v_cmd.msg);
            v_normalised_data := normalize_and_check(v_cmd.data, v_normalised_data, ALLOW_WIDER_NARROWER, "data", "shared_vvc_cmd.data", "vld_rdy_write() called with too wide data. " & v_cmd.msg);
        --     -- Call the corresponding procedure in the BFM package.
        --     vld_rdy_write(addr_value    => v_normalised_addr,
        --               data_value    => v_normalised_data,
        --               msg           => format_msg(v_cmd),
        --               clk           => clk,
        --               vld_rdy_if        => vld_rdy_vvc_if,
        --               scope         => C_SCOPE,
        --               msg_id_panel  => v_msg_id_panel,
        --               config        => vvc_config.bfm_config);
              vld_rdy_write(tx_data => tx_data, 
                            tx_Data_vld => tx_data_vld, 
                            tx_data_rdy => tx_data_rdy, 
                            clk => clk, 
                            data => v_normalised_data, 
                            config => vvc_config.bfm_config);

        --     -- Update vvc transaction info
        --     set_global_vvc_transaction_info(vvc_transaction_info_trigger, vvc_transaction_info, v_cmd, vvc_config, COMPLETED, C_SCOPE);

        --  -- If the result from the BFM call is to be stored, e.g. in a read call, use the additional procedure illustrated in this read example
        --   when READ =>
        --     -- Set vvc_transaction_info
        --     set_global_vvc_transaction_info(vvc_transaction_info_trigger, vvc_transaction_info, v_cmd, vvc_config, IN_PROGRESS, C_SCOPE);

        --     v_normalised_addr := normalize_and_check(v_cmd.addr, v_normalised_addr, ALLOW_WIDER_NARROWER, "addr", "shared_vvc_cmd.addr", "vld_rdy_write() called with too wide address. " & v_cmd.msg);
        --     -- Call the corresponding procedure in the BFM package.
        --     vld_rdy_read(addr_value    => v_normalised_addr,
        --              data_value    => v_result,
        --              msg           => format_msg(v_cmd),
        --              clk           => clk,
        --              vld_rdy_if        => vld_rdy_vvc_if,
        --              scope         => C_SCOPE,
        --              msg_id_panel  => v_msg_id_panel,
        --              config        => vvc_config.bfm_config);

        --     -- Request SB check result
        --     if v_cmd.data_routing = TO_SB then
        --       -- call SB check_received
        --       VLD_RDY_VVC_SB.check_received(GC_INSTANCE_IDX, pad_vld_rdy_sb(v_result(GC_DATA_WIDTH-1 downto 0)));
        --     else
        --       -- Store the result
        --       work.td_vvc_entity_support_pkg.store_result(result_queue => result_queue,
        --                                                   cmd_idx      => v_cmd.cmd_idx,
        --                                                   result       => v_result);
        --     end if;
        --     -- Update vvc transaction info
        --     set_global_vvc_transaction_info(vvc_transaction_info_trigger, vvc_transaction_info, v_cmd, v_result, COMPLETED, C_SCOPE);



        -- UVVM common operations
        --===================================
        when INSERT_DELAY =>
          log(ID_INSERTED_DELAY, "Running: " & to_string(v_cmd.proc_call) & " " & format_command_idx(v_cmd), C_SCOPE, v_msg_id_panel);
          if v_cmd.gen_integer_array(0) = -1 then
            -- Delay specified using time
            wait until terminate_current_cmd.is_active = '1' for v_cmd.delay;
          else
            -- Delay specified using integer
            --<USER_INPUT> Uncomment if BFM has clock_period config
            -- check_value(vvc_config.bfm_config.clock_period > -1 ns, TB_ERROR, "Check that clock_period is configured when using insert_delay().",
            --             C_SCOPE, ID_NEVER, v_msg_id_panel);
            -- wait until terminate_current_cmd.is_active = '1' for v_cmd.gen_integer_array(0) * vvc_config.bfm_config.clock_period;
          end if;

        when others =>
          tb_error("Unsupported local command received for execution: '" & to_string(v_cmd.operation) & "'", C_SCOPE);
      end case;

      if v_command_is_bfm_access then
        v_timestamp_end_of_last_bfm_access   := now;
        v_timestamp_start_of_last_bfm_access := v_timestamp_start_of_current_bfm_access;
        if ((vvc_config.inter_bfm_delay.delay_type = TIME_START2START) and
           ((now - v_timestamp_start_of_current_bfm_access) > vvc_config.inter_bfm_delay.delay_in_time)) then
          alert(vvc_config.inter_bfm_delay.inter_bfm_delay_violation_severity, "BFM access exceeded specified start-to-start inter-bfm delay, " & 
                to_string(vvc_config.inter_bfm_delay.delay_in_time) & ".", C_SCOPE);
        end if;
      end if;

      -- Reset terminate flag if any occurred
      if (terminate_current_cmd.is_active = '1') then
        log(ID_CMD_EXECUTOR, "Termination request received", C_SCOPE, v_msg_id_panel);
        uvvm_vvc_framework.ti_vvc_framework_support_pkg.reset_flag(terminate_current_cmd);
      end if;

      last_cmd_idx_executed <= v_cmd.cmd_idx;

      -- Set vvc_transaction_info back to default values
      reset_vvc_transaction_info(vvc_transaction_info, v_cmd);

    end loop;
  end process cmd_executor;
  --==========================================================================================

  --==========================================================================================
  -- Command termination handler
  -- - Handles the termination request record (sets and resets terminate flag on request)
  --==========================================================================================
  cmd_terminator : uvvm_vvc_framework.ti_vvc_framework_support_pkg.flag_handler(terminate_current_cmd);  -- flag: is_active, set, reset
  --==========================================================================================


  --==========================================================================================
  -- Clock period
  -- - Finds the clock period
  --==========================================================================================
  --<USER_INPUT> Uncomment if the VVC has a valid signal, e.g. tvalid in AXI-Stream
  -- p_clock_period : process
  -- begin
  --   wait until rising_edge(clk);
  --   clock_period <= now;
  --   wait until rising_edge(clk);
  --   clock_period <= now - clock_period;
  --   wait;
  -- end process;
  --==========================================================================================


  --==========================================================================================
  -- Unwanted activity detection
  -- - Monitors unwanted activity from the DUT
  --==========================================================================================
  p_unwanted_activity : process is
  begin
    -- Add a delay to allow the VVC to be registered in the activity register
    wait for std.env.resolution_limit;

    loop
      -- Skip if the vvc is inactive to avoid waiting for an inactive activity register
      if shared_vvc_activity_register.priv_get_vvc_activity(entry_num_in_vvc_activity_register) = ACTIVE then
        -- Wait until the vvc is inactive
        loop
          wait on global_trigger_vvc_activity_register;
          if shared_vvc_activity_register.priv_get_vvc_activity(entry_num_in_vvc_activity_register) = INACTIVE then
            exit;
          end if;
        end loop;
      end if;

      --<USER_INPUT> Insert all DUT outputs to be monitored in the 'wait on' statement below, except ready signal
      -- Note: ready signal, e.g. tready in AXI-Stream, shall not be monitored when the VVC is a master VVC
      -- Example: wait on vld_rdy_tx_vvc_if.valid, vld_rdy_tx_vvc_if.data, global_trigger_vvc_activity_register;
      wait on global_trigger_vvc_activity_register;

      -- Check the changes on the DUT outputs only when the vvc is inactive
      if shared_vvc_activity_register.priv_get_vvc_activity(entry_num_in_vvc_activity_register) = INACTIVE then
        --<USER_INPUT> Use the check_unwanted_activity() procedure defined in the VVC framework support package to check the changes on the DUT outputs
        -- Example:
        -- check_unwanted_activity(vld_rdy_tx_vvc_if.last, vvc_config.unwanted_activity_severity, "last", C_SCOPE);
        -- check_unwanted_activity(vld_rdy_tx_vvc_if.data, vvc_config.unwanted_activity_severity, "data", C_SCOPE);

        -- Note: Use the following example instead if the interface has a valid signal, e.g. tvalid in AXI-Stream
        -- Example:
        -- Skip checking the changes if the valid signal goes low within one clock period after the VVC becomes inactive
        -- if not (falling_edge(vld_rdy_tx_vvc_if.valid'event) and global_trigger_vvc_activity_register'last_event < clock_period) then
        --   check_unwanted_activity(vld_rdy_tx_vvc_if.valid, vvc_config.unwanted_activity_severity, "valid", C_SCOPE);
        --   check_unwanted_activity(vld_rdy_tx_vvc_if.data, vvc_config.unwanted_activity_severity, "data", C_SCOPE);
        -- end if;
      end if;
    end loop;
  end process p_unwanted_activity;
  --==========================================================================================

end architecture behave;
