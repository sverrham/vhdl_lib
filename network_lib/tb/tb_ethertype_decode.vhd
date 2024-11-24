
--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;



entity tb_ethertype_decode is
end entity;


architecture behavioral of tb_ethertype_decode is
    
    signal clk : std_logic;
    signal empty: std_logic := '1';
    signal rd_en : std_logic;
    signal data_i : std_logic_vector(7 downto 0);
    signal uart_busy : std_logic := '0';
    signal uart_en : std_logic;
    signal uart_data : std_logic_vector(7 downto 0);

begin

    clock_generator(clk, 12.5 ns);


    i_ethertype_decode : entity work.ethertype_decode 
        port map(
            clk_i       => clk,
            empty_i     => empty,
            rd_en_o     => rd_en,
            data_i      => data_i,
            uart_busy_i => uart_busy,
            uart_en_o   => uart_en,
            uart_data_o => uart_data
        );


    p_data : process
    begin
        --generate data 
        empty <= '1';
        wait for 500 ns;
        wait until rising_edge(clk);
        -- Packet size, first two words
        empty <= '0';
        data_i <= X"00";
 
        await_value(rd_en, '1', 0 ns, 200 ns, "packet size high");
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        data_i <= X"0A";
        await_value(rd_en, '1', 0 ns, 200 ns, "packet size low");
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        for i in 0 to 11 loop
            data_i <= std_logic_vector(to_unsigned(i,8));
            await_value(rd_en, '1', 0 ns, 200 ns, "mac");
            wait until rising_edge(clk);
            wait until rising_edge(clk);
        end loop;
        data_i <= X"AB";
        await_value(rd_en, '1', 0 ns, 200 ns, "ether type low");
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        data_i <= X"CD";
        await_value(rd_en, '1', 0 ns, 200 ns, "ether type high");


    end process;


    p_main : process
    begin
        log("Starting simulation");
        uart_busy <= '0';

        await_value(uart_en, '1', 0 ns, 1 us, "Packet size high" );
        uart_busy <= '1';
        check_value(uart_data, x"00", "uart data packet size high");
        
        wait for 100 ns;
        wait until rising_edge(clk);
        uart_busy <= '0';
 
       await_value(uart_en, '1', 0 ns, 1 us, "Packet size low" );
        uart_busy <= '1';
        check_value(uart_data, x"0A", "uart data packet size low");
        
        wait for 100 ns;
        wait until rising_edge(clk);
        uart_busy <= '0';
 
        -- should receive the mac address
        for i in 0 to 11 loop          
            await_value(uart_en, '1', 0 ns, 1 us, "uart mac data en" );
            uart_busy <= '1';
            check_value(uart_data, std_logic_vector(to_unsigned(i, 8)),"uart mac data");
            
            wait for 100 ns;
            wait until rising_edge(clk);
            uart_busy <= '0';
        end loop;

        await_value(uart_en, '1', 0 ns, 1 us, "uart en ether type" );
        uart_busy <= '1';
        check_value(uart_data, x"AB", "ether type low");
        
        wait for 100 ns;
        wait until rising_edge(clk);
        uart_busy <= '0';
        
        await_value(uart_en, '1', 0 ns, 1 us, "uart en ether type" );
        check_value(uart_data, x"CD", "ether type high");

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;


end architecture;