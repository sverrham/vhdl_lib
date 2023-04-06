library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library servo_lib;
use servo_lib.servo_pkg.all;

-- the servo_pulsegen entity generates a pulse-width modulated (pwm) signal for each output channel.
-- the pulse width varies based on the corresponding angle input (integer value between 0 and 180).
-- the generated pwm signal has a period of 20ms and a pulse width between 1ms (for angle 0) and 2ms (for angle 180).
entity servo_pulsegen is
    generic (
        num_outputs    : positive := 4;     -- number of output channels
        clk_period_ns  : time     := 50 ns  -- clock period (default is 50 ns, corresponding to 20 mhz clock frequency)
    );
    port (
        clk        : in  std_logic;                              -- clock input
        angle      : in  angleintegerarray(0 to num_outputs-1);  -- vector of angle inputs for each channel
        pulse_out  : out std_logic_vector(0 to num_outputs-1)    -- vector of pwm output signals for each channel
    );
end servo_pulsegen;

architecture behavioral of servo_pulsegen is
    -- calculate clock frequency, pulse period, and pulse width constants based on generic parameters
    constant clk_freq     : integer := integer(real(1.0 sec / clk_period_ns));
    constant pulse_period : integer := clk_freq * 20 / 1000; -- 20ms period
    constant pulse_min    : integer := clk_freq * 1 / 1000; -- 1ms pulse
    constant pulse_max    : integer := clk_freq * 2 / 1000; -- 2ms pulse
    constant pulse_multiplier : integer := (pulse_max - pulse_min) / 180;
begin
    -- main process generating the pwm signals for each output channel
    process(clk)
        type pulseintegerarray is array (natural range 0 to num_outputs-1) of integer range 0 to pulse_max;
        variable pulse_length : pulseintegerarray := (others => pulse_min); -- vector of pulse lengths for each channel
        variable counter      : integer range 0 to pulse_period := 0; -- counter for pwm period
    begin
        if rising_edge(clk) then
            -- update pulse lengths when counter resets to 0
            if counter = 0 then
                for i in 0 to num_outputs-1 loop
                    pulse_length(i) := pulse_min + angle(i) * pulse_multiplier;
                end loop;
            else
                -- generate pwm signals based on counter and pulse lengths
                for i in 0 to num_outputs-1 loop
                    if counter < pulse_length(i) then
                        pulse_out(i) <= '1';
                    elsif counter = pulse_length(i) then
                        pulse_out(i) <= '0';
                    end if;
                end loop;
            end if;
            
            -- increment counter and reset when pulse_period is reached
            counter := counter + 1;
            if counter >= pulse_period then
                counter := 0;
            end if;
        end if;
    end process;
end behavioral;
