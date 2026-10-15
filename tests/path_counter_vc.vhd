-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- A verification component whose behaviour is a Python object made by the
-- component: its identity is the id of its handle or its instance path.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

package path_counter_vc_pkg is
  type path_counter_vc_t is record
    p_step : natural;
    p_id : id_t;
  end record;

  -- The identity of the VC is id, or its instance path when null_id
  impure function new_path_counter_vc(step : natural := 1; id : id_t := null_id) return path_counter_vc_t;
end package;

package body path_counter_vc_pkg is
  impure function new_path_counter_vc(step : natural := 1; id : id_t := null_id) return path_counter_vc_t is
  begin
    return (p_step => step, p_id => id);
  end;
end package body;

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

use work.path_counter_vc_pkg.all;

entity path_counter_vc is
  generic(
    vc : path_counter_vc_t
  );
  port(
    tick : in natural;
    count : out integer
  );
end entity;

architecture python of path_counter_vc is
begin
  process
    variable vc_id : id_t := vc.p_id;
    variable backend : python_object_t;
  begin
    -- 'path_name is taken in the process body: during elaboration GHDL leaves
    -- the instance out of it, which would give every instance the same identity
    if vc_id = null_id then
      vc_id := get_id(path_counter_vc'path_name);
    end if;
    backend := new_python_object("models.counter_model.Counter", kwarg("step", vc.p_step), vc_id);

    loop
      wait on tick;
      count <= call(backend, "add", arg(1));
    end loop;
  end process;
end architecture;
