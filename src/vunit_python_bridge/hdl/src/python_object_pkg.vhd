-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- Python objects owned by VHDL. An object is an instance of a Python class
-- living in a session of its own, where it is self, created on first use. It
-- is typically the backend of a verification component, see "Python objects"
-- in the user guide.
--
-- The call and eval overloads of an object are those of python_pkg with the
-- object first, generated from the same result tables.
--
-- This file is generated from tools/python_object_pkg.vhd.in by
-- src/vunit_python_bridge/hdl/tools/generate_python_pkg.py. Do not edit.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
use vunit_lib.dict_pkg.all;
use vunit_lib.integer_array_pkg.all;
use vunit_lib.id_pkg.all;
use vunit_lib.logger_pkg.all;
use vunit_lib.integer_vector_ptr_pkg.all;
use vunit_lib.string_ptr_pkg.all;

use work.python_ffi_pkg.all;
use work.python_pkg.all;

package python_object_pkg is
  type python_object_t is record
    p_data : integer_vector_ptr_t;
  end record;
  constant null_python_object : python_object_t := (p_data => null_ptr);

  -- An instance of class_name, a dotted name like "package.module.Class" or the
  -- name of a class defined in the default session, constructed with args on first use.
  -- The identity names the object and its session. Without one, objects are
  -- enumerated like VUnit's verification components: python_bridge:python:object:<n>.
  -- An identity already used by an object or a session is reported as a failure
  -- on the logger of the identity, and null_python_object is returned.
  impure function new_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t;
  -- The identity given by its full name, like get_logger(name)
  impure function new_python_object(class_name : string; args : arg_t := null_arg; name : string)
    return python_object_t;

  -- Like new_python_object, but the object is constructed by this call rather
  -- than on first use, so a wrong class or constructor argument is reported here.
  -- Only in a process: Python cannot run during elaboration, so a constant or a
  -- generic is made with new_python_object.
  impure function create_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t;
  impure function create_python_object(class_name : string; args : arg_t := null_arg; name : string)
    return python_object_t;

  -- The object made with the identity, or with the identity of the full name.
  -- Unlike get_logger, it does not make one: an identity without an object is
  -- reported as a failure on python_logger, and null_python_object is returned.
  impure function get_python_object(id : id_t) return python_object_t;
  impure function get_python_object(name : string) return python_object_t;

  impure function get_id(object : python_object_t) return id_t;
  -- The logger of the object, which reports the errors of its operations
  impure function get_logger(object : python_object_t) return logger_t;
  -- The session of the object, in which it is bound to self
  impure function get_session(object : python_object_t) return python_session_t;

  -- Execute code in the session of the object, where it is self, like exec
  procedure exec(object : python_object_t; code : string);

  -- Call a method of the object
  procedure call(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  );

  impure function call_integer_w_arg(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer;
  alias call is call_integer_w_arg[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return integer];

  impure function call_real(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real;
  alias call is call_real[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return real];

  impure function call_integer_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector;
  alias call is call_integer_vector[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return integer_vector];

  impure function call_real_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real_vector;
  alias call is call_real_vector[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return real_vector];

  impure function call_string(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return string;
  alias call is call_string[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return string];

  impure function call_integer_vector_ptr(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector_ptr_t;
  alias call is call_integer_vector_ptr[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return integer_vector_ptr_t];

  impure function call_boolean(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return boolean;
  alias call is call_boolean[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return boolean];

  impure function call_std_ulogic(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic;
  alias call is call_std_ulogic[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return std_ulogic];

  impure function call_std_ulogic_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic_vector;

  impure function call_integer_array(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_array_t;
  alias call is call_integer_array[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t,
    arg_t, arg_t, arg_t, arg_t, arg_t return integer_array_t];

  procedure call_std_ulogic_vector(
    object : python_object_t; method : string; result : out std_ulogic_vector;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  );
  procedure call_signed(
    object : python_object_t; method : string; result : out signed;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  );
  procedure call_unsigned(
    object : python_object_t; method : string; result : out unsigned;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  );

  -- Evaluate an expression in the session of the object, where it is self, like eval
  impure function eval_integer(object : python_object_t; expr : string) return integer;
  alias eval is eval_integer[python_object_t, string return integer];
  impure function eval_real(object : python_object_t; expr : string) return real;
  alias eval is eval_real[python_object_t, string return real];
  impure function eval_integer_vector(object : python_object_t; expr : string) return integer_vector;
  alias eval is eval_integer_vector[python_object_t, string return integer_vector];
  impure function eval_real_vector(object : python_object_t; expr : string) return real_vector;
  alias eval is eval_real_vector[python_object_t, string return real_vector];
  impure function eval_string(object : python_object_t; expr : string) return string;
  alias eval is eval_string[python_object_t, string return string];
  impure function eval_integer_vector_ptr(object : python_object_t; expr : string) return integer_vector_ptr_t;
  alias eval is eval_integer_vector_ptr[python_object_t, string return integer_vector_ptr_t];
  impure function eval_boolean(object : python_object_t; expr : string) return boolean;
  alias eval is eval_boolean[python_object_t, string return boolean];
  impure function eval_std_ulogic(object : python_object_t; expr : string) return std_ulogic;
  alias eval is eval_std_ulogic[python_object_t, string return std_ulogic];
  impure function eval_std_ulogic_vector(object : python_object_t; expr : string) return std_ulogic_vector;
  impure function eval_integer_array(object : python_object_t; expr : string) return integer_array_t;
  procedure eval_std_ulogic_vector(object : python_object_t; expr : string; result : out std_ulogic_vector);
  procedure eval_signed(object : python_object_t; expr : string; result : out signed);
  procedure eval_unsigned(object : python_object_t; expr : string; result : out unsigned);
end package;

package body python_object_pkg is
  constant session_idx : natural := 0;
  constant code_idx : natural := 1;
  constant created_idx : natural := 2;
  constant operation_idx : natural := 3;
  -- The parent of the identities of the objects created without one
  constant anonymous_id : id_t := get_id("object", parent => p_python_id);

  -- The defaults of the call results of a failed call
  constant p_no_integers : integer_vector(0 downto 1) := (others => 0);
  constant p_no_reals : real_vector(0 downto 1) := (others => 0.0);

  impure function p_to_integer_vector_ptr(values : integer_vector) return integer_vector_ptr_t is
    constant normalized : integer_vector(0 to values'length - 1) := values;
    constant result : integer_vector_ptr_t := new_integer_vector_ptr(values'length);
  begin
    for idx in normalized'range loop
      set(result, idx, normalized(idx));
    end loop;
    return result;
  end;

  -- The objects by the full names of their identities, as integers of their p_data
  constant p_objects : dict_t := new_dict;

  -- new_python_object and create_python_object, operation naming the one called
  impure function p_new_python_object(class_name : string; args : arg_t; id : id_t; operation : string)
    return python_object_t is
    variable object_id : id_t := id;
    variable data : integer_vector_ptr_t;
  begin
    if object_id = null_id then
      -- Like enumerate of vc_pkg, which is only there with the verification components
      object_id := get_id(to_string(num_children(anonymous_id) + 1), parent => anonymous_id);
    end if;
    -- The session of the object is that of its identity, which must be its own
    if p_has_session(object_id) then
      failure(
        get_logger(object_id),
        operation & " failed:" & LF & "The identity " & full_name(object_id) &
        " is already used by another Python object or session, give each object an id of its own."
      );
      return null_python_object;
    end if;
    data := new_integer_vector_ptr(4);
    set(data, session_idx, to_integer(new_session(object_id).p_data));
    set(data, code_idx, to_integer(new_string_ptr(
      to_call_str("__vunit__.instantiate_as_self", arg(class_name), args)
    )));
    set(data, operation_idx, to_integer(new_string_ptr(operation)));
    set_string(p_objects, full_name(object_id), integer'image(to_integer(data)));
    return (p_data => data);
  end;

  impure function new_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t is
  begin
    return p_new_python_object(class_name, args, id, "new_python_object(""" & class_name & """)");
  end;

  impure function new_python_object(class_name : string; args : arg_t := null_arg; name : string)
    return python_object_t is
  begin
    return new_python_object(class_name, args, get_id(name));
  end;

  procedure p_no_object(name : string) is
  begin
    failure(
      python_logger,
      "get_python_object(""" & name & """) failed:" & LF & "No Python object has the identity " & name &
      ". Make it with new_python_object or create_python_object before getting it."
    );
  end;

  impure function get_python_object(id : id_t) return python_object_t is
  begin
    if id = null_id then
      p_no_object("null_id");
      return null_python_object;
    end if;
    if not has_key(p_objects, full_name(id)) then
      p_no_object(full_name(id));
      return null_python_object;
    end if;
    return (p_data => to_integer_vector_ptr(integer'value(get_string(p_objects, full_name(id)))));
  end;

  impure function get_python_object(name : string) return python_object_t is
  begin
    -- has_id first: get_id would make the identity of a wrong name
    if not has_id(name) then
      p_no_object(name);
      return null_python_object;
    end if;
    return get_python_object(get_id(name));
  end;

  -- Report the use of null_python_object, e.g. the result of a failed new_python_object
  impure function p_is_null(object : python_object_t) return boolean is
  begin
    if object = null_python_object then
      failure(python_logger, "null_python_object was used, it is not an object");
      return true;
    end if;
    return false;
  end;

  -- The session of null_python_object, where nothing is bound to self
  constant null_session : python_session_t := new_session(get_id("null_object", parent => p_python_id));

  impure function get_session(object : python_object_t) return python_session_t is
  begin
    if p_is_null(object) then
      return null_session;
    end if;
    return (p_data => to_integer_vector_ptr(get(object.p_data, session_idx)));
  end;

  impure function get_id(object : python_object_t) return id_t is
  begin
    return get_id(get_session(object));
  end;

  -- Construct the object unless it is constructed. A failure is reported once, as
  -- the failure of new_python_object or create_python_object, and the object
  -- then raises it on every use.
  procedure p_create(object : python_object_t) is
    variable ok : boolean;
  begin
    if p_is_null(object) then
      return;
    end if;
    if get(object.p_data, created_idx) = 0 then
      set(object.p_data, created_idx, 1);
      ok := p_exec(
        to_string(to_string_ptr(get(object.p_data, code_idx))), 0,
        to_string(to_string_ptr(get(object.p_data, operation_idx))),
        get_session(object)
      );
    end if;
  end;

  impure function create_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t is
    constant object : python_object_t :=
      p_new_python_object(class_name, args, id, "create_python_object(""" & class_name & """)");
  begin
    if object /= null_python_object then
      p_create(object);
    end if;
    return object;
  end;

  impure function create_python_object(class_name : string; args : arg_t := null_arg; name : string)
    return python_object_t is
  begin
    return create_python_object(class_name, args, get_id(name));
  end;

  -- Create the object if needed. False for null_python_object, which is reported.
  impure function p_created(object : python_object_t) return boolean is
  begin
    if object = null_python_object then
      return not p_is_null(object);
    end if;
    p_create(object);
    return true;
  end;

  procedure exec(object : python_object_t; code : string) is
  begin
    if p_created(object) then
      exec(code, get_session(object));
    end if;
  end;

  impure function get_logger(object : python_object_t) return logger_t is
  begin
    return get_logger(get_id(object));
  end;

  -- The name of a method call in error messages
  function p_call_operation(method : string) return string is
  begin
    return "call(""" & method & """)";
  end;

  procedure call(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
    variable ok : boolean;
  begin
    if not p_created(object) then
      return;
    end if;
    -- An error is reported as that of the method rather than of the code executed
    ok := p_exec(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      0, p_call_operation(method), get_session(object)
    );
  end;

  impure function call_integer_w_arg(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer is
  begin
    if not p_created(object) then
      return integer'low;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_integer, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_integer;
    end if;
    return integer'low;
  end;

  impure function call_real(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real is
  begin
    if not p_created(object) then
      return 0.0;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_real, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_real;
    end if;
    return 0.0;
  end;

  impure function call_integer_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector is
  begin
    if not p_created(object) then
      return p_no_integers;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_integer_vector, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_integer_vector;
    end if;
    return p_no_integers;
  end;

  impure function call_real_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real_vector is
  begin
    if not p_created(object) then
      return p_no_reals;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_real_vector, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_real_vector;
    end if;
    return p_no_reals;
  end;

  impure function call_string(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return string is
  begin
    if not p_created(object) then
      return "";
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_string, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_string;
    end if;
    return "";
  end;

  impure function call_integer_vector_ptr(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector_ptr_t is
  begin
    if not p_created(object) then
      return null_ptr;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_integer_vector, -1, p_call_operation(method), get_session(object)
    ) then
      return p_to_integer_vector_ptr(p_result_integer_vector);
    end if;
    return null_ptr;
  end;

  impure function call_boolean(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return boolean is
  begin
    if not p_created(object) then
      return false;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_boolean, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_integer /= 0;
    end if;
    return false;
  end;

  impure function call_std_ulogic(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic is
  begin
    if not p_created(object) then
      return 'U';
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_std_ulogic, -1, p_call_operation(method), get_session(object)
    ) then
      return p_to_std_ulogic(p_result_string(1));
    end if;
    return 'U';
  end;

  impure function call_std_ulogic_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic_vector is
  begin
    if not p_created(object) then
      return "";
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_std_ulogic_vector, -1, p_call_operation(method), get_session(object)
    ) then
      return p_to_std_ulogic_vector(p_result_string);
    end if;
    return "";
  end;

  impure function call_integer_array(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_array_t is
  begin
    if not p_created(object) then
      return null_integer_array;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_integer_array, -1, p_call_operation(method), get_session(object)
    ) then
      return p_result_integer_array;
    end if;
    return null_integer_array;
  end;

  procedure call_std_ulogic_vector(
    object : python_object_t; method : string; result : out std_ulogic_vector;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    if not p_created(object) then
      return;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_std_ulogic_vector, result'length, p_call_operation(method), get_session(object)
    ) then
      result := p_to_std_ulogic_vector(p_result_string);
    end if;
  end;

  procedure call_signed(
    object : python_object_t; method : string; result : out signed;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    if not p_created(object) then
      return;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_signed, result'length, p_call_operation(method), get_session(object)
    ) then
      result := signed(p_to_std_ulogic_vector(p_result_string));
    end if;
  end;

  procedure call_unsigned(
    object : python_object_t; method : string; result : out unsigned;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    if not p_created(object) then
      return;
    end if;
    if p_eval(
      to_call_str("self." & method, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10),
      p_kind_unsigned, result'length, p_call_operation(method), get_session(object)
    ) then
      result := unsigned(p_to_std_ulogic_vector(p_result_string));
    end if;
  end;

  impure function eval_integer(object : python_object_t; expr : string) return integer is
  begin
    if not p_created(object) then
      return integer'low;
    end if;
    return eval_integer(expr, session => get_session(object));
  end;

  impure function eval_real(object : python_object_t; expr : string) return real is
  begin
    if not p_created(object) then
      return 0.0;
    end if;
    return eval_real(expr, session => get_session(object));
  end;

  impure function eval_integer_vector(object : python_object_t; expr : string) return integer_vector is
  begin
    if not p_created(object) then
      return p_no_integers;
    end if;
    return eval_integer_vector(expr, session => get_session(object));
  end;

  impure function eval_real_vector(object : python_object_t; expr : string) return real_vector is
  begin
    if not p_created(object) then
      return p_no_reals;
    end if;
    return eval_real_vector(expr, session => get_session(object));
  end;

  impure function eval_string(object : python_object_t; expr : string) return string is
  begin
    if not p_created(object) then
      return "";
    end if;
    return eval_string(expr, session => get_session(object));
  end;

  impure function eval_integer_vector_ptr(object : python_object_t; expr : string) return integer_vector_ptr_t is
  begin
    if not p_created(object) then
      return null_ptr;
    end if;
    return eval_integer_vector_ptr(expr, session => get_session(object));
  end;

  impure function eval_boolean(object : python_object_t; expr : string) return boolean is
  begin
    if not p_created(object) then
      return false;
    end if;
    return eval_boolean(expr, session => get_session(object));
  end;

  impure function eval_std_ulogic(object : python_object_t; expr : string) return std_ulogic is
  begin
    if not p_created(object) then
      return 'U';
    end if;
    return eval_std_ulogic(expr, session => get_session(object));
  end;

  impure function eval_std_ulogic_vector(object : python_object_t; expr : string) return std_ulogic_vector is
  begin
    if not p_created(object) then
      return "";
    end if;
    return eval_std_ulogic_vector(expr, session => get_session(object));
  end;

  impure function eval_integer_array(object : python_object_t; expr : string) return integer_array_t is
  begin
    if not p_created(object) then
      return null_integer_array;
    end if;
    return eval_integer_array(expr, session => get_session(object));
  end;

  procedure eval_std_ulogic_vector(object : python_object_t; expr : string; result : out std_ulogic_vector) is
  begin
    if not p_created(object) then
      return;
    end if;
    eval_std_ulogic_vector(expr, result, session => get_session(object));
  end;

  procedure eval_signed(object : python_object_t; expr : string; result : out signed) is
  begin
    if not p_created(object) then
      return;
    end if;
    eval_signed(expr, result, session => get_session(object));
  end;

  procedure eval_unsigned(object : python_object_t; expr : string; result : out unsigned) is
  begin
    if not p_created(object) then
      return;
    end if;
    eval_unsigned(expr, result, session => get_session(object));
  end;
end package body;
