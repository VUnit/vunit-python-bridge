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

extensions = ["myst_parser", "sphinxcontrib.towncrier.ext"]
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


# The release notes page, generated from release_notes: the draft of the news fragments in
# news.d, rendered by towncrier, and unreleased.md, then the releases, newest first. It is
# Markdown, since towncrier writes Markdown and the draft is parsed like the page.
towncrier_draft_autoversion_mode = "draft"
towncrier_draft_include_empty = False
towncrier_draft_working_directory = ROOT
_notes = ["# Release notes", ""]
_unreleased = sorted((ROOT / "release_notes").glob("unreleased.md"))
if _unreleased or any((ROOT / "release_notes" / "news.d").glob("*.md")):
    _notes += ["## Unreleased", "", "```{towncrier-draft-entries}", "```", ""]
_releases = sorted((ROOT / "release_notes").glob("[0-9]*.md"), key=lambda path: Version(path.stem), reverse=True)
for _path in _unreleased + _releases:
    if _path.stem != "unreleased":
        _notes += [f"## {_path.stem}", ""]
    _notes += [f"```{{include}} ../release_notes/{_path.name}", ":heading-offset: 1", "```", ""]
(ROOT / "docs" / "release_notes.md").write_text("\n".join(_notes))

vhdl_api.write(ROOT / "docs" / "api")
