# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
The Tcl/Tk installation for the tests using tkinter (PySimpleGUI dialogs, Matplotlib windows),
imported from VHDL with import_module_from_file.

A simulator with a Tcl of its own, like Riviera-PRO, can make tkinter look for the Tcl/Tk script
libraries of that Tcl rather than those of the Python installation. set_tcl_installation points
TCL_LIBRARY and TK_LIBRARY at the libraries of the Python installation, of whatever Tcl version it
has, when it has them in its lib (Linux, macOS) or tcl (Windows) directory. Otherwise it leaves
them alone, for Tcl to find its libraries itself.
"""

import os
import sys
from pathlib import Path

# The variable, the directory name pattern and a script every such directory has
LIBRARIES = [("TCL_LIBRARY", "tcl[0-9]*", "init.tcl"), ("TK_LIBRARY", "tk[0-9]*", "tk.tcl")]

_saved = {}


def set_tcl_installation():
    for name, pattern, script in LIBRARIES:
        _saved.setdefault(name, os.environ.get(name))
        for directory in (Path(sys.base_prefix) / "lib", Path(sys.base_prefix) / "tcl"):
            found = [path for path in sorted(directory.glob(pattern), reverse=True) if (path / script).is_file()]
            if found:
                os.environ[name] = str(found[0])
                break


def unset_tcl_installation():
    for name, value in _saved.items():
        if value is None:
            os.environ.pop(name, None)
        else:
            os.environ[name] = value
    _saved.clear()
