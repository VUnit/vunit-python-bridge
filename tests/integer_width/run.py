# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Run script of the tests of the width of integer, see #43. The testbench checks
that the integer transfers work whatever the width of integer. It is a run of
its own since the standard is fixed for a run: VUNIT_VHDL_STANDARD selects it,
2019 gives NVC a 64-bit integer.
"""

from pathlib import Path

from vunit import VUnit

ROOT = Path(__file__).parent


def main():
    vu = VUnit.from_argv()
    vu.add_vhdl_builtins()
    vu.add_package("vunit-python-bridge", allow_setup=True)

    lib = vu.add_library("lib")
    lib.add_source_file(ROOT / "tb_integer_width.vhd")

    vu.main()


if __name__ == "__main__":
    main()
