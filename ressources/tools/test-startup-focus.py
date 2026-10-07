# test-startup-focus.py
"""Test the deterministic models behind grouped startup hiding and Focus peek.

The game owns widget construction and pawn reflection, so those integration
points still need an in-game session. The policy below does not: these checks
exercise the shipped Lua models directly and keep their key contracts from
regressing:

* a baseline is released only after every configured ordinary group resolves;
* an alternate player form can prove the stats group ready without joining the
  Quiet Dawn dismissal wave itself;
* a Fixed 0% or Always Hidden ordinary panel joins that startup wave, while
  positive Fixed Opacity still does not delay it; and
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

    def opacities(value=1, **overrides):
        result = {name: value for name in baseline_names}
        result.update(overrides)
        return lua.table_from(result)

    # --- Startup barrier -------------------------------------------------
    barrier = barrier_model.new(modes(1), opacities(), 12.5)
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
    alternate = barrier_model.new(modes(0, HumanStats=1, VampireStats=0), opacities(), 0)
    check("only the Quiet Dawn form is a startup fade member", alternate["members"]["HumanStats"] == 1 and alternate["members"]["VampireStats"] is None)
    check("the Vanilla alternate remains a readiness watcher", alternate["watchers"]["VampireStats"] == 1)
    check("the Vanilla alternate can resolve the shared stats position", barrier_model.resolve(alternate, "VampireStats") == 1)
    check("that alternate-form resolution requests the release", alternate["releasePending"] is True)

    fixed_visible = barrier_model.new(modes(2), opacities(1), 0)
    check("positive Fixed Opacity baseline panels do not wait for a Quiet Dawn release", fixed_visible["active"] is False)
    fixed_hidden = barrier_model.new(modes(2), opacities(0), 0)
    check("Fixed 0% baseline panels join the coordinated startup fade", fixed_hidden["active"] is True and fixed_hidden["members"]["XPBar"] is not None)
    always_hidden = barrier_model.new(modes(3), opacities(1), 0)
    check("Always Hidden baseline panels join the coordinated startup fade", always_hidden["active"] is True and always_hidden["members"]["WBP_Compass"] is not None)
    check("a baseline model contains no guessed timeout field", fixed_hidden["timeout"] is None and fixed_hidden["deadline"] is None)

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
    mode = rows["mode_WBP_AA_Quickslots"]
    check("panel modes include explicit Always Hidden", sorted(mode["values"].values()) == [0, 1, 2, 3])

    settings_model = (SCRIPTS / "SettingsModel.lua").read_text()
    gameplay = (SCRIPTS / "Gameplay.lua").read_text()
    check("selector option 2 maps to named Focus intent", "values.peekOnFocusMode=values.manualPeek==2" in settings_model)
    check("the retired Focus-exit selector name is absent", "peekOnFocusExit" not in settings_model and "peekOnFocusExit" not in gameplay)
    check("Gameplay samples the Focus model from the pawn snapshot", "runtime.observeFocusPeek(pawn)" in gameplay)
    check("the confirmed Focus-release event wakes a snapshot rather than revealing directly", "statsPending=true\n            wake(\"resource\")" in gameplay)
    check("an active Focus reveal has no timed expiry deadline", "peekVisible and not peekStartPending and peekUntil>0 and peekUntil" in gameplay)
    check("live panel mode and either HUD Peek policy request one complete reconciliation", "if changedPanelCount>0 or changedPeekPanelCount>0 then\n        fullPending=true\n        dirty=true" in gameplay)
    check("the Focus prompt class is logged before its graph hook is added", "Focus probe: promptClass=" in gameplay)
    check("the verified Focus prompt graph wakes a pawn snapshot on entry", "runtime.focusPromptGraph" in gameplay and "function runtime.focusPromptEvent" in gameplay and "focusPromptWakes" in gameplay)
    check("the Focus graph is queued for every enabled Show HUD trigger, not only Focus", "if manualPeekEnabled then\n    -- Register this verified graph" in gameplay)
    check("per-panel Show HUD inclusion defaults preserve every eligible panel", rows["showHUD_HumanStats"]["default"] == 1 and "values.showHUDPanels={}" in settings_model)
    check("Fixed Opacity HUD Peek raises default off to preserve existing fixed panels", rows["fixedPeek_HumanStats"]["default"] == 0 and "values.fixedPeekPanels={}" in settings_model)
    check("an excluded panel retains its Quiet Dawn target during Show HUD", "config.showHUDPanels[name]~=false" in gameplay)
    check("a Fixed Opacity panel raises only after explicit HUD Peek opt-in", "config.fixedPeekPanels[name]==true" in gameplay)
    check("Focus configuration and registration state are logged decisively", "Focus hook setup: Show HUD=%s manualPeek=%s eligible=%s registration=%s" in gameplay)
    check("a queued Focus fade keeps its worker alive until the wave flushes", "or runtime.fadeWaveSize>0 or timeRequested" in gameplay)
    check("mid-session fade investigation records the startup-immediate route at Info", "startupImmediateFadeBypass" in gameplay and "runtime.hudAdoptionSource" in gameplay and "if fade.enabled() and not runtime.startupImmediateNoted then" in gameplay)
    check("each Show HUD edge resets the settled target before its one configured fade", "if changed then\n            runtime.peekSettled={}\n            peekDirty=true" in gameplay)
    check("a stock refresh reasserts a settled held peek directly instead of starting another fade wave", "if peekVisible and runtime.peekSettled[name] and peekPanel(name) then\n        fade.forget(name)\n        local wrote=panelOpacity.apply(entry.lease,target)" in gameplay)
    check("a refresh already at its target cannot enqueue a no-op fade wave", "local current=entry.object:GetRenderOpacity()" in gameplay and "if math.abs(current-target)>1e-5 then" in gameplay and "panelFadeSatisfiedByStock" in gameplay)
    check("the wave log counts only transitions that actually became active", "if not wasActive and fade.active(name) then started=started+1 end" in gameplay and "panelFadeNoopWaves" in gameplay)
    check("only a completed fade marks an active peek panel settled", "if peekVisible and peekPanel(name) and math.abs(value-target)<=1e-5 then\n        runtime.peekSettled[name]=true" in gameplay)
    check("session, expiry and live-settings boundaries clear held-peek settlement", gameplay.count("runtime.peekSettled={}") >= 7, f"resets={gameplay.count('runtime.peekSettled={}')}")
    check("the paused-fade pacing guard remains ahead of visibility work", "if pace==\"paused\" then" in gameplay and "holding fade" in gameplay)
    check("resolved Activation Charges tree, slot, write, timer and Pop diagnostics are retired", "focusChargePopTrace" not in gameplay and "focusChargeSlotProbe" not in gameplay and "vanillaQuickslotsTree" not in gameplay and "vanillaCombatPanel source=" not in gameplay)
    check("Activation Charges mediates only the measured common DynamicEntryBox at Vanilla Push/Pop boundaries", "function runtime.beginFocusChargeFade" in gameplay and "runtime.focusChargeFadeKey=\"vanilla:FocusChargeDynamicEntryBox\"" in gameplay and "source==\"PushHUDPreset\" and 1 or source==\"PopHUDPreset\" and 0" in gameplay and "runtime.beginFocusChargeFade(source)" in gameplay)
    check("Activation Charges leaves Vanilla untouched when Fade is off or its Debug locator is explicitly active", "if target==nil or not config.fadeTransitions" in gameplay and "(config.debugFocusChargeLocator and D.debugLogging)" in gameplay and "panelModes.WBP_HUD_FocusCharge_Bar~=Modes.VANILLA then return end" in gameplay)
    check("Activation Charges uses the opacity lease and shared game-time fade pacing without a polling loop", "focusChargeFade.step(runtime.focusChargeFadeKey,current,target)" in gameplay and "panelOpacity.bind,box" in gameplay and "runtime.focusChargeFadePending" in gameplay and "focusFading=pcall(runtime.focusChargeFadePending)" in gameplay)
    check("a hidden Activation Charges lease is restored on settings or HUD/session boundaries", "function runtime.resetFocusChargeFade" in gameplay and "Session.onClose(runtime.resetFocusChargeFade)" in gameplay and "runtime.resetFocusChargeFade()" in gameplay and "panelOpacity.restore,entry.lease" in gameplay)
    check("Activation Charges retimes only its verified reverse FadeIn proxy while a nonzero Vanilla Fade is active", "function runtime.mediateFocusChargeFadeOut" in gameplay and "not config.fadeTransitions" in gameplay and "panelModes.WBP_HUD_FocusCharge_Bar~=Modes.VANILLA" in gameplay and "fadeOutSeconds<=0" in gameplay and "playMode~=FOCUS_CHARGE_REVERSE_PLAY_MODE" in gameplay and "animationName~=FOCUS_CHARGE_FADE_IN" in gameplay and "FOCUS_CHARGE_STOCK_FADE_SECONDS/fadeOutSeconds" in gameplay and "playbackSpeedParam:set(rate)" in gameplay and "focusChargeAnimationProxyEvent" in gameplay)
    check("the production proxy hook stays singular and gives the three unresolved combat panels a finite exact-owner trace", gameplay.count('\"/Script/UMG.WidgetAnimationPlayCallbackProxy:CreatePlayAnimationProxyObject\"') == 1 and "COMBAT_HUD_FADE_PANELS" in gameplay and "WBP_HUD_Quickslots_ChangePrompt" in gameplay and "function runtime.traceCombatHudAnimationProxy" in gameplay and "animation:GetEndTime()" in gameplay and "combatHudAnimationTrace panel=%s" in gameplay and "runtime.combatHudAnimationTraceRemaining=12" in gameplay)
    check("the remaining combat HUD proxy trace is Debug-only, named-owner-only and never writes parameters", "if remaining<=0 or not D.debugLogging or not config.fadeTransitions or not valid(hud) then return end" in gameplay and "sameObject(widget,owner)" in gameplay and "runtime.combatHudAnimationTraceRemaining=remaining-1" in gameplay and "function runtime.traceCombatHudAnimationProxy" in gameplay and "playbackSpeedParam:set" not in gameplay[gameplay.index("function runtime.traceCombatHudAnimationProxy"):gameplay.index("function runtime.mediateFocusChargeFadeOut")])
    check("the visual locator remains explicit, finite and tests its common DynamicEntryBox container before four bounded runtime slots", "config.debugFocusChargeLocator" in gameplay and "function runtime.focusChargeLocatorContainer" in gameplay and "box:GetAllEntries()" in gameplay and "kind=\"container\"" in gameplay and "runtime.focusChargeLocatorMaxEntries=4" in gameplay and "runtime.focusChargeLocatorHideMs=2000" in gameplay and "runtime.focusChargeLocatorGapMs=1000" in gameplay and "runtime.focusChargeLocatorArmed=false" in gameplay and "Session.onClose(function()" in gameplay and "runtime.stopFocusChargeLocator(\"session close\")" in gameplay)


    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== startup barrier and Focus checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
