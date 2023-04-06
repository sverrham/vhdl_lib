library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.servo_pkg.all;

-- The servo_pulsegen entity generates a pulse-width modulated (PWM) signal for each output channel.
-- The pulse width varies based on the corresponding angle input (integer value between 0 and 180).
-- The generated PWM signal has a period of 20ms and a pulse width between 1ms (for angle 0) and 2ms (for angle 180).
entity servo_pulsegen is
    generic (
        NUM_OUTPUTS    : positive := 4;      -- Number of output channels
        CLK_PERIOD_NS  : time     := 50 ns  -- Clock period (default is 50 ns, corresponding to 20 MHz clock frequency)
    );
    Port (
        clk        : in  STD_LOGIC;                              -- Clock input
        angle      : in  AngleIntegerArray(0 to NUM_OUTPUTS-1);  -- Vector of angle inputs for each channel
        pulse_out  : out STD_LOGIC_VECTOR(0 to NUM_OUTPUTS-1)    -- Vector of PWM output signals for each channel
    );
end servo_pulsegen;

architecture Behavioral of servo_pulsegen is
    -- Calculate clock frequency, pulse period, and pulse width constants based on generic parameters
    constant CLK_FREQ     : INTEGER := integer(real(1.0 sec / CLK_PERIOD_NS));
    constant PULSE_PERIOD : INTEGER := CLK_FREQ * 20 / 1000; -- 20ms period
    constant PULSE_MIN    : INTEGER := CLK_FREQ * 1 / 1000; -- 1ms pulse
    constant PULSE_MAX    : INTEGER := CLK_FREQ * 2 / 1000; -- 2ms pulse
    constant pulse_multiplier : integer := (PULSE_MAX - PULSE_MIN) / 180;
begin
    -- Main process generating the PWM signals for each output channel
    process(clk)
        type PulseIntegerArray is array (NATURAL range 0 to NUM_OUTPUTS-1) of integer range 0 to PULSE_MAX;
        variable pulse_length : PulseIntegerArray := (others => PULSE_MIN); -- Vector of pulse lengths for each channel
        variable counter      : INTEGER range 0 to PULSE_PERIOD := 0; -- Counter for PWM period
    begin
        if rising_edge(clk) then
            -- Update pulse lengths when counter resets to 0
            if counter = 0 then
                for i in 0 to NUM_OUTPUTS-1 loop
                    pulse_length(i) := PULSE_MIN + angle(i) * pulse_multiplier;
                end loop;
            else
                -- Generate PWM signals based on counter and pulse lengths
                for i in 0 to NUM_OUTPUTS-1 loop
                    if counter < pulse_length(i) then
                        pulse_out(i) <= '1';
                    elsif counter = pulse_length(i) then
                        pulse_out(i) <= '0';
                    end if;
                end loop;
            end if;
            
            -- Increment counter and reset when PULSE_PERIOD is reached
            counter := counter + 1;
            if counter >= PULSE_PERIOD then
                counter := 0;
            end if;
        end if;
    end process;
end Behavioral;
