#!/usr/bin/env python3
"""ressources/tools/test-settings-migration.py

Check the settings schema chain and the logLevel migration, without the game.

Why this exists
---------------
SettingsModel upgrades settings.ini one generation at a time, and each step is
steered by matching the EXACT error string Store.parse returns, for example
"Missing setting: logLevel". That coupling is invisible and easy to break: add
a key in the wrong place in SettingsSchema and a different key becomes "the
first missing one", so the recovery branch silently stops firing and an
existing player's settings.ini is rejected on startup.

These checks run the real Store.parse against synthetic settings files, so
that coupling is verified in a second rather than by reinstalling the mod.

What it does NOT cover: the upgrade WRITE path. Store.create refuses to run
off Windows (it checks package.config), so file replacement, backups and
recovery still need a real install.

Setup (once per sandbox):
    pip install --break-system-packages lupa

Usage:
    python3 ressources/tools/test-settings-migration.py
"""

import pathlib
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPTS = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts"

failures = []


def check(description, condition, detail=""):
    if condition:
        print(f"ok   {description}")
    else:
        failures.append(description)
        print(f"FAIL {description}" + (f"\n       {detail}" if detail else ""))


def main():
    try:
        from lupa import lua54
    except ImportError:
        print("!! lupa is not installed. Run:")
        print("     pip install --break-system-packages lupa")
        return 2

    lua = lua54.LuaRuntime()
    load_module = lua.eval("function(path) return dofile(path) end")

    def parse(text, parse_schema):
        """Store.parse returns `values` or `nil, message`.

        lupa only produces a Python tuple when Lua returns more than one
        value, so the success case arrives as a bare table. Normalise both
        shapes to (values, error).
        """
        result = store.parse(text, parse_schema)
        if isinstance(result, tuple):
            return result[0], result[1]
        return result, None

    levels = load_module(str(SCRIPTS / "QuietDawnLogLevels.lua"))
    schema = load_module(str(SCRIPTS / "SettingsSchema.lua"))
    store = load_module(str(SCRIPTS / "SettingsStore.lua"))

    keys = [row["key"] for row in schema.values()]

    check("schema declares logLevel", "logLevel" in keys)
    check("schema no longer declares debugLogging", "debugLogging" not in keys)

    log_level_row = next(row for row in schema.values() if row["key"] == "logLevel")
    check(
        "logLevel defaults to Warning",
        log_level_row["default"] == levels.WARNING,
        f"default={log_level_row['default']} expected={levels.WARNING}",
    )

    # The documented migration mapping, exercised through the real function.
    check("legacy toggle On becomes Debug", levels.fromLegacyToggle(1) == levels.DEBUG)
    check("legacy toggle Off becomes Warning", levels.fromLegacyToggle(0) == levels.WARNING)

    # A settings.ini from the previous release: every current key except
    # logLevel, plus the retired debugLogging line.
    def settings_file(include_log_level, legacy_toggle=None):
        lines = ["[Settings]"]
        for row in schema.values():
            if row["key"] == "logLevel" and not include_log_level:
                continue
            lines.append(f"{row['key']} = {row['default']}")
        if legacy_toggle is not None:
            lines.append(f"debugLogging = {legacy_toggle}")
        return "\n".join(lines) + "\n"

    previous_release = settings_file(include_log_level=False, legacy_toggle=1)

    # THE load-bearing assertion. SettingsModel branches on this exact string.
    _, error = parse(previous_release, schema)
    check(
        "a previous-release settings.ini fails with exactly 'Missing setting: logLevel'",
        error == "Missing setting: logLevel",
        f"got {error!r} -- the recovery guard in SettingsModel.lua will not fire",
    )

    # The pre-logLevel schema must parse that same file cleanly, which is what
    # lets the older upgrades keep running in order.
    pre_log_level = lua.table_from(
        [row for row in schema.values() if row["key"] != "logLevel"]
    )
    values, error = parse(previous_release, pre_log_level)
    check(
        "the pre-logLevel schema parses a previous-release settings.ini",
        values is not None,
        f"error={error!r}",
    )

    # How SettingsModel recovers the player's old choice for the new default.
    legacy_schema = lua.table_from([lua.table_from({"key": "debugLogging", "values": lua.table_from([0, 1])})])
    recovered, _ = parse(previous_release, legacy_schema)
    check(
        "the retired debugLogging value is still readable for the migration",
        recovered is not None and recovered["debugLogging"] == 1,
    )

    # A current file must parse with no leftover key present at all.
    values, error = parse(settings_file(include_log_level=True), schema)
    check("a current settings.ini parses cleanly", values is not None, f"error={error!r}")

    # A stale debugLogging line left behind by the migration must be ignored.
    values, error = parse(
        settings_file(include_log_level=True, legacy_toggle=1), schema
    )
    check(
        "a leftover debugLogging line is ignored rather than rejected",
        values is not None,
        f"error={error!r}",
    )

    # Every level the picker offers must be accepted by the schema.
    for level in levels.ordered.values():
        text = settings_file(include_log_level=False) + f"logLevel = {level}\n"
        values, error = parse(text, schema)
        check(f"logLevel={level} ({levels.labels[level]}) is accepted", values is not None, f"error={error!r}")

    # And a value outside the range must be rejected.
    text = settings_file(include_log_level=False) + "logLevel = 5\n"
    _, error = parse(text, schema)
    check("logLevel=5 is rejected", error == "Invalid setting: logLevel", f"got {error!r}")

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== settings migration checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
