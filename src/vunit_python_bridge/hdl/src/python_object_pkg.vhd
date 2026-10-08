-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- PROTOTYPE: Python objects owned by VHDL. An object is an instance of a
-- Python class living in a session of its own, created on first use.

library vunit_lib;
use vunit_lib.dict_pkg.all;
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

  -- An instance of class_name ("package.module.Class", "package.module:Class",
  -- or "Class" defined in the default session) created with args on first use.
  -- The identity names the object and its session; it gets a unique one when
  -- none is given. Two objects with the same identity are an error.
  impure function new_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t;

  -- object when it is given, else a new object: the default backend of a
  -- verification component that can also be given one
  impure function object_or_new(
    object : python_object_t; class_name : string; args : arg_t := null_arg; id : id_t := null_id
  ) return python_object_t;

  impure function get_id(object : python_object_t) return id_t;
  -- The session of the object, in which it is bound to self
  impure function get_session(object : python_object_t) return python_session_t;

  -- Create the object now rather than on first use
  procedure create(object : python_object_t);

  impure function call_integer(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return integer;
  alias call is call_integer[python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer];
  impure function call_real(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return real;
  alias call is call_real[python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return real];
  impure function call_string(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return string;
  alias call is call_string[python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return string];
  impure function call_boolean(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return boolean;
  alias call is call_boolean[python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return boolean];
  impure function call_integer_vector(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return integer_vector;
  alias call is call_integer_vector[python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer_vector];
  procedure call(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg);

  -- Evaluate an expression in the session of the object, where it is self
  impure function eval_integer(object : python_object_t; expr : string) return integer;
  impure function eval_string(object : python_object_t; expr : string) return string;

  procedure p_create(object : python_object_t);
  function p_self(method : string) return string;
end package;

package body python_object_pkg is
  constant session_idx : natural := 0;
  constant code_idx : natural := 1;
  constant created_idx : natural := 2;
  constant num_anonymous : integer_vector_ptr_t := new_integer_vector_ptr(1);
  -- The identities of the objects, by full name
  constant identities : dict_t := new_dict;

  impure function new_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t is
    variable object_id : id_t := id;
    variable data : integer_vector_ptr_t := new_integer_vector_ptr(3);
  begin
    if object_id = null_id then
      object_id := get_id("object_" & integer'image(get(num_anonymous, 0)), parent => p_python_id);
      set(num_anonymous, 0, get(num_anonymous, 0) + 1);
    end if;
    if has_key(identities, full_name(object_id)) then
      failure(
        get_logger(object_id),
        "Two Python objects have the identity " & full_name(object_id) & ", give each one an id of its own"
      );
    end if;
    set_string(identities, full_name(object_id), "");
    set(data, session_idx, to_integer(new_session(object_id).p_data));
    set(data, code_idx, to_integer(new_string_ptr(to_call_str("__vunit__.create", arg(class_name), args))));
    return (p_data => data);
  end;

  impure function object_or_new(
    object : python_object_t; class_name : string; args : arg_t := null_arg; id : id_t := null_id
  ) return python_object_t is
  begin
    if object /= null_python_object then
      return object;
    end if;
    return new_object(class_name, args, id);
  end;

  impure function get_session(object : python_object_t) return python_session_t is
  begin
    return (p_data => to_integer_vector_ptr(get(object.p_data, session_idx)));
  end;

  impure function get_id(object : python_object_t) return id_t is
  begin
    return get_id(get_session(object));
  end;

  procedure p_create(object : python_object_t) is
  begin
    if get(object.p_data, created_idx) = 0 then
      set(object.p_data, created_idx, 1);
      exec(to_string(to_string_ptr(get(object.p_data, code_idx))), get_session(object));
    end if;
  end;

  procedure create(object : python_object_t) is
  begin
    p_create(object);
  end;

  function p_self(method : string) return string is
  begin
    return "self." & method;
  end;

  impure function call_integer(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return integer is
  begin
    p_create(object);
    return call_integer_w_arg(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;
  impure function call_real(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return real is
  begin
    p_create(object);
    return call_real(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;
  impure function call_string(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return string is
  begin
    p_create(object);
    return call_string(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;
  impure function call_boolean(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return boolean is
  begin
    p_create(object);
    return call_boolean(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;
  impure function call_integer_vector(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) return integer_vector is
  begin
    p_create(object);
    return call_integer_vector(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;
  procedure call(object : python_object_t; method : string; arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg) is
  begin
    p_create(object);
    call(p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object));
  end;

  impure function eval_integer(object : python_object_t; expr : string) return integer is
  begin
    p_create(object);
    return eval_integer(expr, get_session(object));
  end;

  impure function eval_string(object : python_object_t; expr : string) return string is
  begin
    p_create(object);
    return eval_string(expr, get_session(object));
  end;
end package body;
