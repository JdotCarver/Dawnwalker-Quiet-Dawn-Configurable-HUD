#!/usr/bin/env python3
"""ressources/tools/check-mod-settings.py

Validate mod_settings.ini against the Dawnwalker Mod Menu rules.

Why this exists
---------------
The menu rejects a malformed manifest at load time, inside the game, usually
by simply not showing the mod's page. That is a slow and confusing way to find
a typo in a 1200-line file.

The checks mirror "Rules that matter" in the integration guide, plus the two
couplings that are specific to this mod:

  * Every ConfigKey must exist in SettingsSchema.lua, and every schema key
    that players can edit must have a row in the manifest. A rename done in
    one file and not the other is otherwise invisible until runtime.
  * A [Category.X] section only applies to settings whose Group is EXACTLY X.
    The guide is explicit that the match is literal, so a stray space or a
    changed separator silently stops a whole category from being hidden by
    its controlling toggle.

Setup:  bash ressources/tools/setup.sh
Usage:  python3 ressources/tools/check-mod-settings.py
"""

import pathlib
import re
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/mod_settings.ini"
SCHEMA = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts/SettingsSchema.lua"

# Declared in the manifest but intentionally absent from the Lua schema, or the
# other way around. Keep this list short and explained.
SCHEMA_ONLY_KEYS = {
    # Read from the personal QuietDawnHUD.ini, never shown in the menu.
    "SummarySeconds", "SlowCallbackMs", "MaxEventsPerSecond",
}

problems = []


def fail(message):
    problems.append(message)
    print(f"FAIL {message}")


def parse_sections(text):
    """Return [(section_name, {key: value})] in file order."""
    sections, name, fields = [], None, {}
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            if name is not None:
                sections.append((name, fields))
            name, fields = line[1:-1], {}
        elif line and not line.startswith(";") and "=" in line and name is not None:
            key, _, value = line.partition("=")
            fields[key.strip()] = value.strip()
    if name is not None:
        sections.append((name, fields))
    return sections


def main():
    text = MANIFEST.read_text(encoding="utf-8")
    sections = parse_sections(text)

    settings = [(n, f) for n, f in sections if n.startswith("Setting")]
    categories = [(n[len("Category."):], f) for n, f in sections if n.startswith("Category.")]
    mod = next((f for n, f in sections if n == "Mod"), None)

    if mod is None:
        fail("no [Mod] section")
        return 1
    for required in ("Id", "Name"):
        if required not in mod:
            fail(f"[Mod] is missing the required field {required}")

    identifiers, groups = set(), set()
    for name, fields in settings:
        identifier = fields.get("Id")
        if not identifier:
            fail(f"[{name}] has no Id")
            continue
        if identifier in identifiers:
            fail(f"duplicate setting Id: {identifier}")
        identifiers.add(identifier)

        if "Group" in fields:
            groups.add(fields["Group"])

        if not fields.get("Description"):
            fail(f"{identifier} has no Description")

        kind = fields.get("Type", "")
        values = fields.get("PresetValues")
        labels = fields.get("PresetLabels")
        if kind in ("toggle", "picker", "preset"):
            if not values or not labels:
                fail(f"{identifier} is a {kind} without PresetValues/PresetLabels")
                continue
            value_list = values.split("|")
            label_list = labels.split("|")
            if len(value_list) != len(label_list):
                fail(f"{identifier} has {len(value_list)} PresetValues but {len(label_list)} PresetLabels")
            if any(not label.strip() for label in label_list):
                fail(f"{identifier} has an empty PresetLabel")
            if len(set(value_list)) != len(value_list):
                fail(f"{identifier} has duplicate PresetValues")
            if kind == "toggle" and len(value_list) != 2:
                fail(f"{identifier} is a toggle with {len(value_list)} values; exactly 2 are required")
            if kind in ("picker", "preset") and not 2 <= len(value_list) <= 64:
                fail(f"{identifier} is a picker with {len(value_list)} values; 2 to 64 are allowed")
            default = fields.get("Default")
            if default is not None and default not in value_list:
                fail(f"{identifier} default {default} is not one of its PresetValues ({values})")

    # Conditional visibility must point at a setting that exists.
    for name, fields in settings:
        target = fields.get("VisibleWhen")
        if target and target not in identifiers:
            fail(f"{fields.get('Id')} has VisibleWhen = {target}, which is not a setting Id")
    for group, fields in categories:
        target = fields.get("VisibleWhen")
        if target and target not in identifiers:
            fail(f"[Category.{group}] has VisibleWhen = {target}, which is not a setting Id")

    # A category only applies to groups matching its name EXACTLY.
    seen_categories = set()
    for group, _ in categories:
        if group in seen_categories:
            fail(f"duplicate [Category.{group}] declaration")
        seen_categories.add(group)
        if group not in groups:
            fail(f"[Category.{group}] matches no Group; the match is literal, so check spacing and separators")

    # Manifest and Lua schema must agree on the set of editable keys.
    schema_text = SCHEMA.read_text(encoding="utf-8")
    schema_keys = set(re.findall(r'{key\s*=\s*"([^"]+)"', schema_text))
    config_keys = {f["ConfigKey"] for _, f in settings if "ConfigKey" in f}

    for key in sorted(config_keys - schema_keys):
        fail(f"ConfigKey {key} is in the manifest but not in SettingsSchema.lua")
    for key in sorted(schema_keys - config_keys - SCHEMA_ONLY_KEYS):
        fail(f"schema key {key} has no row in mod_settings.ini")

    print()
    print(f"   {len(settings)} settings, {len(categories)} categories, {len(groups)} groups")
    print(f"   {len({f.get('Description') for _, f in settings})} distinct descriptions")
    if problems:
        print(f"!! {len(problems)} problem(s) found")
        return 1
    print("== mod_settings.ini is consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
