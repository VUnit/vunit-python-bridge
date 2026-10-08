-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A verification component without a handle whose behaviour is a Python
-- object: its identity is its instance path or the id it is given.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

entity path_counter_vc is
  generic(
    -- The identity of the VC, the instance path when null_id
    id : id_t := null_id;
    -- The object to use instead of a Counter of its own
    model : python_object_t := null_python_object;
    step : natural := 1
  );
  port(
    tick : in natural;
    count : out integer
  );
end entity;

architecture python of path_counter_vc is
begin
  process
    variable vc_id : id_t := id;
    variable backend : python_object_t;
  begin
    -- 'path_name is taken in the process body: during elaboration GHDL leaves
    -- the instance out of it, which would give every instance the same identity
    if vc_id = null_id then
      vc_id := get_id(path_counter_vc'path_name);
    end if;
    backend := get_python_object(model, "models.counter_model.Counter", kwarg("step", step), vc_id);

    loop
      wait on tick;
      count <= call(backend, "add", arg(1));
    end loop;
  end process;
end architecture;
