# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Run script of the tests of base_path with a base directory set by
set_relative_file_base(), or by the environment variable
VUNIT_PYTHON_BRIDGE_FILE_BASE when that is set. It is a run of its own since
the base directory is fixed for a run, and tests/run.py starts it after its own
tests, once for each way.
"""

import os
from pathlib import Path

from vunit import VUnit

import vunit_python_bridge

ROOT = Path(__file__).parent

# The tests directory, not the directory of the testbench
BASE_DIR = ROOT.parent


def main():
    vu = VUnit.from_argv()
    vu.add_vhdl_builtins()
    # tests/run.py runs this once with the base directory set here and once with it set by
    # the environment variable instead
    if vunit_python_bridge.FILE_BASE_VARIABLE not in os.environ:
        vunit_python_bridge.set_relative_file_base(BASE_DIR)
    vu.add_package("vunit-python-bridge", allow_setup=True)

    lib = vu.add_library("lib")
    lib.add_source_file(ROOT / "tb_file_base.vhd")
    base_dir = Path(os.environ.get(vunit_python_bridge.FILE_BASE_VARIABLE) or BASE_DIR).resolve()
    models_dir = (BASE_DIR / "models").resolve()
    tb = lib.test_bench("tb_file_base")
    tb.set_generic("models_dir", models_dir.as_posix())
    tb.set_generic("models_name", models_dir.relative_to(base_dir).as_posix())

    vu.main()


if __name__ == "__main__":
    main()
