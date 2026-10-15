-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library python_bridge;
context python_bridge.python_context;

use work.counter_vc_pkg.all;
use work.path_counter_vc_pkg.all;

entity tb_python_objects is
  generic(runner_cfg : string);
end entity;

architecture tb of tb_python_objects is
  -- Created by the bench at elaboration, passed to a VC and inspected by the bench
  constant shared_model : python_object_t := new_python_object("models.counter_model.Counter", kwarg("start", 100));

  signal tick : natural := 0;
  signal count_a, count_b, count_c, count_d : integer;
begin
  main : process
    constant duplicate_id : id_t := get_id("duplicate");
    constant session_id : id_t := get_id("session_first");
    constant broken_id : id_t := get_id("broken");
    constant deferred_broken_id : id_t := get_id("deferred_broken");
    constant call_errors_id : id_t := get_id("call_errors");
    variable object, other : python_object_t;
    variable session : python_session_t;
    variable std_cfg, other_std_cfg : std_cfg_t;
    variable byte : unsigned(7 downto 0);
    variable bits : std_ulogic_vector(7 downto 0);
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
        check_equal(integer'(call(get_python_object("tb_python_objects:vc_d"), "value")), 9, "vc_d by its path");
        check_equal(integer'(call(get_python_object("vc_a"), "value")), 3, "the model of vc_a by its identity");
        check_equal(integer'(call(shared_model, "value")), 103);
        check_equal(eval_string(shared_model, "type(obj).__name__"), "Counter");

      elsif run("Test the result types of the calls of an object") then
        object := new_python_object("models.counter_model.Counter", kwarg("start", 5));
        check_equal(integer'(eval(object, "obj.count")), 5);
        check_equal(real'(call(object, "ratio")), 1.25);
        call(object, "add", arg(1));
        call_unsigned(object, "value", byte);
        check(byte = 6, "unsigned result");
        check(integer_vector'(call(object, "history")) = (0, 1, 2, 3, 4, 5, 6));
        check_equal(length(call_integer_array(object, "history")), 7);
        check_true(eval_boolean(object, "obj.count == 6"));
        -- The eval procedures of an object
        eval_unsigned(object, "obj.count + 1", byte);
        check(byte = 7, "eval_unsigned");
        eval_std_ulogic_vector(object, "'0000' + '1000'", bits);
        check(bits = "00001000", "eval_std_ulogic_vector");

      elsif run("Test exec and get_logger of an object") then
        object := create_python_object("models.counter_model.Counter", id => get_id("exec_test"));
        check(get_id(get_session(object)) = get_id("exec_test"), "session of the object");
        exec(object, "obj.count = 41");
        check_equal(integer'(call(object, "add", arg(1))), 42);
        check(get_logger(object) = get_logger(get_id("exec_test")), "logger of the object");

      elsif run("Test an object of a class defined in the default session") then
        exec("class Doubler:" + "    def apply(self, x):" + "        return 2 * x");
        object := new_python_object("Doubler");
        check_equal(integer'(call(object, "apply", arg(21))), 42);
        -- Without an id, objects are enumerated per class
        check_equal(full_name(get_id(object)), "python_bridge:python:object:Doubler:1");

      elsif run("Test that an identity used by another object or a session fails") then
        mock(get_logger(duplicate_id), failure);
        object := new_python_object("models.counter_model.Counter", id => duplicate_id);
        check_no_log;
        object := new_python_object("models.counter_model.Counter", id => duplicate_id);
        check_only_log(
          get_logger(duplicate_id),
          "new_python_object(""models.counter_model.Counter"") failed:" & LF &
          "The identity duplicate is already used by another Python object or session, " &
          "give each object an id of its own.",
          failure
        );
        unmock(get_logger(duplicate_id));
        check(object = null_python_object, "no object for a used identity");

        session := new_session(session_id);
        mock(get_logger(session_id), failure);
        object := new_python_object("models.counter_model.Counter", id => session_id);
        check_only_log(
          get_logger(session_id),
          "new_python_object(""models.counter_model.Counter"") failed:" & LF &
          "The identity session_first is already used by another Python object or session, " &
          "give each object an id of its own.",
          failure
        );
        unmock(get_logger(session_id));
        check(object = null_python_object, "no object for the identity of a session");

      elsif run("Test an object that cannot be created") then
        -- create_python_object reports it right away
        mock(get_logger(broken_id), failure);
        object := create_python_object("models.no_such_module.Model", id => broken_id);
        check_only_log(
          get_logger(broken_id),
          "create_python_object(""models.no_such_module.Model"") failed:" & LF &
          "ImportError: No class named 'models.no_such_module.Model': models has no attribute 'no_such_module'",
          failure
        );
        -- Reported once, then every use fails with the reason
        check_equal(integer'(call(object, "value")), integer'low);
        check_only_log(
          get_logger(broken_id),
          "call(""value"") failed:" & LF &
          "RuntimeError: The models.no_such_module.Model object could not be created: " &
          "ImportError: No class named 'models.no_such_module.Model': models has no attribute 'no_such_module'",
          failure
        );
        unmock(get_logger(broken_id));

        -- new_python_object reports it at the first use, as new_python_object
        mock(get_logger(deferred_broken_id), failure);
        object := new_python_object("models.no_such_module.Model", id => deferred_broken_id);
        check_no_log;
        check_equal(integer'(call(object, "value")), integer'low);
        check_log(
          get_logger(deferred_broken_id),
          "new_python_object(""models.no_such_module.Model"") failed:" & LF &
          "ImportError: No class named 'models.no_such_module.Model': models has no attribute 'no_such_module'",
          failure
        );
        check_only_log(
          get_logger(deferred_broken_id),
          "call(""value"") failed:" & LF &
          "RuntimeError: The models.no_such_module.Model object could not be created: " &
          "ImportError: No class named 'models.no_such_module.Model': models has no attribute 'no_such_module'",
          failure
        );
        unmock(get_logger(deferred_broken_id));

      elsif run("Test that the call of a method is named in its errors") then
        object := new_python_object("models.counter_model.Counter", id => call_errors_id);
        mock(get_logger(call_errors_id), failure);
        -- The function and the procedure forms name the call alike
        check_equal(integer'(call(object, "name")), integer'low);
        check_only_log(
          get_logger(call_errors_id),
          "call(""name"") failed:" & LF &
          "TypeError: Cannot convert Python str ('counter') to VHDL integer; expected int",
          failure
        );
        call_unsigned(object, "name", byte);
        check_only_log(
          get_logger(call_errors_id),
          "call(""name"") failed:" & LF &
          "TypeError: Cannot convert Python str ('counter') to VHDL unsigned; expected int",
          failure
        );
        unmock(get_logger(call_errors_id));

      elsif run("Test that objects have sessions and numbers of their own") then
        object := new_python_object("models.counter_model.Counter", kwarg("start", 1));
        other := new_python_object("models.counter_model.Counter", kwarg("start", 2));
        check_equal(integer'(eval(object, "obj.count")), 1);
        check_equal(integer'(eval(other, "obj.count")), 2);
        exec(object, "shared = 'object'");
        check_false(eval_boolean(other, "'shared' in globals()"), "the sessions are separate");
        -- Without an id, objects are enumerated per class, the class name giving the hierarchy
        check_equal(
          full_name(get_id(object)), "python_bridge:python:object:models:counter_model:Counter:" & name(get_id(object))
        );
        check_equal(integer'value(name(get_id(other))), integer'value(name(get_id(object))) + 1);

      elsif run("Test that exec and get_logger work before the object is created") then
        object := new_python_object("models.counter_model.Counter", id => get_id("lazy"));
        check(get_logger(object) = get_logger(get_id("lazy")), "logger before creation");
        exec(object, "obj.count = 7");
        check_equal(integer'(call(object, "value")), 7);

      elsif run("Test that get_python_object finds an object by its identity or full name") then
        object := new_python_object("models.counter_model.Counter", kwarg("start", 5), name => "tb:by_name");
        check_equal(full_name(get_id(object)), "tb:by_name");
        check(get_python_object("tb:by_name") = object, "by full name");
        check(get_python_object(get_id("tb:by_name")) = object, "by identity");
        other := create_python_object("models.counter_model.Counter", kwarg("start", 6), name => "tb:created");
        check_equal(integer'(call(get_python_object("tb:created"), "value")), 6);

      elsif run("Test that get_python_object returns null_python_object for an identity without an object") then
        check(get_python_object("tb:no_object") = null_python_object, "unknown name");
        check_false(has_id("tb:no_object"), "a failed lookup makes no identity");
        check(get_python_object(get_id("tb:id_without_object")) = null_python_object, "identity without object");
        check(get_python_object(null_id) = null_python_object, "null_id");

      elsif run("Test that null_python_object is reported") then
        mock(python_logger, failure);
        call(null_python_object, "value");
        check_only_log(python_logger, "null_python_object was used, it is not an object", failure);
        check_equal(integer'(call(null_python_object, "value")), integer'low);
        check_only_log(python_logger, "null_python_object was used, it is not an object", failure);
        unmock(python_logger);

      elsif run("Test objects with the identities of create_std_cfg") then
        -- As in "Backends of verification components" of the user guide
        std_cfg := create_std_cfg(provider => "test_vcs", vc_name => "counter");
        other_std_cfg := create_std_cfg(provider => "test_vcs", vc_name => "counter");
        object := new_python_object("models.counter_model.Counter", id => get_id(std_cfg));
        other := new_python_object("models.counter_model.Counter", id => get_id(other_std_cfg));
        check_equal(full_name(get_id(object)), "test_vcs:counter:1");
        check_equal(full_name(get_id(other)), "test_vcs:counter:2");
        check_equal(integer'(call(object, "add", arg(1))), 1);
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  vc_a : entity work.counter_vc
    generic map (
      vc => new_counter_vc(id => get_id("vc_a"))
    )
    port map (
      tick  => tick,
      count => count_a
    );

  -- No id: an enumerated anonymous identity
  vc_b : entity work.counter_vc
    generic map (
      vc => new_counter_vc(step => 2)
    )
    port map (
      tick  => tick,
      count => count_b
    );

  vc_c : entity work.counter_vc
    generic map (
      vc => new_counter_vc(model => shared_model)
    )
    port map (
      tick  => tick,
      count => count_c
    );

  -- A handle without an id: the instance path is the identity
  vc_d : entity work.path_counter_vc
    generic map (
      vc => new_path_counter_vc(step => 3)
    )
    port map (
      tick  => tick,
      count => count_d
    );
end architecture;
