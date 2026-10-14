# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com


"""
The VUnit package making Python callable from VHDL.

``vu.add_package("vunit-python-bridge", allow_setup=True)`` compiles
``python_pkg``/``python_context`` into the ``python_bridge`` library and sets up the foreign
language interface implementing them for the selected simulator:

the VUnit Python bridge, a small C library (native/*.c) embedding CPython in the simulator
process, called through VHPIDIRECT (NVC, GHDL), the FLI (Questa/ModelSim) or VHPI
(Riviera-PRO/Active-HDL).

Modules:

* bridge: setup of the bridge, its configuration and its generated VHDL.
* native_library: compiles and caches the library on Linux and macOS, selects the prebuilt
  DLL on Windows.
* simulator_hooks: makes the simulators find the library and its configuration.
* runtime: runs inside the simulator's embedded interpreter.
* file_base: the base directory of ``base_path``, ``set_relative_file_base``.

``set_relative_file_base(directory)``, called in the run script before ``add_package``, sets the
directory that ``base_path`` of ``python_pkg`` returns, for VHDL to join file names to. The
environment variable ``VUNIT_PYTHON_BRIDGE_FILE_BASE`` sets it too, and takes precedence.
"""

from pathlib import Path

from .file_base import add_file_base_package

# Public: run scripts use them
from .file_base import FILE_BASE_VARIABLE as FILE_BASE_VARIABLE
from .file_base import set_relative_file_base as set_relative_file_base

VHDL_PATH = Path(__file__).parent.resolve() / "hdl" / "src"

# The foreign language interface implementing the package for a simulator. VUnit says which
# simulator was selected, the package says how it is served: NVC and GHDL both go through
# VHPIDIRECT but bind the library differently, Questa/ModelSim goes through the FLI and
# Riviera-PRO/Active-HDL through VHPI.
FOREIGN_LANGUAGE_INTERFACES = {
    "nvc": "VHPIDIRECT_NVC",
    "ghdl": "VHPIDIRECT_GHDL",
    "modelsim": "FLI",
    "rivierapro": "VHPI",
    "activehdl": "VHPI",
}

# The simulators of the table, named as a user knows them
SUPPORTED_SIMULATORS = "NVC, GHDL, Questa/ModelSim, Riviera-PRO or Active-HDL"


def setup(context):
    """
    Complete the addition of the package.

    ``vunit_pkg.toml`` lists the sources of the package, this adds the bridge for the
    foreign language interface of the selected simulator.
    """
    # pylint: disable=import-outside-toplevel
    from .bridge import setup as setup_bridge
    from . import simulator_hooks

    simulator_name = context.simulator_name
    if simulator_name is None:
        raise RuntimeError(
            f"The vunit-python-bridge package requires {SUPPORTED_SIMULATORS} but no simulator was found"
        )

    interface = FOREIGN_LANGUAGE_INTERFACES.get(simulator_name)
    if interface is None:
        raise RuntimeError(
            f"The vunit-python-bridge package requires {SUPPORTED_SIMULATORS}, "
            f"it has no foreign language interface for {simulator_name}"
        )

    add_file_base_package(context)

    bridge = setup_bridge(
        context.output_path,
        context.run_script_path,
        simulator_name,
        context.simulator_prefix,
        context.simulator_backend,
    )

    context.add_source_files(context.library.name, list(bridge.vhdl_files))

    simulator_hooks.register(context, bridge)
