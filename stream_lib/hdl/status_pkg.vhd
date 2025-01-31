
library ieee;
use ieee.std_logic_1164.all;

package status_pkg is

type  t_status_tag is (SOF, DATA, EOF, UDEF);

type t_status  is record
    data : std_logic_vector(7 downto 0);
    tag : t_status_tag;
end record;

type t_status_array is array (natural range <>) of t_status;

constant vld_rdy_profiler_status : std_logic_vector(7 downto 0) :=  x"01";
constant arp_ether_type_status : std_logic_vector(7 downto 0) :=  x"02";
constant stream_to_status_short_status : std_logic_vector(7 downto 0) :=  x"03";

function status_to_slv(status: t_status)
    return std_logic_vector;

function slv_to_status(slv_data: std_logic_vector)
    return t_status;

end package;

package body status_pkg is

function status_to_slv(status : t_status) return std_logic_vector is
begin
    case status.tag is
        when SOF =>
            return status.data & "00";
        when DATA =>
            return status.data & "01";
        when EOF =>
            return status.data & "10";
        when UDEF =>
            return status.data & "11";
        end case;
end function;

function slv_to_status(slv_data : std_logic_vector) return t_status is
    variable v_status : t_status;
    variable v_tag_slv : std_logic_vector(1 downto 0);
begin
    v_status.data := slv_data(9 downto 2); 
    v_tag_slv := slv_data(1 downto 0);
    case v_tag_slv is
        when "00" => v_status.tag := SOF;
        when "01" => v_status.tag := DATA;
        when "10" => v_status.tag := EOF;
        when "11" => v_status.tag := UDEF;
        when others => report "error" severity ERROR;
    end case;
    return v_status;
end function slv_to_status;


end package body;