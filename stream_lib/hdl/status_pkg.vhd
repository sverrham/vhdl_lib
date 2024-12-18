
library ieee;
use ieee.std_logic_1164.all;

package status_pkg is

type  t_status_tag is (SOF, DATA, EOF);

type t_status  is record
    data : std_logic_vector(7 downto 0);
    tag : t_status_tag;
end record;

constant vld_rdy_profiler_status : std_logic_vector(7 downto 0) :=  x"01";

end package;