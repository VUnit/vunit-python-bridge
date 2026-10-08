-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A verification component whose behaviour is the Python object of its handle.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

use work.counter_vc_pkg.all;

entity counter_vc is
  generic(vc : counter_vc_t);
  port(
    tick : in natural;
    count : out integer
  );
end entity;

architecture python of counter_vc is
begin
  process
  begin
    wait on tick;
    count <= call(get_model(vc), "add", arg(1));
  end process;
end architecture;
