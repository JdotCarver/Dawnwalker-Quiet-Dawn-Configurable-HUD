#!/usr/bin/env python3
"""ressources/tools/test-fade.py

Exercise QuietDawnFade against a controllable clock, without the game.

Why this exists
---------------
Fading is the one part of this mod that depends on time passing, which makes
it the one part that cannot be checked by reading it. Two defects shipped
before this test existed, and both are cheap to catch here:

  * a transition whose panel stopped being written was never retired, so
    pending() stayed true and the worker never went back to sleep -- turning
    an event-driven mod into a permanent 50 Hz tick;
  * every panel advanced in a separate worker call, so a fade ran at the
    worker's rate divided by the panel count and the panels drifted apart.

The module takes its clock from D.now(), so a fake D makes all of this
deterministic.

Setup (once per sandbox):
    bash ressources/tools/setup.sh

Usage:
    python3 ressources/tools/test-fade.py
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
        print("     bash ressources/tools/setup.sh")
        return 2

    lua = lua54.LuaRuntime()
    module = lua.eval("function(path) return dofile(path) end")(str(SCRIPTS / "QuietDawnFade.lua"))

    clock = {"now": 100.0}

    diagnostics = lua.table_from({
        "now": lambda: clock["now"],
        "debugLogging": False,
    })

    def new_fade(enabled=True, fade_in=0.2, fade_out=0.4):
        fade = module.new(diagnostics)
        fade.configure(enabled, fade_in, fade_out)
        return fade

    # --- Disabled fading is a pass-through -------------------------------
    fade = new_fade(enabled=False)
    check("disabled fading returns the target immediately", fade.step("p", 0.0, 1.0) == 1.0)
    check("disabled fading reports nothing pending", not fade.pending())

    # --- A fade in walks from the current value to the target ------------
    fade = new_fade()
    clock["now"] = 100.0
    first = fade.step("p", 0.0, 1.0)
    check("a fade starts at the current opacity, not the target", first < 0.01, f"got {first}")
    check("a started fade is pending", fade.pending())

    clock["now"] = 100.1  # halfway through a 0.2s fade in
    middle = fade.step("p", first, 1.0)
    check("a fade is halfway at half its duration", abs(middle - 0.5) < 1e-9, f"got {middle}")

    clock["now"] = 100.2
    landed = fade.step("p", middle, 1.0)
    check("a fade lands exactly on its target", landed == 1.0, f"got {landed}")
    check("a landed fade is no longer pending", not fade.pending())

    # --- Direction picks the right duration ------------------------------
    fade = new_fade()
    clock["now"] = 200.0
    fade.step("p", 1.0, 0.0)
    clock["now"] = 200.2  # half of the 0.4s fade out
    out_middle = fade.step("p", 1.0, 0.0)
    check("fading out uses the fade-out duration", abs(out_middle - 0.5) < 1e-9, f"got {out_middle}")

    # --- Reversal starts from where the panel actually is ----------------
    fade = new_fade()
    clock["now"] = 300.0
    fade.step("p", 0.0, 1.0)
    clock["now"] = 300.1
    halfway = fade.step("p", 0.0, 1.0)
    reversed_first = fade.step("p", halfway, 0.0)
    check(
        "reversing mid-fade continues from the current opacity, it does not jump",
        abs(reversed_first - halfway) < 1e-9,
        f"got {reversed_first} from {halfway}",
    )

    # --- A zero duration is instant --------------------------------------
    fade = new_fade(fade_in=0)
    clock["now"] = 400.0
    check("a zero fade-in duration is instant", fade.step("p", 0.0, 1.0) == 1.0)
    check("a zero duration leaves nothing pending", not fade.pending())

    # --- THE ORPHAN LEAK --------------------------------------------------
    # A panel that stops being written must not hold the worker open. This is
    # the defect that turned the mod into a permanent tick.
    fade = new_fade()
    clock["now"] = 500.0
    fade.step("p", 0.0, 1.0)
    check("the abandoned transition is pending while it could still finish", fade.pending())
    clock["now"] = 500.3  # past the 0.2s duration, inside the grace period
    check("it is still pending just after its duration", fade.pending())
    clock["now"] = 505.0  # long past duration + grace
    check(
        "an abandoned transition expires instead of keeping the worker awake",
        not fade.pending(),
        "pending() stayed true for a panel nobody is writing any more",
    )

    # --- forEach visits every fading key, and retiring one is safe -------
    fade = new_fade()
    clock["now"] = 600.0
    for name in ("a", "b", "c"):
        fade.step(name, 0.0, 1.0)
    visited = []
    fade.forEach(lambda key: visited.append(key))
    check("forEach visits every fading panel", sorted(visited) == ["a", "b", "c"], f"got {sorted(visited)}")

    # Retiring entries during the visit must not disturb the traversal: this
    # is exactly what happens when a panel's fade lands inside panelStep.
    clock["now"] = 600.5
    retired = []

    def land(key):
        fade.step(key, 0.5, 1.0)
        retired.append(key)

    fade.forEach(land)
    check("every panel still gets visited when they all land at once", sorted(retired) == ["a", "b", "c"])
    check("all three transitions retired together", not fade.pending())

    # --- Reconfiguring drops transitions ---------------------------------
    fade = new_fade()
    clock["now"] = 700.0
    fade.step("p", 0.0, 1.0)
    fade.configure(True, 1.0, 1.0)
    check("changing the settings does not strand a half-finished fade", not fade.pending())

    # --- An unusable clock falls back to instant -------------------------
    stopped = lua.table_from({"now": lambda: None, "debugLogging": False})
    fade = module.new(stopped)
    fade.configure(True, 0.2, 0.4)
    check("without a clock the target is applied immediately", fade.step("p", 0.0, 1.0) == 1.0)
    check("without a clock nothing is left pending", not fade.pending())

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== fade checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
