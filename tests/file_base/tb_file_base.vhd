-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- Tests of file names: base_path with a base directory set in the run script,
-- the tests directory, which is not the directory of this testbench, and
-- relative and empty file names of exec_file and import_module_from_file.

library vunit_lib;
context vunit_lib.vunit_context;
library python_bridge;
context python_bridge.python_context;

entity tb_file_base is
  generic (
    runner_cfg : string;
    base_dir : string
  );
end entity;

architecture tb of tb_file_base is
begin
  main : process
    constant vc_session : python_session_t := new_session("vc");
    constant default_logger : logger_t := get_logger(get_id(default_session));
    constant before_setup_failure : string :=
      "A relative file name needs the testbench path set by test_runner_setup. " &
      "Call it after test_runner_setup, give an absolute path, " &
      "or join it to base_path with a base directory set in the run script.";
    variable checked_before_setup : boolean := false;
  begin
    -- Before test_runner_setup, when the testbench path is not yet set
    if find(runner_cfg, "Test base_path before test_runner_setup") > 0 then
      exec_file(join(base_path, "models/reference_model.py"));
      import_module_from_file(join(base_path, "models/filters.py"), "filters_model");
    end if;
    -- Relative file names before test_runner_setup, as from a verification component at time 0
    if find(runner_cfg, "Test relative file names before test_runner_setup") > 0 then
      mock(default_logger, failure);
      exec_file("local_model.py");
      check_only_log(default_logger, "exec_file(""local_model.py"") failed:" & LF & before_setup_failure, failure);
      import_module_from_file("local_model.py", "local_model");
      check_only_log(
        default_logger,
        "import_module_from_file(""local_model.py"", ""local_model"") failed:" & LF & before_setup_failure,
        failure
      );
      unmock(default_logger);
      checked_before_setup := true;
    end if;
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("Test base_path from a verification component at time 0") then
        -- The verification component loaded its model at time 0
        wait for 1 ns;
        check_equal(call_string("get_model_dir", session => vc_session), join(base_dir, "models"));
        check_equal(integer'(eval("filters_model.fir(1)", session => vc_session)), 2);

      elsif run("Test base_path before test_runner_setup") then
        check_equal(call_string("get_model_dir"), join(base_dir, "models"));
        check_equal(integer'(eval("filters_model.fir(4)")), 5);

      elsif run("Test base_path after test_runner_setup") then
        check_equal(base_path, base_dir);
        exec_file(join(base_path, "models/reference_model.py"));
        check_equal(call_string("get_model_dir"), join(base_dir, "models"));
        import_module_from_file(join(base_path, "models/filters.py"), "filters_model");
        check_equal(integer'(eval("filters_model.fir(2)")), 3);

      elsif run("Test a relative file name of exec_file is relative to the testbench") then
        exec_file("local_model.py");
        check_equal(call_string("get_local_dir") & "/", tb_path(runner_cfg));

      elsif run("Test relative file names before test_runner_setup") then
        check_true(checked_before_setup);
        -- Nothing was executed or imported
        check_false(eval_boolean("'get_local_dir' in globals() or 'local_model' in globals()"));

      elsif run("Test a relative file name from a verification component waiting for test_runner_setup") then
        -- The verification component loaded its model once test_runner_setup had completed
        wait for 1 ns;
        check_equal(call_string("get_local_dir", session => vc_session) & "/", tb_path(runner_cfg));

      elsif run("Test an empty file name") then
        mock(default_logger, failure);
        exec_file("");
        check_only_log(default_logger, "exec_file("""") failed:" & LF & "Empty file name.", failure);
        import_module_from_file("", "x");
        check_only_log(default_logger, "import_module_from_file("""", ""x"") failed:" & LF & "Empty file name.", failure);
        unmock(default_logger);
        check_false(eval_boolean("'x' in globals()"));
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  -- A verification component loading its model: at time 0, before test_runner_setup has set
  -- the testbench path, through base_path, or by a relative file name once test_runner_setup
  -- has completed
  vc : process
    constant session : python_session_t := new_session("vc");
  begin
    if find(runner_cfg, "Test base_path from a verification component at time 0") > 0 then
      exec_file(join(base_path, "models/reference_model.py"), session);
      import_module_from_file(join(base_path, "models/filters.py"), "filters_model", session);
    elsif find(runner_cfg, "Test a relative file name from a verification component waiting for test_runner_setup") > 0 then
      if get_phase <= test_runner_setup then
        wait on runner until get_phase > test_runner_setup;
      end if;
      exec_file("local_model.py", session);
    end if;
    wait;
  end process;
end architecture;
