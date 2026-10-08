-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
--
-- PROTOTYPE: Python objects owned by VHDL. An object is an instance of a
-- Python class living in a session of its own, created on first use.
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

  -- An instance of class_name ("package.module.Class", "package.module:Class",
  -- or "Class" defined in the default session) created with args on first use.
  -- The identity names the object and its session. Without one, objects are
  -- enumerated like VUnit's verification components: python_bridge:python:object:<n>.
  -- Two objects with the same identity are an error.
  impure function new_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t;

  -- object when it is given, else a new object, like get_logger and get_id:
  -- the default backend of a verification component that can also be given one
  impure function get_python_object(
    object : python_object_t; class_name : string; args : arg_t := null_arg; id : id_t := null_id
  ) return python_object_t;

  impure function get_id(object : python_object_t) return id_t;
  -- The session of the object, in which it is bound to self
  impure function get_session(object : python_object_t) return python_session_t;

  -- Create the object now rather than on first use
  procedure create(object : python_object_t);

  -- Call a method of the object, like call
  procedure call(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  );

  impure function call_integer_w_arg(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer;
  alias call is call_integer_w_arg[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer];

  impure function call_real(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real;
  alias call is call_real[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return real];

  impure function call_integer_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector;
  alias call is call_integer_vector[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer_vector];

  impure function call_real_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real_vector;
  alias call is call_real_vector[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return real_vector];

  impure function call_string(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return string;
  alias call is call_string[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return string];

  impure function call_integer_vector_ptr(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector_ptr_t;
  alias call is call_integer_vector_ptr[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer_vector_ptr_t];

  impure function call_boolean(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return boolean;
  alias call is call_boolean[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return boolean];

  impure function call_std_ulogic(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic;
  alias call is call_std_ulogic[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return std_ulogic];

  impure function call_std_ulogic_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic_vector;

  impure function call_integer_array(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_array_t;
  alias call is call_integer_array[
    python_object_t, string, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t, arg_t return integer_array_t];

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

  procedure p_create(object : python_object_t);
  function p_self(method : string) return string;
end package;

package body python_object_pkg is
  constant session_idx : natural := 0;
  constant code_idx : natural := 1;
  constant created_idx : natural := 2;
  -- The parent of the identities of the objects created without one
  constant anonymous_id : id_t := get_id("object", parent => p_python_id);
  -- The identities of the objects, by full name
  constant identities : dict_t := new_dict;

  impure function new_python_object(class_name : string; args : arg_t := null_arg; id : id_t := null_id)
    return python_object_t is
    variable object_id : id_t := id;
    variable data : integer_vector_ptr_t := new_integer_vector_ptr(3);
  begin
    if object_id = null_id then
      -- Like enumerate of vc_pkg, which is only there with the verification components
      object_id := get_id(to_string(num_children(anonymous_id) + 1), parent => anonymous_id);
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

  impure function get_python_object(
    object : python_object_t; class_name : string; args : arg_t := null_arg; id : id_t := null_id
  ) return python_object_t is
  begin
    if object /= null_python_object then
      return object;
    end if;
    return new_python_object(class_name, args, id);
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

  procedure call(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    p_create(object);
    call(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_integer_w_arg(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer is
  begin
    p_create(object);
    return call_integer_w_arg(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_real(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real is
  begin
    p_create(object);
    return call_real(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_integer_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector is
  begin
    p_create(object);
    return call_integer_vector(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_real_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return real_vector is
  begin
    p_create(object);
    return call_real_vector(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_string(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return string is
  begin
    p_create(object);
    return call_string(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_integer_vector_ptr(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_vector_ptr_t is
  begin
    p_create(object);
    return call_integer_vector_ptr(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_boolean(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return boolean is
  begin
    p_create(object);
    return call_boolean(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_std_ulogic(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic is
  begin
    p_create(object);
    return call_std_ulogic(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_std_ulogic_vector(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return std_ulogic_vector is
  begin
    p_create(object);
    return call_std_ulogic_vector(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function call_integer_array(
    object : python_object_t; method : string;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) return integer_array_t is
  begin
    p_create(object);
    return call_integer_array(
      p_self(method), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  procedure call_std_ulogic_vector(
    object : python_object_t; method : string; result : out std_ulogic_vector;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    p_create(object);
    call_std_ulogic_vector(
      p_self(method), result,
      arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  procedure call_signed(
    object : python_object_t; method : string; result : out signed;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    p_create(object);
    call_signed(
      p_self(method), result,
      arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  procedure call_unsigned(
    object : python_object_t; method : string; result : out unsigned;
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 : arg_t := null_arg
  ) is
  begin
    p_create(object);
    call_unsigned(
      p_self(method), result,
      arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, session => get_session(object)
    );
  end;

  impure function eval_integer(object : python_object_t; expr : string) return integer is
  begin
    p_create(object);
    return eval_integer(expr, session => get_session(object));
  end;

  impure function eval_real(object : python_object_t; expr : string) return real is
  begin
    p_create(object);
    return eval_real(expr, session => get_session(object));
  end;

  impure function eval_integer_vector(object : python_object_t; expr : string) return integer_vector is
  begin
    p_create(object);
    return eval_integer_vector(expr, session => get_session(object));
  end;

  impure function eval_real_vector(object : python_object_t; expr : string) return real_vector is
  begin
    p_create(object);
    return eval_real_vector(expr, session => get_session(object));
  end;

  impure function eval_string(object : python_object_t; expr : string) return string is
  begin
    p_create(object);
    return eval_string(expr, session => get_session(object));
  end;

  impure function eval_integer_vector_ptr(object : python_object_t; expr : string) return integer_vector_ptr_t is
  begin
    p_create(object);
    return eval_integer_vector_ptr(expr, session => get_session(object));
  end;

  impure function eval_boolean(object : python_object_t; expr : string) return boolean is
  begin
    p_create(object);
    return eval_boolean(expr, session => get_session(object));
  end;

  impure function eval_std_ulogic(object : python_object_t; expr : string) return std_ulogic is
  begin
    p_create(object);
    return eval_std_ulogic(expr, session => get_session(object));
  end;

  impure function eval_std_ulogic_vector(object : python_object_t; expr : string) return std_ulogic_vector is
  begin
    p_create(object);
    return eval_std_ulogic_vector(expr, session => get_session(object));
  end;

  impure function eval_integer_array(object : python_object_t; expr : string) return integer_array_t is
  begin
    p_create(object);
    return eval_integer_array(expr, session => get_session(object));
  end;

  procedure eval_std_ulogic_vector(object : python_object_t; expr : string; result : out std_ulogic_vector) is
  begin
    p_create(object);
    eval_std_ulogic_vector(expr, result, session => get_session(object));
  end;

  procedure eval_signed(object : python_object_t; expr : string; result : out signed) is
  begin
    p_create(object);
    eval_signed(expr, result, session => get_session(object));
  end;

  procedure eval_unsigned(object : python_object_t; expr : string; result : out unsigned) is
  begin
    p_create(object);
    eval_unsigned(expr, result, session => get_session(object));
  end;
end package body;
