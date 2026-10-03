-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A component with a stateful Python model. Every instance runs the model in a
-- session of its own, so the instances do not share the state of the model.

library vunit_lib;

library python_bridge;
context python_bridge.python_context;

entity accumulator_model is
  generic(model_file : string);
  port(
    x : in integer;
    y : out integer
  );
end entity;

architecture python of accumulator_model is
begin
  model : process is
    variable session : python_session_t;
  begin
    -- A fixed name would give all instances the same session, while the instance
    -- name is a distinct identity for every instance. GHDL drops the instance
    -- labels from 'instance_name in a declaration, so it is taken here.
    session := new_session(accumulator_model'instance_name);

    -- The first input comes after test_runner_setup, which a model_file relative
    -- to the testbench needs
    wait on x;
    exec_file(model_file, session);

    loop
      y <= call("accumulate", arg(x), session => session);
      wait on x;
    end loop;
  end process;
end architecture;
