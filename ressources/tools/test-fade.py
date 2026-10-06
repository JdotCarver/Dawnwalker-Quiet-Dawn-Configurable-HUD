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
    load_module = lua.eval("function(path) return dofile(path) end")
    module = load_module(str(SCRIPTS / "QuietDawnFade.lua"))
    pacing_module = load_module(str(SCRIPTS / "QuietDawnFadePacing.lua"))

    clock = {"now": 100.0}

    diagnostics = lua.table_from({
        "now": lambda: clock["now"],
        "debugLogging": False,
    })

    def new_fade(enabled=True, fade_in=0.2, fade_out=0.4):
        # The second argument is the clock. In the mod this is game time, not
        # the diagnostics clock: os.clock is processor time, too coarse and
        # not proportional to wall time, which makes a fade stutter.
        fade = module.new(diagnostics, lambda: clock["now"])
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

    # --- Game time stopping must not strand the worker -------------------
    # Game time stops while the game is paused or the window is in the
    # background. A time-based expiry can therefore never fire in exactly the
    # situation where a stuck worker hurts most, which is why transitions also
    # count the worker calls they survive.
    fade = new_fade()
    clock["now"] = 800.0
    fade.step("p", 0.0, 1.0)
    for _ in range(2100):
        if not fade.pending():
            break
    check(
        "a frozen clock cannot keep a transition alive forever",
        not fade.pending(),
        "pending() stayed true with the clock stopped: the worker would never sleep",
    )

    # --- Game time restarting (a new world) ------------------------------
    fade = new_fade()
    clock["now"] = 900.0
    fade.step("p", 0.0, 1.0)
    clock["now"] = 5.0  # a fresh level: game time counts from zero again
    check("a transition from the previous world is dropped", not fade.pending())

    clock["now"] = 900.0
    fade.step("p", 0.0, 1.0)
    clock["now"] = 3.0
    restarted = fade.step("p", 0.25, 1.0)
    check(
        "a fade continues sanely after game time restarts",
        abs(restarted - 0.25) < 1e-9,
        f"got {restarted}",
    )

    # --- An unusable clock falls back to instant -------------------------
    fade = module.new(diagnostics, lambda: None)
    fade.configure(True, 0.2, 0.4)
    check("without a clock the target is applied immediately", fade.step("p", 0.0, 1.0) == 1.0)
    check("without a clock nothing is left pending", not fade.pending())

    # --- Pause pacing: frames can advance while game time is frozen ------
    # Dawnwalker's pause menu continues rendering, so frame count alone cannot
    # prove that a game-time fade is progressing. The worker must hold the
    # transition after several independent rendered frames at the same game
    # time, then continue it without a target jump when the clock moves again.
    pacing = pacing_module.new(4)
    state = pacing.observe(100, 50.0, True)
    check("the first active fade frame is not treated as paused", state == "active")
    for frame in (101, 102, 103):
        state = pacing.observe(frame, 50.0, True)
    check("a few same-time rendered frames are tolerated", state == "active")
    state = pacing.observe(104, 50.0, True)
    check("four rendered frames with frozen game time hold the fade", state == "paused" and pacing.paused())
    state = pacing.observe(105, 50.0, True)
    check("the held fade stays paused without advancing its transition", state == "paused")
    state = pacing.observe(106, 50.01, True)
    check("game time advancing resumes the held fade", state == "resumed" and not pacing.paused())
    state = pacing.observe(107, 50.02, False)
    check("a finished fade clears pause pacing state", state == "inactive" and not pacing.paused())

    # --- Lockstep: a group started in one call moves as one -------------
    # The symptom this guards against is panels dissolving raggedly, one
    # element at a time, because each transition began at a different moment.
    clock = {"now": 100.0}
    fade = module.new(diagnostics, lambda: clock["now"])
    fade.configure(True, 0.4, 0.4)
    check("fading reports itself as enabled", fade.enabled())
    check("an untouched key is not active", not fade.active("a"))
    for key in ("a", "b", "c"):
        fade.step(key, 1.0, 0.0)
    check("every key in the group is now active", all(fade.active(k) for k in "abc"))

    clock["now"] = 100.2  # halfway
    values = [fade.step(key, 1.0, 0.0) for key in ("a", "b", "c")]
    check(
        "panels started together hold identical opacity mid-fade",
        max(values) - min(values) < 1e-9,
        f"got {values}",
    )
    check("and are genuinely mid-transition, not snapped", 0.0 < values[0] < 1.0)

    # The same group started across separate calls is what used to happen.
    clock = {"now": 200.0}
    fade = module.new(diagnostics, lambda: clock["now"])
    fade.configure(True, 0.4, 0.4)
    fade.step("a", 1.0, 0.0)
    clock["now"] = 200.05  # the next panel is visited a worker call later
    fade.step("b", 1.0, 0.0)
    clock["now"] = 200.2
    staggered = [fade.step(k, 1.0, 0.0) for k in ("a", "b")]
    check(
        "staggered starts do drift apart, which is the bug being prevented",
        abs(staggered[0] - staggered[1]) > 1e-3,
        f"got {staggered}",
    )

    fade.configure(False, 0.4, 0.4)
    check("fading reports itself as disabled once switched off", not fade.enabled())
    check("disabled fading leaves nothing active", not fade.active("a"))

    # --- The deferred-wave rule ----------------------------------------
    # A model of the batching rule in Gameplay.step(), not the code itself.
    # It is here because this rule has now been got wrong twice: first the
    # flush lived only at the end of the discovery pass, so a manual peek --
    # which never runs that pass -- deferred its panels and never started
    # them, leaving the HUD hidden permanently. The invariant worth pinning
    # is simply: a non-empty wave always starts within a bounded number of
    # calls, whatever the caller is doing.
    lua = module  # reuse the same runtime
    del lua
    wave = {"size": 0, "last": 0, "idle": 0, "flushed": []}

    def tick(added):
        wave["size"] += added
        if wave["size"] > 0:
            if wave["size"] > wave["last"]:
                wave["last"], wave["idle"] = wave["size"], 0
            else:
                wave["idle"] += 1
                if wave["idle"] >= 2:
                    wave["flushed"].append(wave["size"])
                    wave["size"], wave["last"], wave["idle"] = 0, 0, 0

    # A discovery pass adds one panel per call, then stops.
    for _ in range(16):
        tick(1)
    check("a growing wave does not start early", wave["flushed"] == [])
    tick(0); tick(0)
    check("the group starts once it stops growing", wave["flushed"] == [16],
          f"got {wave['flushed']}")

    # A peek defers everything in one call and never runs the pass.
    wave.update(size=0, last=0, idle=0, flushed=[])
    tick(9)
    for _ in range(4):
        tick(0)
    check("a peek's group starts without any pass running", wave["flushed"] == [9],
          f"got {wave['flushed']}")

    # Bounded: whatever happens, an idle wave cannot outlive a few calls.
    wave.update(size=0, last=0, idle=0, flushed=[])
    tick(1)
    calls = 0
    while not wave["flushed"] and calls < 10:
        tick(0); calls += 1
    check("a wave always starts within a few idle calls", bool(wave["flushed"]),
          f"never flushed after {calls} calls")

    gameplay = (REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts/Gameplay.lua").read_text()
    check(
        "background enemy-bar work yields while a player-HUD fade is active",
        "if not fade.pending() and enemyBars.ready()" in gameplay,
    )

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== fade checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
