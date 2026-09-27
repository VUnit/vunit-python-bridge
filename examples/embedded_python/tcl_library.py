# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Points Tcl and Tk to the scripts of the Python installation, for the tests of
tb_example.vhd that show a Tk window. Tcl looks for its scripts next to the
executable, which is the simulator here, so it finds none (NVC, GHDL) or those
of the simulator (Riviera-PRO). A Tcl 9 that carries its scripts in its library
has none to point to.
"""

from os import environ
from pathlib import Path
from sys import base_prefix

for var, pattern in [("TCL_LIBRARY", "*/tcl[0-9]*/init.tcl"), ("TK_LIBRARY", "*/tk[0-9]*/tk.tcl")]:
    for script in Path(base_prefix).glob(pattern):
        environ[var] = str(script.parent)
