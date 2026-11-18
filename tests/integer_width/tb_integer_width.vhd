-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- The integers crossing the foreign interface are 32 bits whatever the width
-- of integer, which is 64 bits for NVC with VHDL-2019, see #43. The tests
-- pass with either width.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

entity tb_integer_width is
  generic(runner_cfg : string);
end entity;

architecture tb of tb_integer_width is
begin
  test_runner : process
    constant int32_low : integer := -2147483647 - 1;
    constant int32_high : integer := 2147483647;
    variable arr, result : integer_array_t;
  begin
    test_runner_setup(runner, runner_cfg);
    info("integer'high is " & integer'image(integer'high));

    while test_suite loop
      if run("Test integer results") then
        check_equal(eval_integer("3"), 3);
        check_equal(eval_integer("-1"), -1);
        check_equal(eval_integer("-2**31"), int32_low);
        check_equal(eval_integer("2**31 - 1"), int32_high);

      elsif run("Test integer_vector results") then
        check(eval_integer_vector("[3, 1, 4]") = integer_vector'(3, 1, 4));
        check(
          eval_integer_vector("[-1, -2**31, 2**31 - 1, 0]") = integer_vector'(-1, int32_low, int32_high, 0)
        );

      elsif run("Test integer_array_t round trip") then
        arr := new_1d(length => 4);
        set(arr, 0, 3);
        set(arr, 1, -1);
        set(arr, 2, int32_low);
        set(arr, 3, int32_high);
        exec("def total(a): return int(sum(int(v) for v in a))");
        exec("def same(a): return a");
        check_equal(call_integer("total", arg(arr)), 3 - 1 - 1);
        result := call_integer_array("same", arg(arr));
        check_equal(length(result), 4);
        for idx in 0 to 3 loop
          check_equal(get(result, idx), get(arr, idx));
        end loop;

      elsif run("Test that integer'high reaches Python") then
        -- Arguments are transferred as Python source code, so all of a
        -- 64-bit integer reaches Python
        exec("high = " & integer'image(integer'high));
        check_equal(eval_integer("1 if high in (2**31 - 1, 2**63 - 1) else 0"), 1);
        check_equal(eval_integer("high >> 32"), integer'high / 2**16 / 2**16);
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
