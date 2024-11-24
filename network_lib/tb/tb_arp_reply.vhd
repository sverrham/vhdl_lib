

--hdlregression:tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.data_fifo_pkg.all;

entity tb_arp_reply is
end entity;


architecture behavioral of tb_arp_reply is
    
    signal clk : std_logic;
    signal rst : std_logic := '0';
    signal data_i_vld : std_logic := '1';
    signal data_i_rdy : std_logic := '1';
    signal data_i     : std_logic_vector(7 downto 0) := (others => '0');

    signal data_o_vld : std_logic := '1';
    signal data_o_rdy : std_logic := '1';
    signal data_o     : std_logic_vector(7 downto 0);

    constant gen_data_fifo_idx : integer := 0;
    constant buffer_size_bits : integer := 512;

    constant clk_period : time := 12.5 ns;

    constant ether_type_arp : std_logic_vector(15 downto 0) := x"0806";

begin

    clock_generator(clk, clk_period);


    i_arp_reply : entity work.arp_reply
        port map(
            clk_i       => clk,
            rst_i       => rst,
            vld_i       => data_i_vld,
            rdy_o       => data_i_rdy,
            data_i      => data_i,
            vld_o       => data_o_vld,
            data_o      => data_o,
            rdy_i       => data_o_rdy
            );


    p_data : process
    begin
        --generate data 
        -- TODO: actual vld/rdy module 
        data_i_vld <= '0';
        wait until falling_edge(rst);
        wait until rising_edge(clk);


        while uvvm_fifo_get_count(gen_data_fifo_idx) /= 0 loop
            if data_i_rdy = '1' or data_i_vld = '0' then
                data_i_vld <= '1';
                data_i <= uvvm_fifo_get(gen_data_fifo_idx, data_i'length);
            end if;
            wait until rising_edge(clk);
        end loop;

        wait;

    end process;


    p_main : process
        procedure pd_gen_data (constant fifo_idx : integer;
                               constant receiver_fifo_idx : integer) is

        begin
            log("procedure");
            uvvm_fifo_put(fifo_idx, x"00"); -- HTYPE
            uvvm_fifo_put(fifo_idx, x"01"); -- 
            uvvm_fifo_put(fifo_idx, x"08"); -- PTYPE
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"06"); -- HLEN
            uvvm_fifo_put(fifo_idx, x"04"); -- PLEN
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"01"); -- OPER
            uvvm_fifo_put(fifo_idx, x"58"); -- SHA (Sender hardware address)
            uvvm_fifo_put(fifo_idx, x"82"); --
            uvvm_fifo_put(fifo_idx, x"a8"); -- 
            uvvm_fifo_put(fifo_idx, x"94"); -- 
            uvvm_fifo_put(fifo_idx, x"d3"); -- 
            uvvm_fifo_put(fifo_idx, x"5e"); -- 
            uvvm_fifo_put(fifo_idx, x"c0"); -- SPA (Sender protocol address) 
            uvvm_fifo_put(fifo_idx, x"a8"); -- 
            uvvm_fifo_put(fifo_idx, x"02"); -- 
            uvvm_fifo_put(fifo_idx, x"66"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- THA (Target hardware address) 
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- 
            uvvm_fifo_put(fifo_idx, x"c0"); -- TPA Target protocol address
            uvvm_fifo_put(fifo_idx, x"a8"); -- 
            uvvm_fifo_put(fifo_idx, x"02"); -- 
            uvvm_fifo_put(fifo_idx, x"32"); -- 
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(fifo_idx, x"00"); -- Extra data

            uvvm_fifo_put(receiver_fifo_idx, x"00");
            uvvm_fifo_put(receiver_fifo_idx, x"01"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"08"); -- PTYPE
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"06"); -- HLEN
            uvvm_fifo_put(receiver_fifo_idx, x"04"); -- PLEN
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"02"); -- OPER
            uvvm_fifo_put(receiver_fifo_idx, x"BA"); -- SHA (Sender hardware address)
            uvvm_fifo_put(receiver_fifo_idx, x"AD"); --
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"02"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"01"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"c0"); -- SPA (Sender protocol address) 
            uvvm_fifo_put(receiver_fifo_idx, x"a8"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"02"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"32"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"58"); -- THA (Target hardware address) 
            uvvm_fifo_put(receiver_fifo_idx, x"82"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"a8"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"94"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"d3"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"5e"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"c0"); -- TPA Target protocol address
            uvvm_fifo_put(receiver_fifo_idx, x"a8"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"02"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"66"); -- 
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data
            uvvm_fifo_put(receiver_fifo_idx, x"00"); -- Extra data

       end procedure;

        procedure pd_check_receive(constant receiver_fifo_idx : integer;
                                   constant sender_fifo_idx : integer) is

        begin
            log("Waiting for ");
            -- if receiver fifo empty we expect no data. verify uart_en is low 
            if uvvm_fifo_get_count(receiver_fifo_idx) = 0 then
                while uvvm_fifo_get_count(sender_fifo_idx) /= 0 loop
                    wait until rising_edge(clk);
                end loop;
            else

                while uvvm_fifo_get_count(receiver_fifo_idx) /= 0 loop
                    while data_o_vld = '0'  loop
                        wait until rising_edge(clk);
                    end loop; -- <name>
                    -- await_value(data_o_vld, '1', 0 ns, 1 us, "data vld");
                    data_o_rdy <= '1';
                    check_value(data_o, uvvm_fifo_get(receiver_fifo_idx, data_o'length), "data_o check");
                    wait until rising_edge(clk);
                    data_o_rdy <= '0';
                end loop;

            end if;
        end procedure;

        variable v_rec_fifo_index : integer;
    begin
        log("Starting simulation");
        uvvm_fifo_init(gen_data_fifo_idx, buffer_size_bits-1);
        v_rec_fifo_index := uvvm_fifo_init(buffer_size_bits-1);
       
        gen_pulse(rst, clk, 10, "reset pulse");
        

        -- Generate data arp packet, non blocking
        pd_gen_data(gen_data_fifo_idx, v_rec_fifo_index);
        -- Wait and check for received data. Blocking
        pd_check_receive(v_rec_fifo_index, gen_data_fifo_idx);

        report_alert_counters(FINAL);
        std.env.stop;
        wait;
    end process;


end architecture;