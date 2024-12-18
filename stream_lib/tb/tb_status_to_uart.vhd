
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;

library stream_lib;
use stream_lib.status_pkg.all;

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

    signal pause_vld : std_logic := '0';
    signal valid_probability : integer range 0 to 100 := 100;
     
    constant input_status_fifo_idx : integer := 0;
    constant output_uart_fifo_idx : integer := 1;

    constant buffer_size_bits : integer := 512;

begin

    clock_generator(clk, 8 ns);


    p_main : process

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
            uvvm_fifo_put(output_uart_fifo_idx, x"53");
            uvvm_fifo_put(output_uart_fifo_idx, x"48");
            uvvm_fifo_put(output_uart_fifo_idx, x"41");
            -- Generate random data to send and receive
            status_data : for i in 0 to status_words-1 loop 
                status_word := random(8);
                sof := '1' when i = 0 else '0';
                eof := '1' when i = status_words-1 else '0';
                uvvm_fifo_put(input_status_fifo_idx, sof & eof & status_word);
                uvvm_fifo_put(output_uart_fifo_idx, status_word);
            end loop; -- status_data 
            
            -- Generate tail data
            uvvm_fifo_put(output_uart_fifo_idx, x"0A0D534841");

        end procedure pd_gen_testdata;
        
    begin
        log("Start simulation");
        gen_pulse(rst, clk, 10, "Rst signal");
        uvvm_fifo_init(input_status_fifo_idx, buffer_size_bits-1);
        uvvm_fifo_init(output_uart_fifo_idx, buffer_size_bits-1);
        unblock_flag("init_fifos", "fifos initialized", global_trigger);
        
        log("check defaults");
        check_value(status_rdy, '0', "check default status_rdy");
        check_value(uart_data_vld, '0', "check default uart_data_vld");

        pd_gen_testdata(VOID);
        
        wait for 1 us; 
        valid_probability <= 10;
        pd_gen_testdata(VOID);
        
        wait for 2 us;
        
        check_value(uvvm_fifo_get_count(input_status_fifo_idx), 0, "Check all data sent");
        check_value(uvvm_fifo_get_count(output_uart_fifo_idx), 0, "Check all data received");

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;



    p_send_status_data : process
        variable status_data : std_logic_vector(9 downto 0);
    begin
        await_unblock_flag("init_fifos", 100 ns, "waiting for init_fifos flag");
        -- wait for data in fifo
        wait_data_loop : while uvvm_fifo_get_count(input_status_fifo_idx) = 0 loop
            wait until falling_edge(clk);
        end loop wait_data_loop;

        -- output data
        status_data := uvvm_fifo_get(input_status_fifo_idx, status_data'length);
        status.tag <= SOF when status_data(9) = '1' else EOF when status_data(8) = '1' else DATA;
        status.data <= status_data(7 downto 0);
        status_vld <= '1';
        
        output_data_loop : while uvvm_fifo_get_count(input_status_fifo_idx) /= 0 loop
            if status_rdy = '1' then
                status_data := uvvm_fifo_get(input_status_fifo_idx, status_data'length);
                status.tag <= SOF when status_data(9) = '1' else EOF when status_data(8) = '1' else DATA;
                status.data <= status_data(7 downto 0);
                status_vld <= '1';
            end if;
            wait until falling_edge(clk);
        end loop output_data_loop;
       
        if status_rdy = '0' then
            wait until status_rdy = '1';
        end if;

        status_vld <= '0';

    end process p_send_status_data;
    
    p_receive_data : process
        variable verify_data : std_logic_vector(7 downto 0);
    begin
        await_unblock_flag("init_fifos", 100 ns, "waiting for init_fifos flag");
              
        get_data_looop: while true loop
            wait until falling_edge(clk);
            if uart_data_vld = '1' and uart_data_rdy = '1' then
                verify_data := uvvm_fifo_get(output_uart_fifo_idx, verify_data'length);
                log("data was: " & to_hstring(uart_data) & " data should be: " & to_hstring(verify_data));
                check_value(uart_data, verify_data, "Check uart_data");
            end if;
        end loop;

    end process;

    p_pause_pattern : process
        variable v_percent : integer range 0 to 100;
    begin
        wait until rising_edge(clk);
        v_percent := random(0, 100);
        pause_vld <= '0'; 
        if v_percent < valid_probability then
            pause_vld <= '1';
        end if;
    end process;

    uart_data_rdy <= uart_data_vld and pause_vld;

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

end architecture;