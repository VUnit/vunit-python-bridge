-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- Tests of base_path with a base directory set in the run script, the tests
-- directory, which is not the directory of this testbench.

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
  begin
    -- Before test_runner_setup, when the testbench path is not yet set
    if find(runner_cfg, "Test base_path before test_runner_setup") > 0 then
      exec_file(join(base_path, "models/reference_model.py"));
      import_module_from_file(join(base_path, "models/filters.py"), "filters_model");
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
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  -- A verification component loading its model at time 0, before
  -- test_runner_setup has set the testbench path
  vc : process
    constant session : python_session_t := new_session("vc");
  begin
    if find(runner_cfg, "Test base_path from a verification component at time 0") > 0 then
      exec_file(join(base_path, "models/reference_model.py"), session);
      import_module_from_file(join(base_path, "models/filters.py"), "filters_model", session);
    end if;
    wait;
  end process;
end architecture;
