

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library reference_lib;

-- Wrapper for the frequency measurement and error calculation modules.
entity freq_measure_wrapper is
    generic (
        g_frequency : real;
        g_instance  : integer := 0
    );
    port (
        clk_i: in std_logic;
        pps_i: in std_logic;
        msg_req_o: out std_logic;
        msg_busy_i: in std_logic;
        msg_data_o : out std_logic_vector(7 downto 0);
        msg_data_vld_o : out std_logic
        );
end freq_measure_wrapper;

architecture rtl of freq_measure_wrapper is

    constant c_bits : integer := 25;

    signal count : unsigned(c_bits-1 downto 0);
    signal count_vld : std_logic;
    signal error_ppb : signed(c_bits-1 downto 0);
    signal error_ppb_vld : std_logic;

    -- signal high_offset : std_logic;

    signal msg_data_vld : std_logic := '0';
begin

    pps_counter : entity reference_lib.pps_counter
    generic map(
        g_bits => c_bits
    )
    port map(
        clk_i => clk_i,
        pps_i => pps_i,
        last_count_o => count,
        last_count_vld_o => count_vld
    );
    
    freq_offset_from_count : entity reference_lib.freq_offset_from_count
    generic map(
        g_frequency => g_frequency,
        g_bits => c_bits
    )
    port map(
        clk_i => clk_i,
        count_i => count,
        count_vld_i => count_vld,
        error_ppb_o => error_ppb,
        error_ppb_vld_o => error_ppb_vld
    );

    -- error_ppb_proc : process(clk_i)
    -- begin
    --     if  rising_edge(clk_i) then
    --         if error_ppb_vld = '1' then
    --             if (error_ppb > to_signed(10000, 32) or error_ppb < to_signed(-10000, 32)) then
    --                 high_offset <= '1';
    --             else
    --                 high_offset <= '0';
    --             end if;
    --         end if; 
    --     end if;
    -- end process;

    debug_message_block : block is
        type state_t is (idle, new_line, car_return, 
                         count_type, count_length, count_inst, count_value,
                         error_type, error_length, error_inst, error_value);
        signal state : state_t := idle;
        signal cur_count : std_logic_vector(31 downto 0);
        signal cnt : integer range 0 to 7 := 0;
        signal err_cnt : integer range 0 to 7 := 0;

        signal error_vld : std_logic := '0';
        signal cur_error_ppb : std_logic_vector(31 downto 0);
    begin

    msg_data_vld_o <= msg_data_vld;
    
    debug_info_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Send debug info.
            msg_data_vld <= '0';

            if error_ppb_vld = '1' then
                error_vld <= '1';
                cur_error_ppb <= (others => '0');
                cur_error_ppb(error_ppb'range) <= std_logic_vector(error_ppb);
            end if;
            
            case state is
                when idle =>
                    msg_req_o <= '1';
                    if count_vld = '1' then
                        cur_count <= (others => '0');
                        cur_count(count'range) <= std_logic_vector(count);
                        cnt <= 0;
                        state <= count_type;
                    elsif error_vld = '1' then
                    -- elsif error_ppb_vld = '1' then
                        err_cnt <= 0;
                        error_vld <= '0';
                        state <= error_type;
                        -- state <= count_type;
                    else
                        msg_req_o <= '0';
                    end if;

                when count_type =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"01";
                        msg_data_vld <= '1';
                        state <= count_length;
                    end if;

                when count_length =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"07";
                        msg_data_vld <= '1';
                        state <= count_inst;
                    end if;

                when count_inst =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= std_logic_vector(to_unsigned(g_instance, 8));
                        msg_data_vld <= '1';
                        state <= count_value;
                    end if;    

                when count_value =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= cur_count(7+8*cnt downto 8*cnt);
                        msg_data_vld <= '1';
                        cnt <= cnt + 1;
                        if cnt = 3 then
                            state <= car_return;
                        end if;
                    end if;

                when error_type =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"02";
                        msg_data_vld <= '1';
                        state <= error_length;
                    end if;

                when error_length =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"07";
                        msg_data_vld <= '1';
                        state <= error_inst;
                    end if;

                when error_inst =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= std_logic_vector(to_unsigned(g_instance, 8));
                        msg_data_vld <= '1';
                        state <= error_value;
                    end if;  

                when error_value =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= cur_error_ppb(7+8*err_cnt downto 8*err_cnt);
                        msg_data_vld <= '1';
                        err_cnt <= err_cnt + 1;
                        if err_cnt = 3 then
                            state <= car_return;
                        end if;
                    end if;

                when car_return =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"0D";
                        msg_data_vld <= '1';
                        state <= new_line;
                    end if;

                when new_line =>
                    if msg_busy_i = '0' and msg_data_vld = '0' then
                        msg_data_o <= x"0A";
                        msg_data_vld <= '1';
                        state <= idle;
                    end if;

                
            end case;

        end if;
    end process;
    end block;

end rtl;