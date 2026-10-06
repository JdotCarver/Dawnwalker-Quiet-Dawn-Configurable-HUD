# test-startup-focus.py
"""Test the deterministic models behind grouped startup hiding and Focus peek.

The game owns widget construction and pawn reflection, so those integration
points still need an in-game session. The policy below does not: these checks
exercise the shipped Lua models directly and keep their key contracts from
regressing:

* a baseline is released only after every configured ordinary group resolves;
* an alternate player form can prove the stats group ready without joining the
  Quiet Dawn dismissal wave itself;
* no configured Quiet Dawn baseline means no waiting state; and
* Focus entry holds the peek while its false transition requests one timed hold.

Usage:
    python3 ressources/tools/test-startup-focus.py
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


def multiple(result):
    """Normalise Lupa's one-value and multiple-value return conventions."""
    return result if isinstance(result, tuple) else (result,)


def main():
    try:
        from lupa import lua54
    except ImportError:
        print("!! lupa is not installed. Run:")
        print("     bash ressources/tools/setup.sh")
        return 2

    lua = lua54.LuaRuntime()
    load_module = lua.eval("function(path) return dofile(path) end")
    barrier_model = load_module(str(SCRIPTS / "QuietDawnStartupBarrier.lua"))
    focus_model = load_module(str(SCRIPTS / "QuietDawnFocusPeek.lua"))

    baseline_names = (
        "HumanStats",
        "VampireStats",
        "XPBar",
        "WBP_Compass",
        "WBP_HUD_QuestInfo",
        "WBP_HUD_Quickslots",
        "WBP_AA_Quickslots",
        "WBP_HudTimer",
    )

    def modes(value=0, **overrides):
        result = {name: value for name in baseline_names}
        result.update(overrides)
        return lua.table_from(result)

    # --- Startup barrier -------------------------------------------------
    barrier = barrier_model.new(modes(1), 12.5)
    check("all default Quiet Dawn baseline positions form seven groups", barrier["groups"] == 7)
    check("the barrier retains its real game-time starting point", barrier["startedAt"] == 12.5)
    check("an enabled baseline begins active", barrier["active"] is True)
    check("the Human and Vampire stats forms share one group", barrier["members"]["HumanStats"] == barrier["members"]["VampireStats"])

    first_group = barrier_model.resolve(barrier, "HumanStats")
    check("the first observed panel resolves its own group", first_group == 1)
    check("one stats form is enough to resolve the shared stats group", barrier["remaining"] == 6)
    check("the alternate stats form cannot resolve that group twice", barrier_model.resolve(barrier, "VampireStats") is None)

    for name in (
        "XPBar",
        "WBP_Compass",
        "WBP_HUD_QuestInfo",
        "WBP_HUD_Quickslots",
        "WBP_AA_Quickslots",
        "WBP_HudTimer",
    ):
        barrier_model.resolve(barrier, name)
    check("the final ordinary group requests exactly one release", barrier["releasePending"] is True)
    check("all groups are accounted for before release", barrier["remaining"] == 0)

    # Quiet Dawn for only one stats form must still recognise the player's
    # currently constructed alternate form. That alternate only watches; it
    # never joins the opacity wave and therefore keeps its own vanilla setting.
    alternate = barrier_model.new(modes(0, HumanStats=1, VampireStats=0), 0)
    check("only the Quiet Dawn form is a startup fade member", alternate["members"]["HumanStats"] == 1 and alternate["members"]["VampireStats"] is None)
    check("the Vanilla alternate remains a readiness watcher", alternate["watchers"]["VampireStats"] == 1)
    check("the Vanilla alternate can resolve the shared stats position", barrier_model.resolve(alternate, "VampireStats") == 1)
    check("that alternate-form resolution requests the release", alternate["releasePending"] is True)

    fixed_only = barrier_model.new(modes(2), 0)
    check("Fixed-opacity baseline panels do not wait for a Quiet Dawn release", fixed_only["active"] is False)
    check("a baseline model contains no guessed timeout field", fixed_only["timeout"] is None and fixed_only["deadline"] is None)

    # --- Focus state machine ---------------------------------------------
    state, edge = multiple(focus_model.transition(None, True))
    check("the first active Focus sample enters the hold", state is True and edge == "entered")
    state, edge = multiple(focus_model.transition(state, True))
    check("continued Focus does not restart the hold", state is True and edge is None)
    state, edge = multiple(focus_model.transition(state, False))
    check("Focus exit emits one timed-peek edge", state is False and edge == "exited")
    state, edge = multiple(focus_model.transition(state, False))
    check("continued non-Focus does not emit repeated exits", state is False and edge is None)
    state, edge = multiple(focus_model.transition(True, None))
    check("an unreadable Focus field cannot fabricate an exit", state is True and edge is None)

    # --- Selector and integration contracts ------------------------------
    schema = load_module(str(SCRIPTS / "SettingsSchema.lua"))
    rows = {row["key"]: row for row in schema.values()}
    peek = rows["manualPeek"]
    check("the Show HUD selector still accepts Off, legend hold and Focus", sorted(peek["values"].values()) == [0, 1, 2])

    settings_model = (SCRIPTS / "SettingsModel.lua").read_text()
    gameplay = (SCRIPTS / "Gameplay.lua").read_text()
    check("selector option 2 maps to named Focus intent", "values.peekOnFocusMode=values.manualPeek==2" in settings_model)
    check("the retired Focus-exit selector name is absent", "peekOnFocusExit" not in settings_model and "peekOnFocusExit" not in gameplay)
    check("Gameplay samples the Focus model from the pawn snapshot", "runtime.observeFocusPeek(pawn)" in gameplay)
    check("the confirmed Focus-release event wakes a snapshot rather than revealing directly", "statsPending=true\n            wake(\"resource\")" in gameplay)
    check("an active Focus reveal has no timed expiry deadline", "peekVisible and not peekStartPending and peekUntil>0 and peekUntil" in gameplay)
    check("live panel mode changes request one complete reconciliation", "if changedPanelCount>0 then\n        fullPending=true\n        dirty=true" in gameplay)

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== startup barrier and Focus checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
