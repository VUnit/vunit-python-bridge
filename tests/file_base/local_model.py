# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Fixture next to the testbench, executed by a relative file name of exec_file.
"""

from pathlib import Path

LOCAL_DIR = Path(__file__).parent.as_posix()


def get_local_dir():
    return LOCAL_DIR
