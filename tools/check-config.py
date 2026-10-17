# SPDX-FileCopyrightText: 2026 xcompanero
# SPDX-License-Identifier: GPL-3.0-or-later
#!/usr/bin/env python3
"""
Static sanity checks for the applet's config pages.

Both bugs found here during development were silent: a missing cfg_ alias, and
an alias pointing at an id that did not exist. Neither produced a visible error
at the point of the mistake -- the page just came up blank, or came up with a
setting nobody could edit.

Run from the project root:

    python3 tools/check-config.py
"""
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "package/contents/config"
UI_CONFIG = ROOT / "package/contents/ui/config"
NS = {"k": "http://www.kde.org/standards/kcfg/1.0"}

failures = []


def schema_keys():
    root = ET.fromstring((CONFIG / "main.xml").read_text())
    return {e.get("name") for g in root.findall("k:group", NS)
            for e in g.findall("k:entry", NS)}


def page_aliases(path):
    """Return (declared ids, [(cfg_key, target_id_or_None), ...]).

    Two shapes are in use: `property alias cfg_x: someId.value`, whose target
    must exist, and a plain `property string cfg_x: ""` used where the page
    syncs the value in code rather than binding it directly.
    """
    text = path.read_text()
    declared = set(re.findall(r"^\s*id:\s*(\w+)\s*$", text, re.M))
    bound = []
    for key in re.findall(r"property (?:alias|string|double|int|bool|real|var) (cfg_\w+):", text):
        m = re.search(rf"property alias {key}:\s*(\w+)\.", text)
        bound.append((key, m.group(1) if m else None))
    return declared, bound


def main():
    keys = schema_keys()
    print(f"schema: {len(keys)} entries")

    pages = re.findall(r'source: "config/(\w+)\.qml"',
                       (CONFIG / "config.qml").read_text())
    if not pages:
        failures.append("config.qml declares no ConfigCategory pages")
    print(f"pages:  {pages}")

    seen = {}
    for name in pages:
        path = UI_CONFIG / f"{name}.qml"
        if not path.exists():
            failures.append(f"{name}.qml is referenced by config.qml but missing")
            continue

        text = path.read_text()

        # Brace balance.
        depth = 0
        for line in text.split("\n"):
            code = line.split("//")[0]
            depth += code.count("{") - code.count("}")
        if depth != 0:
            failures.append(f"{name}.qml: unbalanced braces (depth {depth})")

        declared, aliases = page_aliases(path)
        for key, target in aliases:
            if target is not None and target not in declared:
                failures.append(
                    f"{name}.qml: {key} points at id '{target}', which is not declared")
            seen.setdefault(key[len("cfg_"):], []).append(name)
        print(f"  {name}.qml: {len(aliases)} aliases, {len(declared)} ids")

    # Every schema key must be bound by exactly one page.
    for key in sorted(keys):
        if key not in seen:
            failures.append(f"schema key '{key}' is not bound by any config page")
    for key, where in sorted(seen.items()):
        if len(where) > 1:
            failures.append(f"cfg key '{key}' declared on several pages: {where}")
        if key not in keys:
            failures.append(f"cfg key '{key}' is not in main.xml")

    if failures:
        print("\nFAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("\nall config pages consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
