
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library stream_lib;
use stream_lib.status_pkg.all;

library vip_vld_rdy;
context vip_vld_rdy.vvc_context;

entity tb_status_to_uart is
end tb_status_to_uart;

architecture rtl of tb_status_to_uart is
    
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal pps : std_logic := '0';
    signal status : t_status;
    signal status_vld : std_logic := '0';
    signal status_rdy : std_logic;
    signal uart_data : std_logic_vector(7 downto 0);
    signal uart_data_vld : std_logic;
    signal uart_data_rdy : std_logic := '0';

    signal tx_data : std_logic_vector(9 downto 0);

    constant UART_VVC_IDX : integer := 1;
    constant STATUS_VVC_IDX : integer := 2;


begin

    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

    clock_generator(clk, 8 ns);

    p_main : process
        procedure expect_receive(constant data : std_logic_vector; constant msg : string) is
        begin
            VLD_RDY_VVC_SB.add_expected(X"0000_0000" & data, msg);
            vld_rdy_receive(VLD_RDY_VVCT, UART_VVC_IDX, msg, TO_SB);
        end procedure expect_receive;

        -- Generate testdata to be sent into the module and also generate 
        -- the expected data coming out of the module.
        -- generate data in 0 time so this is a non blocking call.
        procedure pd_gen_testdata (constant void : t_void) is
            variable status_words : integer := 6;
            variable status_word : std_logic_vector(7 downto 0);
            variable sof : std_logic;
            variable eof : std_logic;
        begin
            -- Generate header data for output
            expect_receive(X"53", "Header");
            expect_receive(X"48", "Header");
            expect_receive(X"41", "Header");
            
            -- Generate random data to send and receive
            status_data : for i in 0 to status_words-1 loop 
                status_word := random(8);
                sof := '1' when i = 0 else '0';
                eof := '1' when i = status_words-1 else '0';
                vld_rdy_write(VLD_RDY_VVCT, STATUS_VVC_IDX, sof & eof & status_word, "Data");
                expect_receive(status_word, "Data");
            end loop; -- status_data 
            
            -- Generate tail data
            expect_receive(X"41", "Tail");
            expect_receive(X"48", "Tail");
            expect_receive(X"53", "Tail");
            expect_receive(X"0D", "Tail");
            expect_receive(X"0A", "Tail");
        end procedure pd_gen_testdata;
        
    begin
        await_uvvm_initialization(VOID);

        log("Start simulation");
        gen_pulse(rst, clk, 10, "Rst signal");
        unblock_flag("init_fifos", "fifos initialized", global_trigger);
        
        log("check defaults");
        check_value(status_rdy, '0', "check default status_rdy");
        check_value(uart_data_vld, '0', "check default uart_data_vld");

        pd_gen_testdata(VOID);
        await_completion(ALL_VVCS, 1 ms, "Wait for data done");

        wait for 1 us; 
        shared_vld_rdy_vvc_config(RX, UART_VVC_IDX).bfm_config.pause_probability := 0.5;
        pd_gen_testdata(VOID);
        await_completion(ALL_VVCS, 1 ms, "Wait for data done");
        
        
        check_value(VLD_RDY_VVC_SB.is_empty(VOID), ERROR, "SB is not empty");
        VLD_RDY_VVC_SB.report_counters(VOID);
        
        await_uvvm_completion(1 ns);
        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;

    i_status_to_uart : entity stream_lib.status_to_uart
    port map (
        clk => clk,
        rst => rst, 
        pps => pps,
        status => status,
        status_vld => status_vld,
        status_rdy => status_rdy,
        uart_data => uart_data,
        uart_data_vld => uart_data_vld,
        uart_data_rdy => uart_data_rdy
    );

    i_vld_rdy_vvc : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
        GC_DATA_WIDTH => 8,
        GC_INSTANCE_IDX => UART_VVC_IDX 
    )
    port map (
        tx_data => open,
        tx_data_vld => open,
        tx_data_rdy => '0',
        rx_data => uart_data,
        rx_data_vld => uart_data_vld,
        rx_data_rdy => uart_data_rdy,
        clk => clk
    );

    status.tag <= SOF when tx_data(9) = '1' else EOF when tx_data(8) = '1' else DATA;
    status.data <= tx_data(7 downto 0);

    i_status_vld_rdy_vvc : entity vip_vld_rdy.vld_rdy_vvc
    generic map (
        GC_DATA_WIDTH => 10,
        GC_INSTANCE_IDX => STATUS_VVC_IDX 
    )
    port map (
        tx_data => tx_data,
        tx_data_vld => status_vld,
        tx_data_rdy => status_rdy,
        rx_data => x"00" & "00",
        rx_data_vld => '0',
        rx_data_rdy => open,
        clk => clk
    );


end architecture;