# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Points Tcl/Tk to the scripts of the Python installation. Tcl looks for them next
to the executable, which here is the simulator.
"""

from os import environ
from pathlib import Path
from sys import base_prefix

for var, pattern in [("TCL_LIBRARY", "*/tcl[0-9]*/init.tcl"), ("TK_LIBRARY", "*/tk[0-9]*/tk.tcl")]:
    for script in Path(base_prefix).glob(pattern):
        environ[var] = str(script.parent)
