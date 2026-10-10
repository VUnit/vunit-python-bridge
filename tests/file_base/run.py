# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Run script of the tests of base_path with a base directory set by
set_relative_file_base(). It is a run of its own since the base directory is
fixed for a run, and tests/run.py starts it after its own tests.
"""

from pathlib import Path

from vunit import VUnit

import vunit_python_bridge

ROOT = Path(__file__).parent

# The tests directory, not the directory of the testbench
BASE_DIR = ROOT.parent


def main():
    vu = VUnit.from_argv()
    vu.add_vhdl_builtins()
    vunit_python_bridge.set_relative_file_base(BASE_DIR)
    vu.add_package("vunit-python-bridge", allow_setup=True)

    lib = vu.add_library("lib")
    lib.add_source_file(ROOT / "tb_file_base.vhd")
    lib.test_bench("tb_file_base").set_generic("base_dir", BASE_DIR.resolve().as_posix())

    vu.main()


if __name__ == "__main__":
    main()
