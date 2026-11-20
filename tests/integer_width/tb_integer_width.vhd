-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- The transfers of integers with the width of integer, which is 64 bits for
-- some simulators with VHDL-2019, see #43. The tests pass with either width.

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
    variable ptr : integer_vector_ptr_t;
    variable dict : dict_t;
    variable two_32 : integer;
    constant session_logger : logger_t := get_logger(get_id(default_session));
  begin
    test_runner_setup(runner, runner_cfg);
    info("integer'high is " & integer'image(integer'high));

    while test_suite loop
      if run("Test integer results") then
        check_equal(eval_integer("3"), 3);
        check_equal(eval_integer("-1"), -1);
        check_equal(eval_integer("-2**31"), int32_low);
        check_equal(eval_integer("2**31 - 1"), int32_high);
        check_equal(eval_integer(integer'image(integer'low)), integer'low);
        check_equal(eval_integer(integer'image(integer'high)), integer'high);
        if integer'high > int32_high then
          -- Both halves of a 64-bit integer. 2**32 is computed at run time
          -- since it does not fit in a 32-bit integer.
          two_32 := 2**16;
          two_32 := two_32 * two_32;
          check_equal(eval_integer("2**32 + 5"), two_32 + 5);
          check_equal(eval_integer("-2**32 - 5"), -two_32 - 5);
          check_equal(eval_integer("2**40 + 2**31"), two_32 * 256 + two_32 / 2);
          check_equal(eval_integer("-2**40 - 1"), -two_32 * 256 - 1);
        end if;

      elsif run("Test integer_vector results") then
        check(eval_integer_vector("[3, 1, 4]") = integer_vector'(3, 1, 4));
        check(
          eval_integer_vector("[-1, -2**31, 2**31 - 1, 0]") = integer_vector'(-1, int32_low, int32_high, 0)
        );
        check(
          eval_integer_vector("[" & integer'image(integer'low) & ", " & integer'image(integer'high) & "]") =
          integer_vector'(integer'low, integer'high)
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

      elsif run("Test that an integer_array_t element outside 32 bits fails") then
        -- The elements cross as 32 bits. The failures are counted rather than
        -- mocked since VHDL-2019 gives a log entry the location of its call
        -- path, which check_log compares.
        disable_stop(python_logger, failure, unset_children => true);
        exec("import numpy");
        result := eval_integer_array("numpy.array([2**40])");
        check_equal(get_log_count(session_logger, failure), 1, "failures of a result");
        if integer'high > int32_high then
          -- An integer_array_t with a bit_width of 32 holds a 64-bit integer
          two_32 := 2**16;
          two_32 := two_32 * two_32;
          arr := new_1d(length => 3);
          set(arr, 2, two_32 * 256);
          exec("def same(a): return a");
          result := call_integer_array("same", arg(arr));
          check_equal(get_log_count(python_logger, failure), 1, "failures of an argument");
        end if;
        reset_log_count(python_logger, failure);

      elsif run("Test integer_vector_ptr_t results") then
        ptr := eval_integer_vector_ptr("[-1, -2**31, 2**31 - 1]");
        check_equal(length(ptr), 3);
        check_equal(get(ptr, 0), -1);
        check_equal(get(ptr, 1), int32_low);
        check_equal(get(ptr, 2), int32_high);
        ptr := eval_integer_vector_ptr("[" & integer'image(integer'high) & ", " & integer'image(integer'low) & "]");
        check_equal(get(ptr, 0), integer'high);
        check_equal(get(ptr, 1), integer'low);

      elsif run("Test dict_t results") then
        dict := eval_dict("{'a': -1, 'b': 2**31 - 1, 'c': [-2**31, 3], 'd': True, 'e': {'f': -5}}");
        check_equal(get_integer(dict, "a"), -1);
        check_equal(get_integer(dict, "b"), int32_high);
        ptr := get_integer_vector_ptr_t_ref(dict, "c");
        check_equal(get(ptr, 0), int32_low);
        check_equal(get(ptr, 1), 3);
        check(get_boolean(dict, "d"));
        check_equal(get_integer(get_dict_t_ref(dict, "e"), "f"), -5);
        dict := eval_dict("{'c': [" & integer'image(integer'low) & ", " & integer'image(integer'high) & "]}");
        ptr := get_integer_vector_ptr_t_ref(dict, "c");
        check_equal(get(ptr, 0), integer'low);
        check_equal(get(ptr, 1), integer'high);

      elsif run("Test that a dict_t integer outside 32 bits fails") then
        -- VUnit stores the integers of a dict_t in 32 bits whatever the width of
        -- integer. The failure is counted rather than mocked since VHDL-2019 gives
        -- a log entry the location of its call path, which check_log compares.
        disable_stop(session_logger, failure);
        dict := eval_dict("{'a': 2**31}");
        check_equal(get_log_count(session_logger, failure), 1, "failures of eval_dict");
        reset_log_count(session_logger, failure);

      elsif run("Test boolean results") then
        -- A boolean result is read as an integer, which takes the high half
        -- from the metadata with a 64-bit integer
        check(eval_boolean("True"));
        check(not eval_boolean("False"));

      elsif run("Test that integer'high reaches Python") then
        -- Arguments are transferred as Python source code, so all of a
        -- 64-bit integer reaches Python
        exec("high = " & integer'image(integer'high));
        check_equal(eval_integer("1 if high in (2**31 - 1, 2**63 - 1) else 0"), 1);
        check_equal(eval_integer("high >> 32"), integer'high / 2**16 / 2**16);
        exec("def top(v): return int(max(v) >> 32)");
        check_equal(call_integer("top", arg(integer_vector'(1, integer'high))), integer'high / 2**16 / 2**16);
        ptr := new_integer_vector_ptr(2);
        set(ptr, 1, integer'low);
        check_equal(call_integer("top", arg(ptr)), 0);
        -- Not a dict_t value: VUnit encodes the integers of a dict_t in 32 bits
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
