# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
The model of filter_vc: the average of the last inputs. Every filter_vc gets
an object of its own, or the one its testbench gives it.
"""


class MovingAverage:
    def __init__(self, window=2):
        self.window = window
        self.samples = []

    def push(self, x):
        self.samples.append(x)
        recent = self.samples[-self.window :]
        return sum(recent) // len(recent)

    def num_samples(self):
        return len(self.samples)
