library ieee;
use ieee.std_logic_1164.all;

package servo_pkg is

-- Define the integer range constraint
subtype AngleInteger is INTEGER range 0 to 180;

-- Define the integer array type with constrained elements
type AngleIntegerArray is array (NATURAL range <>) of AngleInteger;

end package;