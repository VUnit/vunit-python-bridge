-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- The handle of counter_vc, made the way VUnit's verification components are:
-- the constructor creates everything, including the Python object, unless
-- the other constructor is given one.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

package counter_vc_pkg is
  type counter_vc_t is record
    p_model : python_object_t;
  end record;

  -- A Counter of its own, with the identity of the VC
  impure function new_counter_vc(step : natural := 1; id : id_t := null_id) return counter_vc_t;
  -- A given model, e.g. shared with other VCs or the testbench
  impure function new_counter_vc(model : python_object_t) return counter_vc_t;
end package;

package body counter_vc_pkg is
  impure function new_counter_vc(step : natural := 1; id : id_t := null_id) return counter_vc_t is
  begin
    return (p_model => new_python_object("models.counter_model.Counter", kwarg("step", step), id));
  end;

  impure function new_counter_vc(model : python_object_t) return counter_vc_t is
  begin
    return (p_model => model);
  end;
end package body;
