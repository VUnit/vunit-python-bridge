# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com

"""
Sphinx configuration of the vunit-python-bridge documentation.

Build with: sphinx-build -b html docs docs/_build
"""

import sys
import tomllib
from pathlib import Path

from packaging.version import Version

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT / "docs"))
import vhdl_api  # noqa: E402

project = "vunit-python-bridge"
copyright = "2014-2026, Lars Asplund"  # pylint: disable=redefined-builtin
author = "Lars Asplund"
with (ROOT / "pyproject.toml").open("rb") as fptr:
    release = tomllib.load(fptr)["project"]["version"]

extensions = ["myst_parser"]
# The release notes start at ## since they are included under a version heading
suppress_warnings = ["myst.header"]
exclude_patterns = ["_build"]

html_theme = "sphinx_rtd_theme"
html_theme_options = {
    "prev_next_buttons_location": "both",
    "navigation_depth": 3,
}
# The "Edit on GitHub" link of every page
html_context = {
    "display_github": True,
    "github_user": "VUnit",
    "github_repo": "vunit-python-bridge",
    "github_version": "main",
    "conf_py_path": "/docs/",
}


# The release notes page, generated from release_notes: the news fragments of news.d, which
# towncrier collects into unreleased.md when releasing, and unreleased.md, then the releases, newest first
with (ROOT / "pyproject.toml").open("rb") as _fptr:
    _types = tomllib.load(_fptr)["tool"]["towncrier"]["type"]
_news = []
for _type in _types:
    _fragments = sorted((ROOT / "release_notes" / "news.d").glob(f"*.{_type['directory']}.md"))
    if _fragments:
        _news += [f"### {_type['name']}", ""]
        _news += [f"- {path.read_text().strip()} (#{path.name.split('.')[0]})" for path in _fragments] + [""]
(ROOT / "docs" / "news.md").write_text("\n".join(_news))
_notes = ["Release notes", "=============", ""]
_unreleased = [ROOT / "docs" / "news.md"] if _news else []
_unreleased += sorted((ROOT / "release_notes").glob("unreleased.md"))
if _unreleased:
    _notes += ["Unreleased", "----------", ""]
    for _path in _unreleased:
        _notes += [f".. include:: ../{_path.relative_to(ROOT).as_posix()}", "   :parser: myst_parser.sphinx_", ""]
_releases = sorted((ROOT / "release_notes").glob("[0-9]*.md"), key=lambda path: Version(path.stem), reverse=True)
for _path in _releases:
    _notes += [_path.stem, "-" * len(_path.stem), "", f".. include:: ../release_notes/{_path.name}"]
    _notes += ["   :parser: myst_parser.sphinx_", ""]
(ROOT / "docs" / "release_notes.rst").write_text("\n".join(_notes))

vhdl_api.write(ROOT / "docs" / "api")
