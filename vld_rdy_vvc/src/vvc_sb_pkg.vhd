--==========================================================================================
-- This VVC was generated with UVVM VVC Generator
--==========================================================================================


--==========================================================================================
--  vvc_sb_pkg
--==========================================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library bitvis_vip_scoreboard;

use work.transaction_pkg.all;

package vvc_sb_pkg is new bitvis_vip_scoreboard.generic_sb_pkg
  generic map (
    t_element         => std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH - 1 downto 0),
    element_match     => std_match,
    to_string_element => to_string
  );

--==========================================================================================
--  vvc_sb_support_pkg
--==========================================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library bitvis_vip_scoreboard;
use bitvis_vip_scoreboard.generic_sb_support_pkg.all;

use work.transaction_pkg.all;

package vvc_sb_support_pkg is
  -- The data parameter used in the scoreboard procedures needs to have the same length as
  -- the t_element defined in the VVC's built-in scoreboard, since even though it is a generic
  -- type, it constrained during elaboration time.
  -- This function is used to pad the data without having to know the exact length of t_element.
  function pad_vld_rdy_sb (
    constant data : in std_logic_vector
  ) return std_logic_vector;
end package vvc_sb_support_pkg;

package body vvc_sb_support_pkg is
  function pad_vld_rdy_sb (
    constant data : in std_logic_vector
  ) return std_logic_vector is 
  begin
    return pad_sb_slv(data, C_VVC_CMD_DATA_MAX_LENGTH);
  end function pad_vld_rdy_sb;
end package body vvc_sb_support_pkg;

