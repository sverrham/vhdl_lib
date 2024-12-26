library ieee;
use ieee.std_logic_1164.all;

package stream_pkg is 

type  t_stream_tag is (SOF, DATA, EOF, UDEF);

type t_stream is record 
    data : std_logic_vector(31 downto 0);
    tag  : t_stream_tag;
end record;

constant t_stream_init : t_stream := (data => (others => '0'), tag => UDEF);

function stream_to_slv(stream: t_stream)
    return std_logic_vector; 

function slv_to_stream(slv_data: std_logic_vector)
    return t_stream;

function stream_tag_to_string(tag: t_stream_tag)
    return string;

-- Stream tag types
constant mac_raw_stream : std_logic_vector(7 downto 0) :=  x"01";

end package stream_pkg;

package body stream_pkg is

function stream_to_slv(stream : t_stream) return std_logic_vector is
begin
    case stream.tag is
        when SOF =>
            return stream.data & "00";
        when DATA =>
            return stream.data & "01";
        when EOF =>
            return stream.data & "10";
        when UDEF =>
            return stream.data & "11";
        end case;
end function;

function slv_to_stream(slv_data : std_logic_vector) return t_stream is
    variable v_data : t_stream;
    variable v_tag_slv : std_logic_vector(1 downto 0);
begin
    v_data.data := slv_data(33 downto 2); 
    v_tag_slv := slv_data(1 downto 0);
    case v_tag_slv is
        when "00" => v_data.tag := SOF;
        when "01" => v_data.tag := DATA;
        when "10" => v_data.tag := EOF;
        when "11" => v_data.tag := UDEF;
        when others => report "error" severity ERROR;
    end case;
    return v_data;
end function slv_to_stream;

function stream_tag_to_string(tag : t_stream_tag) return string is
begin
    case tag is
        when SOF =>
            return "SOF";
        when DATA =>
            return "DATA";
        when EOF =>
            return "EOF";
        when UDEF =>
            return "UDEF";
        end case;
end function;



end package body stream_pkg;