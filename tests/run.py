# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Run script of the tests of the vunit-python-bridge package.

It is imported by tb_python_pkg through import_run_script, which is why
everything but remote_test is guarded by a __main__ check.
"""

import os
import subprocess
import sys
from pathlib import Path
from vunit import VUnit, VUnitCLI
from vunit_python_bridge import FILE_BASE_VARIABLE

ROOT = Path(__file__).parent

def remote_test():
    """
    Called from VHDL to verify that the run script can be imported into the
    embedded Python interpreter.
    """
    return 2


def run_file_base_tests(args):
    """
    Run the tests of base_path with a base directory, which is fixed for a run and
    therefore a run of its own, with the same simulator and an output path of its own.
    It runs twice: with the base directory set by set_relative_file_base() in the run
    script, and with it set by the environment variable instead.
    """
    for name, env in [
        ("function", dict(os.environ)),
        ("variable", dict(os.environ, **{FILE_BASE_VARIABLE: str(ROOT.resolve())})),
    ]:
        command = [
            sys.executable,
            str(ROOT / "file_base" / "run.py"),
            "-o",
            str(Path(args.output_path) / "file_base" / name),
            "-p",
            str(args.num_threads),
        ]
        sys.stdout.flush()
        if subprocess.run(command, env=env, check=False).returncode != 0:
            raise RuntimeError(f"The tests of tests/file_base/run.py with the base directory set by the {name} failed")


def main():
    args = VUnitCLI().parse_args()
    # The tests of base_path without a base directory need the variable unset
    os.environ.pop(FILE_BASE_VARIABLE, None)
    vu = VUnit.from_args(args)
    vu.add_vhdl_builtins()
    vu.add_package("vunit-python-bridge", allow_setup=True)

    lib = vu.add_library("lib")
    lib.add_source_file(ROOT / "tb_python_pkg.vhd")
    lib.add_source_file(ROOT / "tb_python_pkg_bridge.vhd")

    vu.set_compile_option("rivierapro.vcom_flags", ["-dbg"])
    vu.set_sim_option("rivierapro.vsim_flags", ["-interceptcoutput"])

    def post_run(results):  # pylint: disable=unused-argument
        run_file_base_tests(args)

    vu.main(post_run=post_run)


if __name__ == "__main__":
    main()
