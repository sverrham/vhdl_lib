library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;


library servo_lib;
use servo_lib.servo_pkg.all;

entity tb_servo is
    generic (runner_cfg : string := "test");
end entity tb_servo;

architecture rtl of tb_servo is
    constant clock_period : time := 100 ns;
    signal clk : std_logic := '0';
    --  signal reset : std_logic := '0';
    signal position : integer range 0 to 180 := 180;

    constant outputs : integer := 4;
    signal position_array : AngleIntegerArray(0 to outputs-1):= (0 => 0, 1 => 45, 2 => 90, 3 => 180);

    signal servo_out : std_logic_vector(0 to outputs-1) := (others => '0');
    constant servo_out_high : std_logic_vector(0 to outputs-1) := (others => '1');
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

        
        wait for 10 ns;
        -- test the module by setting a position and checking the output
        info("Starting test");
        -- Simple test wait until output 1 goes low, then check time lpsed is 1.0ms
        wait until servo_out(0) = '0' for 20 ms;
        info("Output 0 went low");
        info(time'image(now));
        
        assert now < 1.01 ms report "Output 0 went low at wrong time" severity failure;
        assert now > 0.99 ms report "Output 0 went low at wrong time" severity failure;
        
        -- Simple test for output 1, wait until output 1 goes low, then check time lpsed is 1.25ms
        wait until servo_out(1) = '0' for 20 ms;
        info("Output 1 went low");
        info(time'image(now));
        assert now < 1.26 ms report "Output 1 went low at wrong time" severity failure;
        assert now > 1.24 ms report "Output 1 went low at wrong time" severity failure;
        
        -- Simple test for output 2, wait until output 1 goes low, then check time lpsed is 1.5ms
        wait until servo_out(2) = '0' for 20 ms;
        info("Output 2 went low");
        info(time'image(now));
        assert now < 1.51 ms report "Output 2 went low at wrong time" severity failure;
        assert now > 1.49 ms report "Output 2 went low at wrong time" severity failure;
        
        -- Simple test for output 3, wait until output 1 goes low, then check time lpsed is 2.0ms
        wait until servo_out(3) = '0' for 20 ms;
        info("Output 3 went low");
        info(time'image(now));
        assert now < 2.01 ms report "Output 3 went low at wrong time" severity failure;
        assert now > 1.99 ms report "Output 3 went low at wrong time" severity failure;
        
        -- Verify all outputs go high after the period of 20ms has lapsed
        wait until servo_out(0) = '1' for 20 ms;
        info("20ms has elapsed");
        info(time'image(now));
        assert servo_out = servo_out_high report "Outputs did not go high" severity failure;



        test_runner_cleanup(runner);
    end process;


end architecture;