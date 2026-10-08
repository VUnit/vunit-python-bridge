-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A verification component whose behaviour is the Python object of its handle.
-- Every clock cycle with valid set, x is given to the object and its result is
-- the next y. The object is not created in Python until the first valid input.

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

use work.filter_vc_pkg.all;

entity filter_vc is
  generic(filter : filter_vc_t);
  port(
    clk : in std_logic;
    valid : in std_logic;
    x : in integer;
    y : out integer
  );
end entity;

architecture python of filter_vc is
begin
  process(clk)
  begin
    if rising_edge(clk) and valid = '1' then
      y <= call(get_model(filter), "push", arg(x));
    end if;
  end process;
end architecture;
