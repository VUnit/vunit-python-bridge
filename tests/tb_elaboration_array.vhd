-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- An integer_array_t argument made during elaboration must fail with a clear
-- error, not crash the simulator, see #17. tests/run.py expects it to fail
-- and checks the error.

library vunit_lib;
context vunit_lib.vunit_context;
library python_bridge;
context python_bridge.python_context;

entity tb_elaboration_array is
  generic(runner_cfg : string);
end entity;

architecture tb of tb_elaboration_array is
  impure function one_to_four return integer_array_t is
    variable values : integer_array_t := new_1d(4);
  begin
    for idx in 0 to 3 loop
      set(values, idx, idx + 1);
    end loop;
    return values;
  end;

  constant values_arg : arg_t := arg(one_to_four);
begin
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    check_equal(integer'(call("sum", values_arg)), 10);
    test_runner_cleanup(runner);
  end process;
end architecture;
