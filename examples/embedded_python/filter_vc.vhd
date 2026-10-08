-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A verification component whose behaviour is the Python object of its handle.
-- Its object is not created in Python until the first input arrives.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

use work.filter_vc_pkg.all;

entity filter_vc is
  generic(filter : filter_vc_t);
  port(
    x : in integer;
    y : out integer
  );
end entity;

architecture python of filter_vc is
begin
  process
  begin
    wait on x;
    y <= call(get_model(filter), "push", arg(x));
  end process;
end architecture;
