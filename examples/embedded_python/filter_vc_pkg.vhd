-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- The handle of filter_vc. Like the handles of VUnit's verification
-- components, it is made by its constructor during elaboration, here together
-- with the Python object that is the behaviour of the component.

library vunit_lib;
context vunit_lib.vunit_context;

library python_bridge;
context python_bridge.python_context;

package filter_vc_pkg is
  type filter_vc_t is record
    p_model : python_object_t;
  end record;

  -- A MovingAverage of its own, named by id
  impure function new_filter_vc(window : positive := 2; id : id_t := null_id) return filter_vc_t;
  -- A model given by the testbench, e.g. shared with it
  impure function new_filter_vc(model : python_object_t) return filter_vc_t;
end package;

package body filter_vc_pkg is
  impure function new_filter_vc(window : positive := 2; id : id_t := null_id) return filter_vc_t is
  begin
    return (p_model => new_python_object("filter_model.MovingAverage", kwarg("window", window), id));
  end;

  impure function new_filter_vc(model : python_object_t) return filter_vc_t is
  begin
    return (p_model => model);
  end;
end package body;
