# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com


"""
Setup of the Python bridge of a project: native library, configuration and generated VHDL.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, NamedTuple, Optional

from .native_library import (
    LIBRARY_DIR_VARIABLE,
    PACKAGE_PATH,
    PythonBridgeError,
    check_python_build,
    check_windows_64bit_simulator,
    library_directory,
    prepare_library,
    windows_python_dll,
)

RUNTIME_SOURCE = PACKAGE_PATH / "runtime.py"
VHDL_SOURCE_PATH = PACKAGE_PATH / "hdl" / "src"
BRIDGE_PACKAGE_TEMPLATE = VHDL_SOURCE_PATH / "python_bridge_pkg.vhd.in"
CONFIG_FILE_NAME = "vunit_python_bridge.cfg"

# The foreign language interface of each built-in VUnit simulator. VHPIDIRECT names the library
# by file name and the simulator hooks make the simulator load it, which GHDL does in its own way.
BUILTIN_SIMULATORS = {
    "nvc": "VHPIDIRECT",
    "ghdl": "VHPIDIRECT_GHDL",
    "modelsim": "FLI",
    "rivierapro": "VHPI",
}

# The simulators of the table, named as a user knows them
SUPPORTED_SIMULATORS = "NVC, GHDL, Questa/ModelSim or Riviera-PRO"

# What the interface class of a simulator from a VUnit package defines instead, see
# docs/simulator_packages.rst
INTERFACE_ATTRIBUTE = "foreign_language_interface"
HOOKS_ATTRIBUTE = "native_library_hooks"
PACKAGE_INTERFACES = ("VHPIDIRECT", "FLI", "VHPI")

# GHDL backends that link the design ahead of time. For these the library
# token in the VHPIDIRECT attribute is passed to the linker instead of being
# dlopen()ed at run time.
GHDL_LINKING_BACKENDS = ("llvm", "gcc")

# {foreign:<entry point>} placeholder of the bridge package template
FOREIGN_PATTERN = re.compile(r"\{foreign:(\w+)\}")
# The subprogram declarations of the template, whose bodies are generated
SUBPROGRAM_PATTERN = re.compile(r"^  (impure function|procedure) (\w+)(\([^)]*\))?( return \w+)?;", re.MULTILINE)


class PythonBridge(NamedTuple):
    """
    A prepared bridge: the native library and the generated VHDL.
    """

    library_file: Path
    config_file: Path
    vhdl_files: List[Path]


def setup(
    output_path,
    run_script_path: Optional[Path],
    simulator_name: Optional[str] = None,
    simulator_prefix: Optional[str] = None,
    simulator_backend: Optional[str] = None,
    interface: Optional[str] = None,
) -> PythonBridge:
    """
    Prepare the Python bridge for a project. Called by the package setup function.

    :param run_script_path: The run script or None. The runtime puts its directory, or the current
                            directory without a run script, first on sys.path, like python does.
    :param simulator_name: The name of the selected simulator, None for no simulator.
    :param simulator_prefix: The path its executables were found in.
    :param simulator_backend: How the installation found there was built, which for GHDL
                              is the code generator deciding how the library is bound.
    :param interface: The foreign language interface, see foreign_language_interface. None takes it
                      from the table of built-in simulators by name.
    :returns: The bridge. Its vhdl_files are to be added to the package library.
    """
    if interface is None and simulator_name is not None:
        interface = BUILTIN_SIMULATORS.get(simulator_name)
        if interface is None:
            raise PythonBridgeError(
                f"The vunit-python-bridge package requires {SUPPORTED_SIMULATORS}, "
                f"it is not supported for {simulator_name}"
            )

    check_python_build()
    check_windows_64bit_simulator(simulator_name, simulator_prefix)

    is_fli = interface == "FLI"
    is_vhpi = interface == "VHPI"
    if (is_fli or is_vhpi) and simulator_prefix is None:
        raise PythonBridgeError(
            f"The {'FLI' if is_fli else 'VHPI'} variant of the bridge is built against the {simulator_name} "
            "installation, but it was not found"
        )

    root = Path(output_path) / "python_bridge"
    front_end = "fli" if is_fli else "vhpi" if is_vhpi else None
    library_file = _prepare_library(Path(simulator_prefix) if front_end else None, front_end)
    run_script_dir = str(Path.cwd() if run_script_path is None else Path(run_script_path).resolve().parent)
    # The configuration belongs to the project, the library may be shared. The simulator
    # hooks tell the library where the configuration is.
    config_file = root / CONFIG_FILE_NAME
    _write_if_changed(config_file, _config_text(run_script_dir))

    # The foreign attribute string of an entry point: the name of its wrapper in native/fli.c
    # and the library, by absolute path since Questa accepts it, for the FLI; the library by
    # absolute path without its suffix, which Riviera-PRO adds, and the entry point registered
    # by native/vhpi.c for VHPI; the VHPIDIRECT library token and the entry point itself for
    # VHPIDIRECT.
    if is_fli:
        foreign = f"fli_{{entry_point}} {library_file!s}"
    elif is_vhpi:
        foreign = f"VHPI {_vhpi_library_token(library_file)} {{entry_point}}"
    else:
        foreign = f"VHPIDIRECT {_vhpidirect_token(interface, simulator_backend, library_file)} {{entry_point}}"
    bridge_package = root / "vhdl" / "python_bridge_pkg.vhd"
    _write_if_changed(bridge_package, _render_bridge_package(foreign))

    return PythonBridge(
        library_file,
        config_file,
        [
            bridge_package,
            VHDL_SOURCE_PATH / "python_ffi_pkg_bridge.vhd",
        ],
    )


def foreign_language_interface(simulator_class) -> str:
    """
    The foreign language interface serving the selected simulator: the one its interface class
    names in foreign_language_interface, or else the one of the built-in simulator of its name.
    """
    name = simulator_class.name
    interface = getattr(simulator_class, INTERFACE_ATTRIBUTE, None)
    hooks = getattr(simulator_class, HOOKS_ATTRIBUTE, None)
    if interface is None and hooks is None:
        if name in BUILTIN_SIMULATORS:
            return BUILTIN_SIMULATORS[name]
        raise PythonBridgeError(
            f"The vunit-python-bridge package requires {SUPPORTED_SIMULATORS}, or a simulator whose interface "
            f"class says how it loads a native library, which {name} does not. Its simulator interface class must "
            f"define {INTERFACE_ATTRIBUTE} ({', '.join(map(repr, PACKAGE_INTERFACES))}) and "
            f"{HOOKS_ATTRIBUTE}(library_file), see 'Simulator packages' in the vunit-python-bridge documentation."
        )
    for defined, missing in ((INTERFACE_ATTRIBUTE, HOOKS_ATTRIBUTE), (HOOKS_ATTRIBUTE, INTERFACE_ATTRIBUTE)):
        if getattr(simulator_class, missing, None) is None:
            raise PythonBridgeError(
                f"The {name} simulator interface defines {defined} but not {missing}, "
                "the vunit-python-bridge package needs both. Define it in the simulator interface class."
            )
    if interface not in PACKAGE_INTERFACES:
        raise PythonBridgeError(
            f"{INTERFACE_ATTRIBUTE} of the {name} simulator interface is {interface!r}, "
            f"the vunit-python-bridge package knows {', '.join(map(repr, PACKAGE_INTERFACES))}"
        )
    if not callable(hooks):
        raise PythonBridgeError(
            f"{HOOKS_ATTRIBUTE} of the {name} simulator interface is not callable, it must be a static or "
            "class method taking the library file"
        )
    return interface


def _prepare_library(simulator_prefix: Optional[Path], front_end: Optional[str]) -> Path:
    """
    Prepare the library in the library directory, failing with a pointer to the variable
    selecting another one when it cannot be written, e.g. a read-only home directory.
    """
    directory = library_directory()
    try:
        return prepare_library(directory, simulator_prefix, front_end)
    except OSError as exc:
        source = f"set by {LIBRARY_DIR_VARIABLE}" if os.environ.get(LIBRARY_DIR_VARIABLE) else "the default"
        raise PythonBridgeError(
            f"Cannot build the Python bridge library in {directory!s} ({source}): {exc}. "
            f"Set {LIBRARY_DIR_VARIABLE} to a writable directory."
        ) from exc


def _vhpidirect_token(interface: Optional[str], simulator_backend: Optional[str], library_file: Path) -> str:
    """
    The library token of the VHPIDIRECT attributes: the file name the simulator dlopen()s,
    or the linker flag of the GHDL backends that link the design ahead of time.
    """
    if interface == "VHPIDIRECT_GHDL" and simulator_backend in GHDL_LINKING_BACKENDS:
        return "-lvunit_python_bridge"
    return library_file.name


def _vhpi_library_token(library_file: Path) -> str:
    """
    The library of the VHPI attributes: its path without the suffix the simulator adds. The
    attribute separates its parts by spaces, so the path cannot have any.
    """
    token = str(library_file.with_suffix(""))
    if any(character.isspace() for character in token):
        raise PythonBridgeError(
            f"The Python bridge library for VHPI is in {library_file.parent!s}, whose path has a space, which the "
            f"VHPI foreign attribute cannot name. Set {LIBRARY_DIR_VARIABLE} to a directory without spaces."
        )
    return token


def _render_bridge_package(foreign: str) -> str:
    """
    The generated python_bridge_pkg.vhd: the declarations of the template with the foreign
    attribute of every subprogram, and a body reporting a failure for each of them since the
    bodies are replaced by the foreign implementations and never executed.
    """
    template = BRIDGE_PACKAGE_TEMPLATE.read_text(encoding="utf-8")
    declarations = FOREIGN_PATTERN.sub(lambda match: foreign.format(entry_point=match.group(1)), template)
    stubs = []
    for kind, name, parameters, result in SUBPROGRAM_PATTERN.findall(declarations):
        stubs.append(f"  {kind} {name}{parameters}{result} is\n  begin")
        stubs.append(f'    report "VUnit Python bridge: foreign subprogram {name} is not bound" severity failure;')
        if result:
            stubs.append(f"    return {'0.0' if result.endswith('real') else '1'};")
        stubs.append("  end;\n")
    return declarations + "\npackage body python_bridge_pkg is\n" + "\n".join(stubs) + "end package body;\n"


def _config_text(run_script_dir: str) -> str:
    """
    Content of the configuration file read by the bridge library at run time.
    """
    lines = {
        "executable": sys.executable,
        "prefix": sys.prefix,
        "runtime": str(RUNTIME_SOURCE),
        "run_script_dir": run_script_dir,
    }
    if sys.platform == "win32":
        lines["python_dll"] = windows_python_dll()
    for key, value in lines.items():
        if "\n" in value or "\r" in value:
            raise PythonBridgeError(f"VHDL Python support cannot handle line breaks in the path {value!r}")
    return "".join(f"{key}={value}\n" for key, value in lines.items())


def _write_if_changed(path: Path, text: str) -> None:
    """
    Write a file unless it already has the given content, keeping timestamps stable.
    """
    data = text.encode("utf-8")
    if path.is_file() and path.read_bytes() == data:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + f".{os.getpid()}.tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)
