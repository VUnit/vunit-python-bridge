# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
The behaviour of the accumulator_model component in tb_example.vhd. Every
instance executes this file in a session of its own and so gets a total of its own.
"""

total = 0


def accumulate(x):
    """
    Add x to the total and return the new total.
    """
    global total  # pylint: disable=global-statement
    total += x
    return total
