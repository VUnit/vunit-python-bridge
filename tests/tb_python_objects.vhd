-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--

library ieee;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

use work.counter_vc_pkg.all;

entity tb_python_objects is
  generic(runner_cfg : string);
end entity;

architecture tb of tb_python_objects is
  -- Created by the bench at elaboration, passed to a VC and inspected by the bench
  constant shared_model : python_object_t := new_python_object("models.counter_model:Counter", kwarg("start", 100));

  signal tick : natural := 0;
  signal count_a, count_b, count_c, count_d : integer;
begin
  main : process
    constant duplicate_id : id_t := get_id("duplicate");
    variable object : python_object_t;
    variable byte : unsigned(7 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("Test that every instance has an object of its own and a given one is shared") then
        for idx in 1 to 3 loop
          tick <= idx;
          wait for 1 ns;
        end loop;
        check_equal(count_a, 3, "vc_a, a Counter of its own");
        check_equal(count_b, 6, "vc_b, a Counter of its own with step 2");
        check_equal(count_c, 103, "vc_c, the shared Counter");
        check_equal(count_d, 9, "vc_d, a Counter of its own with step 3, by instance path");
        check_equal(integer'(call(shared_model, "value")), 103);
        check_equal(eval_string(shared_model, "type(self).__name__"), "Counter");

      elsif run("Test the result types of the calls of an object") then
        object := new_python_object("models.counter_model.Counter", kwarg("start", 5));
        check_equal(integer'(eval(object, "self.count")), 5);
        check_equal(real'(call(object, "ratio")), 1.25);
        call(object, "add", arg(1));
        call_unsigned(object, "value", byte);
        check(byte = 6, "unsigned result");
        check(integer_vector'(call(object, "history")) = (0, 1, 2, 3, 4, 5, 6));
        check_equal(length(call_integer_array(object, "history")), 7);
        check_true(eval_boolean(object, "self.count == 6"));

      elsif run("Test exec and get_logger of an object") then
        object := new_python_object("models.counter_model.Counter", id => get_id("exec_test"));
        create(object);
        check(get_id(get_session(object)) = get_id("exec_test"), "session of the object");
        exec(object, "self.count = 41");
        check_equal(integer'(call(object, "add", arg(1))), 42);
        check(get_logger(object) = get_logger(get_id("exec_test")), "logger of the object");

      elsif run("Test an object of a class defined in the default session") then
        exec("class Doubler:" + "    def apply(self, x):" + "        return 2 * x");
        object := new_python_object("Doubler");
        check_equal(integer'(call(object, "apply", arg(21))), 42);
        -- Without an id, objects are enumerated like VUnit's verification components
        check_equal(find(full_name(get_id(object)), "python_bridge:python:object:"), 1);

      elsif run("Test that two objects with the same identity fail") then
        mock(get_logger(duplicate_id), failure);
        object := new_python_object("models.counter_model.Counter", id => duplicate_id);
        check_no_log;
        object := new_python_object("models.counter_model.Counter", id => duplicate_id);
        check_only_log(
          get_logger(duplicate_id),
          "Two Python objects have the identity duplicate, give each one an id of its own",
          failure
        );
        unmock(get_logger(duplicate_id));
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  vc_a : entity work.counter_vc
    generic map(vc => new_counter_vc(id => get_id("vc_a")))
    port map(tick => tick, count => count_a);

  -- No id: an enumerated anonymous identity
  vc_b : entity work.counter_vc
    generic map(vc => new_counter_vc(step => 2))
    port map(tick => tick, count => count_b);

  vc_c : entity work.counter_vc
    generic map(vc => new_counter_vc(model => shared_model))
    port map(tick => tick, count => count_c);

  -- Without a handle: the instance path is the identity
  vc_d : entity work.path_counter_vc
    generic map(step => 3)
    port map(tick => tick, count => count_d);
end architecture;
