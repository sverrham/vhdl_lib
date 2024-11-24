

--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;

entity tb_arp_echo is
end entity;


architecture behavioral of tb_arp_echo is
    
    signal clk : std_logic;
    signal empty: std_logic := '1';
    signal rd_en : std_logic;
    signal data_i : std_logic_vector(7 downto 0);
    signal uart_busy : std_logic := '0';
    signal uart_en : std_logic;
    signal uart_data : std_logic_vector(7 downto 0);


    constant gen_data_fifo_idx : integer := 0;
    constant buffer_size_bits : integer := 512;

    constant clk_period : time := 12.5 ns;

    constant ether_type_arp : std_logic_vector(15 downto 0) := x"0806";

begin

    clock_generator(clk, clk_period);


    i_ethertype_decode : entity work.arp_echo
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
        wait until rising_edge(clk);
        data_i <= uvvm_fifo_get(gen_data_fifo_idx, data_i'length);
        empty <= '0';

        while uvvm_fifo_get_count(gen_data_fifo_idx) /= 0 loop
            if rd_en = '1' then
                data_i <= uvvm_fifo_get(gen_data_fifo_idx, data_i'length);
            end if;
            wait until rising_edge(clk);
        end loop;

    end process;


    p_main : process
        procedure pd_gen_data (constant fifo_idx : integer;
                               constant receiver_fifo_idx : integer;
                               constant ether_type : std_logic_vector(15 downto 0)) is

            variable length : integer;
            variable header : integer := 14; -- bytes in header
            variable random_data : std_logic_vector(7 downto 0);
        begin
            log("procedure");
            length := random(20, 30);
            -- packet size
            -- uvvm_fifo_put(fifo_idx, x"00"); -- This is a bit strange but its what comes out of the mac. one extra for length it should be only two bytes.
            uvvm_fifo_put(fifo_idx, x"00");
            uvvm_fifo_put(fifo_idx, std_logic_vector(to_unsigned(length, 8)));
            -- mac
            for i in 0 to 11 loop
                uvvm_fifo_put(fifo_idx, std_logic_vector(to_unsigned(i, 8)));
                uvvm_fifo_put(receiver_fifo_idx, std_logic_vector(to_unsigned(i, 8)));
            end loop;

           -- ether type 
            uvvm_fifo_put(fifo_idx, ether_type(15 downto 8));
            uvvm_fifo_put(receiver_fifo_idx, ether_type(15 downto 8));
            uvvm_fifo_put(fifo_idx, ether_type(7 downto 0));
            uvvm_fifo_put(receiver_fifo_idx, ether_type(7 downto 0));

            -- Data
            for i in 0 to length-header loop
                random_data := random(random_data'length);
                uvvm_fifo_put(fifo_idx, random_data);
                uvvm_fifo_put(receiver_fifo_idx, random_data);
            end loop;

            -- end packet
            -- uvvm_fifo_put(fifo_idx, x"0A");
            uvvm_fifo_put(receiver_fifo_idx, x"0A");

            if ether_type /= ether_type_arp then
                -- Only arp packets should be sent from module
                uvvm_fifo_flush(receiver_fifo_idx);
            end if;
        end procedure;

        procedure pd_check_receive(constant receiver_fifo_idx : integer;
                                   constant sender_fifo_idx : integer) is

        begin
            log("Waiting for dataQ");
            -- if receiver fifo empty we expect no data. verify uart_en is low 
            if uvvm_fifo_get_count(receiver_fifo_idx) = 0 then
                while uvvm_fifo_get_count(sender_fifo_idx) /= 0 loop
                    check_value(uart_en, '0', "uart_en low");
                    wait until rising_edge(clk);
                end loop;
            else

                while uvvm_fifo_get_count(receiver_fifo_idx) /= 0 loop
                    await_value(uart_en, '1', 0 ns, 1 us, "uart en");
                    check_value(uart_data, uvvm_fifo_get(receiver_fifo_idx, uart_data'length), "uart data check");
                    wait for clk_period * 1.5; -- atleast wait 1.5 clk cycle so uart_en can go low again.
                end loop;

            end if;
        end procedure;

        variable v_rec_fifo_index : integer;
    begin
        log("Starting simulation");
        uvvm_fifo_init(gen_data_fifo_idx, buffer_size_bits-1);
        v_rec_fifo_index := uvvm_fifo_init(buffer_size_bits-1);
        
        -- Generate data arp packet, non blocking
        pd_gen_data(gen_data_fifo_idx, v_rec_fifo_index, ether_type_arp);
        -- Wait and check for received data. Blocking
        pd_check_receive(v_rec_fifo_index, gen_data_fifo_idx);

        -- Generate data not arp packet, non blocking
        pd_gen_data(gen_data_fifo_idx, v_rec_fifo_index, x"0800"); --ip v4 packet
        -- Wait and check for received data. Blocking
        pd_check_receive(v_rec_fifo_index, gen_data_fifo_idx);


        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;


end architecture;