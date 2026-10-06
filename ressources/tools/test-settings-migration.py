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

    # --- Upgrade steps must supply a default for every key they add -------
    #
    # ensure() fills a missing key from the `defaults` table handed to it and
    # NEVER from the schema. Given no entry it returns "Missing setting: <key>"
    # and the entire load fails, which is how a shipped build rejected every
    # existing settings.ini. This mirrors ensure()'s parse/patch loop without
    # touching the filesystem.
    def ensure_dry_run(text, dry_schema, dry_defaults):
        values, error = None, None
        for _ in range(len(list(dry_schema.values())) + 1):
            values, error = parse(text, dry_schema)
            if values is not None:
                return values, None
            missing = error and error.startswith("Missing setting: ")
            key = error[len("Missing setting: "):] if missing else None
            if key is None or dry_defaults.get(key) is None:
                return None, error
            text += f"{key} = {dry_defaults[key]}\n"
        return None, error

    # A settings.ini from before per-panel Show HUD inclusion: all existing
    # settings must parse under the strict predecessor, then add thirteen
    # default-on choices without changing any established peek behavior.
    rows = {row["key"]: row for row in schema.values()}
    show_hud_keys = tuple(key for key in rows if key.startswith("showHUD_"))
    pre_show_hud = "[Settings]\n" + "".join(
        f"{key} = {row['default']}\n" for key, row in rows.items() if key not in show_hud_keys
    )
    pre_show_schema = lua.table_from([row for row in schema.values() if not row["key"].startswith("showHUD_")])
    values, error = parse(pre_show_hud, pre_show_schema)
    check(
        "a pre-Show-HUD settings.ini parses under the strict predecessor",
        values is not None,
        f"error={error!r}",
    )
    values, error = ensure_dry_run(pre_show_hud, schema, {key: 1 for key in show_hud_keys})
    check(
        "default-on Show HUD inclusions upgrade instead of rejecting existing settings",
        values is not None,
        f"error={error!r}",
    )
    settings_model = (SCRIPTS / "SettingsModel.lua").read_text()
    check(
        "SettingsModel starts the final upgrade from the strict pre-Show-HUD generation",
        "err and err:match('^Missing setting: showHUD_')" in settings_model
        and "Store.parse(text,preShowHUDSchema)" in settings_model
        and "'show-hud-inclusions'" in settings_model,
    )
    check(
        "Show HUD inclusion defaults preserve every existing peek target",
        len(show_hud_keys) == 13 and all(rows[key]["default"] == 1 for key in show_hud_keys),
        f"keys={show_hud_keys!r}",
    )

    # A settings.ini from before fading: every key the newest schema has,
    # except the three fading added.
    fade_keys = ("fadeTransitions", "fadeInSeconds", "fadeOutSeconds")
    pre_fade = "[Settings]\n" + "".join(
        f"{key} = {row['default']}\n" for key, row in rows.items() if key not in fade_keys
    )

    # The defaults SettingsModel derives from the schema for that step.
    fade_defaults = {key: rows[key]["default"] for key in fade_keys}
    values, error = ensure_dry_run(pre_fade, schema, fade_defaults)
    check(
        "a pre-fade settings.ini upgrades instead of being rejected",
        values is not None,
        f"error={error!r}",
    )

    # And the failure mode that actually shipped, so the test proves it would
    # have been caught: the same step with no defaults at all.
    values, error = ensure_dry_run(pre_fade, schema, {})
    check(
        "the same upgrade with no defaults is correctly detected as broken",
        values is None and (error or "").startswith("Missing setting: "),
        f"got values={values is not None} error={error!r}",
    )

    # --- HUD peek trigger (item 6) ---------------------------------------
    # manualPeek widened from {0,1} to {0,1,2}. Both old values must keep
    # their exact meaning, which is what makes this safe without a migration
    # step: an existing file already holds a value the new schema accepts.
    peek = rows["manualPeek"]
    accepted = sorted(peek["values"].values())
    check("the peek trigger offers three options", accepted == [0, 1, 2], f"got {accepted}")
    check("its default is unchanged", peek["default"] == 1, f"got {peek['default']}")

    for legacy in (0, 1):
        text = settings_file(include_log_level=True).replace(
            "manualPeek = 1", f"manualPeek = {legacy}"
        )
        values, error = parse(text, schema)
        check(
            f"an existing settings.ini with manualPeek={legacy} is still accepted",
            values is not None,
            f"error={error!r}",
        )

    text = settings_file(include_log_level=True).replace("manualPeek = 1", "manualPeek = 3")
    _, error = parse(text, schema)
    check(
        "manualPeek=3 is rejected",
        error == "Invalid setting: manualPeek",
        f"got {error!r}",
    )

    # --- Fading (item 7) ------------------------------------------------
    # The three keys must exist in the schema with behaviour-preserving
    # defaults, so an existing settings.ini that gains them does not suddenly
    # start animating.
    rows = {row["key"]: row for row in schema.values()}
    for key, default in (("fadeTransitions", 0), ("fadeInSeconds", 0.22), ("fadeOutSeconds", 0.45)):
        row = rows.get(key)
        check(f"{key} is declared in the schema", row is not None)
        if row is not None:
            check(
                f"{key} defaults to {default}",
                abs(float(row["default"]) - default) < 1e-9,
                f"got {row['default']!r}",
            )

    # Fading off is the default, so nothing changes for an existing player.
    check("fading is off by default", float(rows["fadeTransitions"]["default"]) == 0)

    # Fade durations are continuous, not a discrete grid: a 0.01-step slider
    # emits values such as 1.1300000000000001 that no grid can match.
    for key in ("fadeInSeconds", "fadeOutSeconds"):
        row = rows[key]
        check(f"{key} is a continuous range, not a value grid", row["values"] is None)
        wanted = float(row["default"])
        check(
            f"{key}'s default lies inside its range",
            row["min"] is not None and row["min"] <= wanted <= row["max"],
        )

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== settings migration checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
