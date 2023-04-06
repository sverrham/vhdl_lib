library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library servo_lib;
use servo_lib.servo_pkg.all;

entity tb_servo is
    generic (runner_cfg : string);
end entity tb_servo;

architecture rtl of tb_servo is
    constant clock_period : time := 100 ns;
    signal clk : std_logic := '0';
    --  signal reset : std_logic := '0';
    signal position : integer range 0 to 180 := 180;

    constant outputs : integer := 4;
    signal position_array : AngleIntegerArray(0 to outputs-1):= (0 => 0, 1 => 45, 2 => 90, 3 => 180);

    signal servo_out : std_logic_vector(0 to outputs-1) := (others => '0');
begin

    clk <= not clk after clock_period/2;
    
    dut : entity work.servo_pulsegen
        generic map (
            num_outputs => outputs,
            CLK_PERIOD_NS => clock_period
        )
        port map (
            clk => clk,
            angle => position_array,
            pulse_out => servo_out
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 10 ms;
        -- test the module by setting a position and checking the output
        
        assert false report "Test failed" severity failure;

        test_runner_cleanup(runner);
    end process;


end architecture;