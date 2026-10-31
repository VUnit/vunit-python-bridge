# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com


"""
Simulator hooks making the simulator load the bridge library and its dependencies.

They are registered with the package context by the setup function of the package, one set
per simulator, and are only called for the project they were registered for.

Questa needs no help finding the library itself: the FLI attributes of the generated
python_bridge_pkg.vhd name it by absolute path.
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

from .bridge import GHDL_LINKING_BACKENDS, HOOKS_ATTRIBUTE, BridgeSimulator, PythonBridge
from .native_library import PythonBridgeError

# The vsim flag keeping the runtime libraries Questa bundles out of the dynamic library
# search path, and the help category listing every vsim flag.
NO_AUTO_LD_LIBRARY_PATH = "-noautoldlibpath"
VSIM_HELP_ARGUMENTS = ("-help", "all")

# Read by native/config.c, keep in sync
CONFIG_FILE_VARIABLE = "VUNIT_PYTHON_BRIDGE_CONFIG"

# The keyword arguments of register_simulator_hooks of the VUnit package context
HOOK_KINDS = ("elab_flags", "run_flags", "process_flags", "run_env")


def register(context, bridge: PythonBridge, simulators: Dict[str, BridgeSimulator]) -> None:
    """
    Register the hooks of every built-in simulator with the package context. The hooks the selected
    simulator interface gives by native_library_hooks replace the built-in ones.
    """
    hooks = {
        "nvc": dict(run_flags=_nvc_run_flags(bridge), run_env=_config_run_env(bridge)),
        "ghdl": dict(elab_flags=_ghdl_elab_flags(bridge), run_env=_ghdl_run_env(bridge)),
        "modelsim": dict(process_flags=_modelsim_process_flags(), run_env=_config_run_env(bridge)),
    }
    selected = simulators.get(context.simulator_name)
    if selected is not None and selected.native_library_hooks is not None:
        hooks[context.simulator_name] = _package_hooks(context.simulator_name, selected.native_library_hooks, bridge)
    for simulator_name, kinds in hooks.items():
        context.register_simulator_hooks(simulator_name, **kinds)
    if context.simulator_name == "rivierapro":
        # Its interface has no run environment hook, but starts vsim with the environment of this
        # process, after the setup
        os.environ[CONFIG_FILE_VARIABLE] = str(bridge.config_file)


def _package_hooks(simulator_name: str, native_library_hooks, bridge: PythonBridge) -> Dict:
    """
    The hooks of a simulator interface loading the library, with the configuration added to its
    run environment.
    """
    hooks = native_library_hooks(bridge.library_file)
    if not isinstance(hooks, dict):
        raise PythonBridgeError(
            f"{HOOKS_ATTRIBUTE} of the {simulator_name} simulator interface returned {type(hooks).__name__}, "
            f"it must return a dict with any of the keys {', '.join(HOOK_KINDS)}"
        )
    unknown = sorted(str(kind) for kind in hooks if kind not in HOOK_KINDS)
    if unknown:
        raise PythonBridgeError(
            f"{HOOKS_ATTRIBUTE} of the {simulator_name} simulator interface returned the unknown keys "
            f"{', '.join(unknown)}, the keys are {', '.join(HOOK_KINDS)}"
        )
    return dict(hooks, run_env=_config_run_env(bridge, hooks.get("run_env")))


def _config_run_env(bridge: PythonBridge, simulator_run_env=None):
    """
    Tell the bridge library where the configuration of the project is, on top of the environment
    a simulator_run_env hook gives.
    """

    def hook(simulator_interface, env: Dict[str, str]) -> Dict[str, str]:
        if simulator_run_env is not None:
            env = simulator_run_env(simulator_interface, env)
        env = dict(env)
        env[CONFIG_FILE_VARIABLE] = str(bridge.config_file)
        return env

    return hook


def _nvc_run_flags(bridge: PythonBridge):
    """
    NVC run (-r) flags loading the bridge.
    """

    def hook(simulator_interface) -> List[str]:  # pylint: disable=unused-argument
        return [f"--load={bridge.library_file!s}"]

    return hook


def _ghdl_elab_flags(bridge: PythonBridge):
    """
    GHDL elaboration flags. Only the backends linking the design ahead of time need them,
    the others load the bridge at run time and are served by the run environment. The rpath
    lets the linked simulation find the bridge without the run environment, e.g. when re-run by hand.
    """

    def hook(simulator_interface) -> List[str]:
        if simulator_interface.backend not in GHDL_LINKING_BACKENDS:
            return []
        directory = bridge.library_file.parent
        return [f"-Wl,-L{directory!s}", f"-Wl,-Wl,-rpath,{directory!s}"]

    return hook


def _ghdl_run_env(bridge: PythonBridge):
    """
    Add the bridge directory to the dynamic library search path of a GHDL simulation.
    """

    config_env = _config_run_env(bridge)

    def hook(simulator_interface, env: Dict[str, str]) -> Dict[str, str]:
        variable = {"win32": "PATH", "darwin": "DYLD_LIBRARY_PATH"}.get(sys.platform, "LD_LIBRARY_PATH")
        env = config_env(simulator_interface, env)
        env[variable] = os.pathsep.join(
            item for item in (str(bridge.library_file.parent), env.get(variable, "")) if item
        )
        return env

    return hook


def _modelsim_process_flags():
    """
    Flags for the vsim process VUnit starts for a Questa/ModelSim simulation.

    Questa/ModelSim puts the directory of the C++ runtime it bundles first in
    LD_LIBRARY_PATH. That runtime is regularly older than the one the Python extension
    modules of the environment (NumPy, used for integer_array_t values) were built
    against, and they then fail to load in the embedded interpreter. -noautoldlibpath
    turns that off, leaving the C++ runtime of the system to be found as usual.

    The flag is set up when the process starts, so it is only honoured on the command line
    of the vsim process itself, not on the vsim command of the do-file VUnit generates.

    Only relevant on Linux, where LD_LIBRARY_PATH decides this, and only given to a vsim
    that knows the flag.
    """
    known: Dict[Optional[str], bool] = {}

    def hook(simulator_interface) -> List[str]:
        if not sys.platform.startswith("linux"):
            return []

        prefix = simulator_interface.prefix
        if prefix not in known:
            known[prefix] = _vsim_knows_flag(prefix, simulator_interface)
        if not known[prefix]:
            return []

        return [NO_AUTO_LD_LIBRARY_PATH]

    return hook


def _vsim_knows_flag(prefix: Optional[str], simulator_interface) -> bool:
    """
    Whether the vsim of an installation lists -noautoldlibpath among its options.

    Asking vsim rather than assuming keeps a version without the flag from failing to
    start at all. An installation that cannot be asked is taken to know it, since the
    flag is what makes the bridge usable there.
    """
    if prefix is None:
        return True

    try:
        output = subprocess.run(
            [str(Path(prefix) / "vsim"), *VSIM_HELP_ARGUMENTS],
            check=True,
            capture_output=True,
            text=True,
            env=simulator_interface.get_env(),
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return True

    return NO_AUTO_LD_LIBRARY_PATH in output.split()
