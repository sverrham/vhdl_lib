
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;

library stream_lib;
use stream_lib.status_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;

library olo_lib;
use olo_lib.olo_base_pkg_array.all;

entity tb_status_mux is
end entity;

architecture rtl of tb_status_mux is

  constant STATUS_MUX_SOURCES : integer := 2;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal status_in_vld : std_logic_vector(STATUS_MUX_SOURCES-1 downto 0) := (others => '0');
  signal status_in_rdy : std_logic_vector(STATUS_MUX_SOURCES-1 downto 0);
  signal status_in : t_status_array(STATUS_MUX_SOURCES-1 downto 0);

  signal status_in_slv : StlvArray10_t(0 to STATUS_MUX_SOURCES-1);

  signal status_out_vld : std_logic;
  signal status_out_rdy : std_logic;
  signal status_out : t_status;

  constant STATUS_OUTPUT_VVC_IDX : integer := 1;
  constant STATUS_INPUT_VVC_IDX : integer := 2;

begin

  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  clock_generator(clk, 8 ns);

  p_main : process 

    procedure send_expect_receive(constant input : integer; constant status: t_status; constant msg : string) is
    begin
        vld_rdy_write(VLD_RDY_VVCT, STATUS_INPUT_VVC_IDX+input, status_to_slv(status=>status), msg);
        VLD_RDY_VVC_SB.add_expected(X"0000_000" & "00" & status_to_slv(status=>status), msg);
        vld_rdy_receive(VLD_RDY_VVCT, STATUS_OUTPUT_VVC_IDX, msg, TO_SB);
    end procedure send_expect_receive;

    procedure generate_random_testdata(constant input : integer) is
      variable length : integer;
    begin
      length := random(10, 20);
      send_expect_receive(input => input, status => (tag=>SOF, data=>random(8)), msg => "SOF");
      for i in 0 to length-1 loop
        send_expect_receive(input => input, status => (tag=>DATA, data=>random(8)), msg => "DATA");
      end loop;
      send_expect_receive(input => input, status => (tag=>EOF, data=>random(8)), msg => "EOF");
    end procedure generate_random_testdata;

    type RealArray is array (natural range <>) of real;
    -- constant pause_pattern_array : RealArray := (0.0, 0.2);
    constant pause_pattern_array : RealArray := (0.0, 0.2, 0.4, 0.6, 0.8, 0.9);
  begin
    await_uvvm_initialization(VOID);
    
    log("Start simulation");
    gen_pulse(rst, clk, 10, "Rst signal");

    -- Send some data, expect some data
    send_expect_receive(input => 0, status => (tag=>SOF, data=>x"55"), msg => "SOF");
    send_expect_receive(input => 0, status => (tag=>DATA, data=>x"AA"), msg => "DATA");
    send_expect_receive(input => 0, status => (tag=>EOF, data=>x"FE"), msg => "EOF");
    await_completion(ALL_VVCS, 1 ms, "wait for completion");
    
    shared_vld_rdy_vvc_config(RX, STATUS_OUTPUT_VVC_IDX).bfm_config.pause_probability := 0.00;
    shared_vld_rdy_vvc_config(TX, STATUS_INPUT_VVC_IDX).bfm_config.pause_probability := 0.50;
    generate_random_testdata(0);
    await_completion(ALL_VVCS, 1 ms, "wait for completion");

    shared_vld_rdy_vvc_config(RX, STATUS_OUTPUT_VVC_IDX).bfm_config.pause_probability := 0.50;
    shared_vld_rdy_vvc_config(TX, STATUS_INPUT_VVC_IDX).bfm_config.pause_probability := 0.00;
    generate_random_testdata(0);
    await_completion(ALL_VVCS, 1 ms, "wait for completion");
    
    shared_vld_rdy_vvc_config(RX, STATUS_OUTPUT_VVC_IDX).bfm_config.pause_probability := 0.50;
    shared_vld_rdy_vvc_config(TX, STATUS_INPUT_VVC_IDX).bfm_config.pause_probability := 0.50;
    generate_random_testdata(1);
    await_completion(ALL_VVCS, 1 ms, "wait for completion");
    
    shared_vld_rdy_vvc_config(RX, STATUS_OUTPUT_VVC_IDX).bfm_config.pause_probability := 0.00;
    shared_vld_rdy_vvc_config(TX, STATUS_INPUT_VVC_IDX).bfm_config.pause_probability := 0.00;
    generate_random_testdata(0);
    generate_random_testdata(1);
    await_completion(ALL_VVCS, 1 ms, "wait for completion");
     
   
    -- for i in pause_pattern_array'range loop
    --   log("Pause probability: " & real'image(pause_pattern_array(i)));
    --   shared_vld_rdy_vvc_config(RX, STATUS_OUTPUT_VVC_IDX).bfm_config.pause_probability := pause_pattern_array(i);
    --   shared_vld_rdy_vvc_config(TX, STATUS_INPUT_VVC_IDX).bfm_config.pause_probability := pause_pattern_array(i);
    --   generate_random_testdata(0);
    --   generate_random_testdata(1);
    --   await_completion(ALL_VVCS, 1 ms, "wait for completion");
    -- end loop;

    await_uvvm_completion(1 ns);
    report_alert_counters(FINAL);
    std.env.stop;
  end process;


  p_dut : entity stream_lib.status_mux
    generic map (
      STATUS_MUX_SOURCES => STATUS_MUX_SOURCES
    )
    port map (
      clk => clk,
      rst => rst,
      status_in_vld => status_in_vld,
      status_in_rdy => status_in_rdy,
      status_in => status_in,
      status_out_vld => status_out_vld,
      status_out_rdy => status_out_rdy,
      status_out => status_out
    );

  gen_vvcs : for i in 0 to STATUS_MUX_SOURCES-1 generate
    i_vvc_input : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
      GC_DATA_WIDTH => 10,
      GC_INSTANCE_IDX => STATUS_INPUT_VVC_IDX + i
    )
    port map (
      tx_data => status_in_slv(i),
      tx_data_vld => status_in_vld(i),
      tx_data_rdy => status_in_rdy(i),
      rx_data => X"00" & "00",
      rx_data_vld => '0',
      rx_data_rdy => open,
      clk => clk
    );
    status_in(i) <= slv_to_status(status_in_slv(i));
  end generate;

    i_vvc_output : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
      GC_DATA_WIDTH => 10,
      GC_INSTANCE_IDX => STATUS_OUTPUT_VVC_IDX
      )
    port map (
      tx_data => open,
      tx_data_vld => open,
      tx_data_rdy => '0',
      rx_data => status_to_slv(status_out),
      rx_data_vld => status_out_vld,
      rx_data_rdy => status_out_rdy,
      clk => clk
    );

end architecture;