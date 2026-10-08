# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com


"""
A stateful model for the Python object tests: each VHDL instance must get its own.
"""


class Counter:
    def __init__(self, start=0, step=1):
        self.count = start
        self.step = step

    def add(self, times):
        self.count += times * self.step
        return self.count

    def value(self):
        return self.count

    def history(self):
        return list(range(self.count + 1))

    def ratio(self):
        return self.count / 4
