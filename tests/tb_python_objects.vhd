-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

entity tb_python_objects is
  generic(runner_cfg : string);
end entity;

architecture tb of tb_python_objects is
  -- Created by the bench at elaboration, passed to a VC and inspected by the bench
  constant shared_model : python_object_t := new_object("models.counter_model:Counter", kwarg("start", 100));

  signal tick : natural := 0;
  signal count_a, count_b, count_c : integer;
begin
  main : process
    constant duplicate_id : id_t := get_id("duplicate");
    variable object : python_object_t;
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
        check_equal(integer'(call(shared_model, "value")), 103);
        check_equal(eval_string(shared_model, "type(self).__name__"), "Counter");

      elsif run("Test an object of a class defined in the default session") then
        exec("class Doubler:" + "    def apply(self, x):" + "        return 2 * x");
        object := new_object("Doubler");
        check_equal(integer'(call(object, "apply", arg(21))), 42);

      elsif run("Test that two objects with the same identity fail") then
        mock(get_logger(duplicate_id), failure);
        object := new_object("models.counter_model.Counter", id => duplicate_id);
        check_no_log;
        object := new_object("models.counter_model.Counter", id => duplicate_id);
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
    generic map(id => get_id("vc_a"))
    port map(tick => tick, count => count_a);

  -- No id: the instance path is the identity
  vc_b : entity work.counter_vc
    generic map(step => 2)
    port map(tick => tick, count => count_b);

  vc_c : entity work.counter_vc
    generic map(model => shared_model)
    port map(tick => tick, count => count_c);
end architecture;
