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
    PACKAGE_PATH,
    PythonBridgeError,
    check_python_build,
    prepare_library,
    windows_python_dll,
)

RUNTIME_SOURCE = PACKAGE_PATH / "runtime.py"
VHDL_SOURCE_PATH = PACKAGE_PATH / "vhdl" / "src"
BRIDGE_PACKAGE_TEMPLATE = VHDL_SOURCE_PATH / "python_bridge_pkg.vhd.in"
CONFIG_FILE_NAME = "vunit_python_bridge.cfg"

# The simulators the bridge serves, reaching it through VHPIDIRECT and through the FLI.
# The rest of the simulators of the package are served by the VHPI application.
FLI_SIMULATORS = ("modelsim",)
BRIDGE_SIMULATORS = ("nvc", "ghdl") + FLI_SIMULATORS

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
    vhdl_files: List[Path]


def setup(
    output_path,
    run_script_path: Optional[Path],
    simulator_name: Optional[str] = None,
    simulator_prefix: Optional[str] = None,
    simulator_backend: Optional[str] = None,
) -> PythonBridge:
    """
    Prepare the Python bridge for a project. Called by the package setup function.

    :param run_script_path: The run script or None. The runtime puts its directory, or the current
                            directory without a run script, first on sys.path, like python does.
    :param simulator_name: The name of the selected simulator, None for no simulator.
    :param simulator_prefix: The path its executables were found in.
    :param simulator_backend: How the installation found there was built, which for GHDL
                              is the code generator deciding how the library is bound.
    :returns: The bridge. Its vhdl_files are to be added to the package library.
    """
    if simulator_name is not None and simulator_name not in BRIDGE_SIMULATORS:
        raise PythonBridgeError(
            f"The vunit-python-bridge package requires NVC, GHDL or Questa/ModelSim, "
            f"it is not supported for {simulator_name}"
        )

    check_python_build()

    is_fli = simulator_name in FLI_SIMULATORS
    if is_fli and simulator_prefix is None:
        raise PythonBridgeError(
            f"The FLI variant of the bridge is built against the {simulator_name} installation, but it was not found"
        )

    root = Path(output_path) / "python_bridge"
    library_file = prepare_library(root, Path(simulator_prefix) if is_fli else None)
    run_script_dir = str(Path.cwd() if run_script_path is None else Path(run_script_path).resolve().parent)
    _write_if_changed(library_file.parent / CONFIG_FILE_NAME, _config_text(run_script_dir))

    # The foreign attribute string of an entry point: the name of its wrapper in native/fli.c
    # and the library, by absolute path since Questa accepts it, for the FLI; the VHPIDIRECT
    # library token and the entry point itself for NVC and GHDL.
    foreign = (
        f"fli_{{entry_point}} {library_file!s}"
        if is_fli
        else f"VHPIDIRECT {_vhpidirect_token(simulator_name, simulator_backend, library_file)} {{entry_point}}"
    )
    bridge_package = root / "vhdl" / "python_bridge_pkg.vhd"
    _write_if_changed(bridge_package, _render_bridge_package(foreign))

    return PythonBridge(
        library_file,
        [
            bridge_package,
            VHDL_SOURCE_PATH / "python_ffi_pkg_bridge.vhd",
        ],
    )


def _vhpidirect_token(simulator_name, simulator_backend: Optional[str], library_file: Path) -> str:
    """
    The library token of the VHPIDIRECT attributes: the file name the simulator dlopen()s,
    or the linker flag of the GHDL backends that link the design ahead of time.
    """
    if simulator_name == "ghdl" and simulator_backend in GHDL_LINKING_BACKENDS:
        return "-lvunit_python_bridge"
    return library_file.name


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
