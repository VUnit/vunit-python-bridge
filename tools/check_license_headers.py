# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Check that every Python, VHDL and C source file starts with the MPL 2.0 notice and a copyright
line ending with the current year. Lists the files that don't and exits with 1.
"""

import datetime
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
SUFFIXES = (".py", ".vhd", ".vhd.in", ".c", ".h")
# The header is within the first lines, after an optional description line
HEADER_LINES = 15
NOTICE = [
    "This Source Code Form is subject to the terms of the Mozilla Public",
    "License, v. 2.0. If a copy of the MPL was not distributed with this file,",
    "You can obtain one at http://mozilla.org/MPL/2.0/.",
]
COPYRIGHT = re.compile(r"Copyright \(c\) 2014-(\d{4}), Lars Asplund lars\.anders\.asplund@gmail\.com")


def header_problem(text: str, year: int):
    """
    What is wrong with the header of a file, or None.
    """
    header = "\n".join(text.splitlines()[:HEADER_LINES])
    if not all(line in header for line in NOTICE):
        return "no MPL 2.0 notice"
    match = COPYRIGHT.search(header)
    if match is None:
        return "no copyright line 'Copyright (c) 2014-<year>, Lars Asplund lars.anders.asplund@gmail.com'"
    if int(match.group(1)) != year:
        return f"copyright ends with {match.group(1)}, not {year}"
    return None


def main() -> int:
    files = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
    year = datetime.date.today().year
    problems = []
    for name in sorted(name for name in files if name.endswith(SUFFIXES)):
        problem = header_problem((ROOT / name).read_text(encoding="utf-8"), year)
        if problem:
            problems.append(f"{name}: {problem}")
    print("\n".join(problems) or "All license headers are in place.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
