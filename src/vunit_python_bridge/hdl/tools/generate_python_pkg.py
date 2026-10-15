# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Generate python_pkg.vhd and python_object_pkg.vhd from the templates in this directory.

Each template holds the parts of its package that are written by hand. The
generated parts of python_pkg are the argument value types of call, the result
types of eval and call and the execution of Python files. Those of
python_object_pkg are the call and eval overloads of a python_object_t, from the
same result tables. They are mostly one overload per type, which is why they are
generated. The operations that are implemented by the Python bridge (NVC, GHDL
and Questa) are built on the p_ prefixed primitives of python_ffi_pkg, which the
VHPI variant of that package implements by reporting a failure.
"""

from pathlib import Path
from string import Template

SRC_PATH = Path(__file__).parent.parent / "src"
TEMPLATE_PATH = Path(__file__).parent

# Like the operations of python_pkg, every operation takes the session it is
# performed in as its last parameter
SESSION = "session : python_session_t := default_session"

# The 10 arguments of call
ARGS = [f"arg{index}" for index in range(1, 11)]
ARG_PARAMETERS = f"{', '.join(ARGS)} : arg_t := null_arg"
ARG_ACTUALS = ", ".join(ARGS)
ARG_SIGNATURE = ", ".join(["string"] + ["arg_t"] * len(ARGS) + ["python_session_t"])

# Value types of arg and kwarg that are generated rather than declared in the
# template.
#
# vhdl:   the VHDL type
# impure: true when the functions must be impure
# fails:  true when the conversion can fail, which makes p_arg_value take the
#         name of the operation to report the value it cannot convert
# suffix: appended to the arg and kwarg names, empty for an overload
#
# The integer_array_t value is transferred by the Python bridge, which makes it
# available for NVC, GHDL and Questa only. The other values are built from the
# Python source text of the value alone and work on any simulator.
#
# The unsigned and signed values are passed to typed names, arg_unsigned and
# arg_signed, on purpose: plain overloads would make a string literal
# argument, arg("Hello"), ambiguous since a string literal belongs to every
# character array type. std_ulogic needs no such name, being a scalar, and
# std_ulogic_vector is deliberately not among the types at all. Such values
# are passed as arg(to_string(slv)) and arg_unsigned(unsigned(slv)).
ARG_VALUES = [
    dict(vhdl="real_vector", impure=False, fails=False, suffix=""),
    dict(vhdl="integer_vector_ptr_t", impure=True, fails=False, suffix=""),
    dict(vhdl="std_ulogic", impure=True, fails=True, suffix=""),
    dict(vhdl="unsigned", impure=True, fails=True, suffix="_unsigned"),
    dict(vhdl="signed", impure=True, fails=True, suffix="_signed"),
    dict(vhdl="integer_array_t", impure=True, fails=True, suffix=""),
]

# Result types of eval and call.
#
# name:     suffix of eval_<name> and call_<name>
# vhdl:     the VHDL type
# kind:     result kind passed to the bridge, see src/vunit_python_bridge/runtime.py
# value:    expression giving the result of a successful evaluation
# default:  value returned after a failure
# hand_written_eval/hand_written_call: true when the eval/call function is
#           declared in the template rather than generated. value and default
#           are only needed when the eval function is generated.
RESULTS = [
    dict(
        name="integer",
        vhdl="integer",
        kind="p_kind_integer",
        value="p_result_integer",
        default="integer'low",
        hand_written_eval=True,
        hand_written_call=True,
    ),
    dict(
        name="real",
        vhdl="real",
        kind="p_kind_real",
        value="p_result_real",
        default="0.0",
        hand_written_eval=True,
        hand_written_call=True,
    ),
    dict(
        name="integer_vector",
        vhdl="integer_vector",
        kind="p_kind_integer_vector",
        value="p_result_integer_vector",
        default="p_no_integers",
        hand_written_eval=True,
        hand_written_call=True,
    ),
    dict(
        name="real_vector",
        vhdl="real_vector",
        kind="p_kind_real_vector",
        value="p_result_real_vector",
        default="p_no_reals",
        hand_written_eval=True,
        hand_written_call=False,
    ),
    dict(
        name="string",
        vhdl="string",
        kind="p_kind_string",
        value="p_result_string",
        default='""',
        hand_written_eval=True,
        hand_written_call=False,
    ),
    dict(
        name="integer_vector_ptr",
        vhdl="integer_vector_ptr_t",
        kind="p_kind_integer_vector",
        value="p_to_integer_vector_ptr(p_result_integer_vector)",
        default="null_ptr",
        hand_written_eval=True,
        hand_written_call=False,
    ),
    dict(
        name="boolean",
        vhdl="boolean",
        kind="p_kind_boolean",
        value="p_result_integer /= 0",
        default="false",
        hand_written_eval=False,
        hand_written_call=False,
    ),
    dict(
        name="std_ulogic",
        vhdl="std_ulogic",
        kind="p_kind_std_ulogic",
        value="p_to_std_ulogic(p_result_string(1))",
        default="'U'",
        hand_written_eval=False,
        hand_written_call=False,
    ),
    dict(
        name="std_ulogic_vector",
        vhdl="std_ulogic_vector",
        kind="p_kind_std_ulogic_vector",
        value="p_to_std_ulogic_vector(p_result_string)",
        default='""',
        hand_written_eval=False,
        hand_written_call=False,
        # No eval/call alias: check_equal(eval("17"), 17) would otherwise be ambiguous
        # with check_equal(std_ulogic_vector, natural). Use the explicit names.
        alias_eval=False,
        alias_call=False,
    ),
    dict(
        name="integer_array",
        vhdl="integer_array_t",
        kind="p_kind_integer_array",
        value="p_result_integer_array",
        default="null_integer_array",
        hand_written_eval=False,
        hand_written_call=False,
        # No eval alias: length(eval(...)) would otherwise be ambiguous between
        # the integer_array_t and integer_vector_ptr_t results. Use eval_integer_array.
        alias_eval=False,
    ),
]

# Result types whose width is given by the actual of the result parameter
PROCEDURE_RESULTS = [
    dict(
        name="std_ulogic_vector",
        vhdl="std_ulogic_vector",
        kind="p_kind_std_ulogic_vector",
        value="p_to_std_ulogic_vector(p_result_string)",
    ),
    dict(
        name="signed",
        vhdl="signed",
        kind="p_kind_signed",
        value="signed(p_to_std_ulogic_vector(p_result_string))",
    ),
    dict(
        name="unsigned",
        vhdl="unsigned",
        kind="p_kind_unsigned",
        value="unsigned(p_to_std_ulogic_vector(p_result_string))",
    ),
]


def call_name(result):
    """
    Name of the call function of a result type. The integer one is named
    call_integer_w_arg by python_pkg.
    """
    return "call_integer_w_arg" if result["name"] == "integer" else f"call_{result['name']}"


def call_aliases(result):
    """
    Aliases of the call function of a result type: call, and call_integer for
    call_integer_w_arg, named like the other results, as in python_pkg.vhd.in.
    """
    aliases = ["call"] if result.get("alias_call", True) else []
    return aliases + (["call_integer"] if result["name"] == "integer" else [])


# -------------------------------------------------------------------------
# arg and kwarg
# -------------------------------------------------------------------------
def arg_declarations():
    """
    Declarations of the generated arg and kwarg subprograms.
    """
    lines = []
    for value in ARG_VALUES:
        purity = "impure " if value["impure"] else ""
        suffix = value["suffix"]
        lines.append(f"  {purity}function arg{suffix}(value : {value['vhdl']}) return arg_t;")
        lines.append(f"  {purity}function kwarg{suffix}(kw : string; value : {value['vhdl']}) return arg_t;")
    return "\n".join(lines)


def arg_functions():
    """
    Bodies of the generated arg and kwarg subprograms. p_arg_value reports a
    value it cannot convert and gives it a Python source text raising the same
    message, so that the call the argument is used in fails as well.
    """
    parts = []
    for value in ARG_VALUES:
        purity = "impure " if value["impure"] else ""
        value_type = value["vhdl"]
        suffix = value["suffix"]
        for name, parameters, target in [
            (f"arg{suffix}", f"value : {value_type}", "p_positional_arg"),
            (f"kwarg{suffix}", f"kw : string; value : {value_type}", "kw"),
        ]:
            arg_value = f'p_arg_value(value, "{name}")' if value["fails"] else "p_arg_value(value)"
            parts.append(
                f"""\
  {purity}function {name}({parameters}) return arg_t is
  begin
    return ({target}, {arg_value});
  end;
"""
            )
    return "\n".join(parts).rstrip("\n")


# -------------------------------------------------------------------------
# eval
# -------------------------------------------------------------------------
def eval_declarations():
    """
    Declarations of the generated eval functions and of the eval procedures.
    """
    lines = []
    for result in RESULTS:
        if result["hand_written_eval"]:
            continue
        lines.append(f"  impure function eval_{result['name']}(")
        lines.append(f"    expr : string; {SESSION}")
        lines.append(f"  ) return {result['vhdl']};")
        if result.get("alias_eval", True):
            lines.append(f"  alias eval is eval_{result['name']}[string, python_session_t return {result['vhdl']}];")
        lines.append("")
    for result in PROCEDURE_RESULTS:
        lines.append(f"  procedure eval_{result['name']}(")
        lines.append(f"    expr : string; result : out {result['vhdl']}; {SESSION}")
        lines.append("  );")
    return "\n".join(lines)


def eval_subprograms():
    """
    Bodies of the generated eval functions and of the eval procedures.
    """
    parts = []
    for result in RESULTS:
        if result["hand_written_eval"]:
            continue
        parts.append(
            f"""\
  impure function eval_{result['name']}(
    expr : string; {SESSION}
  ) return {result['vhdl']} is
  begin
    if p_eval(expr, {result['kind']}, -1, p_eval_operation(expr, session), session) then
      return {result['value']};
    end if;
    return {result['default']};
  end;
"""
        )
    for result in PROCEDURE_RESULTS:
        parts.append(
            f"""\
  procedure eval_{result['name']}(
    expr : string; result : out {result['vhdl']}; {SESSION}
  ) is
  begin
    if p_eval(expr, {result['kind']}, result'length, p_eval_operation(expr, session), session) then
      result := {result['value']};
    end if;
  end;
"""
        )
    return "\n".join(parts).rstrip("\n")


# -------------------------------------------------------------------------
# call
# -------------------------------------------------------------------------
def call_declarations():
    """
    Declarations of the generated call functions and of the call procedures.
    """
    lines = []
    for result in RESULTS:
        if result["hand_written_call"]:
            continue
        name = call_name(result)
        lines.append(f"  impure function {name}(")
        lines.append(f"    identifier : string; {ARG_PARAMETERS};")
        lines.append(f"    {SESSION}")
        lines.append(f"  ) return {result['vhdl']};")
        for alias in call_aliases(result):
            lines.append(f"  alias {alias} is {name}[")
            lines.append(f"    {ARG_SIGNATURE} return {result['vhdl']}];")
        lines.append("")
    for result in PROCEDURE_RESULTS:
        lines.append(f"  procedure call_{result['name']}(")
        lines.append(f"    identifier : string; result : out {result['vhdl']};")
        lines.append(f"    {ARG_PARAMETERS};")
        lines.append(f"    {SESSION}")
        lines.append("  );")
    return "\n".join(lines)


def call_subprograms():
    """
    Bodies of the generated call functions and of the call procedures. A call
    is the evaluation of the Python expression calling the identifier with the
    given arguments.
    """
    parts = []
    for result in RESULTS:
        if result["hand_written_call"]:
            continue
        parts.append(
            f"""\
  impure function {call_name(result)}(
    identifier : string; {ARG_PARAMETERS};
    {SESSION}
  ) return {result['vhdl']} is
  begin
    return eval_{result['name']}(
      to_call_str(identifier, {ARG_ACTUALS}), session
    );
  end;
"""
        )
    for result in PROCEDURE_RESULTS:
        parts.append(
            f"""\
  procedure call_{result['name']}(
    identifier : string; result : out {result['vhdl']};
    {ARG_PARAMETERS};
    {SESSION}
  ) is
  begin
    eval_{result['name']}(
      to_call_str(identifier, {ARG_ACTUALS}), result, session
    );
  end;
"""
        )
    return "\n".join(parts).rstrip("\n")


# -------------------------------------------------------------------------
# call and eval of an object
# -------------------------------------------------------------------------
OBJECT = "object : python_object_t"
OBJECT_ARG_SIGNATURE = ", ".join(["python_object_t", "string"] + ["arg_t"] * len(ARGS))


def object_declarations():
    """
    Declarations of the call and eval overloads of an object: those of
    python_pkg with the object first, the method or expression second.
    """
    lines = [
        "  -- Call a method of the object",
        "  procedure call(",
        f"    {OBJECT}; method : string;",
        f"    {ARG_PARAMETERS}",
        "  );",
        "",
    ]
    for result in RESULTS:
        name = call_name(result)
        lines.append(f"  impure function {name}(")
        lines.append(f"    {OBJECT}; method : string;")
        lines.append(f"    {ARG_PARAMETERS}")
        lines.append(f"  ) return {result['vhdl']};")
        for alias in call_aliases(result):
            # The signature over two lines, to keep them short
            signature = OBJECT_ARG_SIGNATURE.split(", ")
            lines.append(f"  alias {alias} is {name}[")
            lines.append(f"    {', '.join(signature[:7])},")
            lines.append(f"    {', '.join(signature[7:])} return {result['vhdl']}];")
        lines.append("")
    for result in PROCEDURE_RESULTS:
        lines.append(f"  procedure call_{result['name']}(")
        lines.append(f"    {OBJECT}; method : string; result : out {result['vhdl']};")
        lines.append(f"    {ARG_PARAMETERS}")
        lines.append("  );")
    lines += ["", "  -- Evaluate an expression in the session of the object, where it is obj, like eval"]
    for result in RESULTS:
        lines.append(f"  impure function eval_{result['name']}({OBJECT}; expr : string) return {result['vhdl']};")
        if result.get("alias_eval", True):
            lines.append(f"  alias eval is eval_{result['name']}[python_object_t, string return {result['vhdl']}];")
    for result in PROCEDURE_RESULTS:
        lines.append(f"  procedure eval_{result['name']}({OBJECT}; expr : string; result : out {result['vhdl']});")
    return "\n".join(lines)


def object_subprograms():
    """
    Bodies of the call and eval overloads of an object. Each creates the object
    if needed and performs the operation in the session of the object. The call
    overloads report their errors as call("<method>") rather than as the code
    they evaluate, like the call procedure.
    """
    session = "session => get_session(object)"
    parts = [
        f"""\
  procedure call(
    {OBJECT}; method : string;
    {ARG_PARAMETERS}
  ) is
    variable ok : boolean;
  begin
    if not p_created(object) then
      return;
    end if;
    -- An error is reported as that of the method rather than of the code executed
    ok := p_exec(
      to_call_str("obj." & method, {ARG_ACTUALS}),
      0, p_call_operation(method), get_session(object)
    );
  end;
"""
    ]
    for result in RESULTS:
        name = call_name(result)
        parts.append(
            f"""\
  impure function {name}(
    {OBJECT}; method : string;
    {ARG_PARAMETERS}
  ) return {result['vhdl']} is
  begin
    if not p_created(object) then
      return {result['default']};
    end if;
    if p_eval(
      to_call_str("obj." & method, {ARG_ACTUALS}),
      {result['kind']}, -1, p_call_operation(method), get_session(object)
    ) then
      return {result['value']};
    end if;
    return {result['default']};
  end;
"""
        )
    for result in PROCEDURE_RESULTS:
        parts.append(
            f"""\
  procedure call_{result['name']}(
    {OBJECT}; method : string; result : out {result['vhdl']};
    {ARG_PARAMETERS}
  ) is
  begin
    if not p_created(object) then
      return;
    end if;
    if p_eval(
      to_call_str("obj." & method, {ARG_ACTUALS}),
      {result['kind']}, result'length, p_call_operation(method), get_session(object)
    ) then
      result := {result['value']};
    end if;
  end;
"""
        )
    for result in RESULTS:
        parts.append(
            f"""\
  impure function eval_{result['name']}({OBJECT}; expr : string) return {result['vhdl']} is
  begin
    if not p_created(object) then
      return {result['default']};
    end if;
    return eval_{result['name']}(expr, {session});
  end;
"""
        )
    for result in PROCEDURE_RESULTS:
        parts.append(
            f"""\
  procedure eval_{result['name']}({OBJECT}; expr : string; result : out {result['vhdl']}) is
  begin
    if not p_created(object) then
      return;
    end if;
    eval_{result['name']}(expr, result, {session});
  end;
"""
        )
    return "\n".join(parts).rstrip("\n")


def generate_object_package():
    """
    Generate python_object_pkg from its template and the generated overloads.
    """
    template = (TEMPLATE_PATH / "python_object_pkg.vhd.in").read_text(encoding="utf-8")
    return Template(template).substitute(
        object_declarations=object_declarations(),
        object_subprograms=object_subprograms(),
    )


def generate_package():
    """
    Generate python_pkg from the template and the generated declarations.
    """
    template = (TEMPLATE_PATH / "python_pkg.vhd.in").read_text(encoding="utf-8")
    return Template(template).substitute(
        arg_declarations=arg_declarations(),
        arg_functions=arg_functions(),
        eval_declarations=eval_declarations(),
        call_declarations=call_declarations(),
        eval_subprograms=eval_subprograms(),
        call_subprograms=call_subprograms(),
    )


def main():
    (SRC_PATH / "python_pkg.vhd").write_text(generate_package(), encoding="utf-8", newline="\n")
    (SRC_PATH / "python_object_pkg.vhd").write_text(generate_object_package(), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
