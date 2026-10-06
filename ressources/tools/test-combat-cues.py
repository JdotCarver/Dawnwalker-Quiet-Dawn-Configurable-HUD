# test-combat-cues.py
"""Keep the combat-cue diagnostic boundary from becoming a behavior change.

The lock/dot indicator is a shared stock widget and must be tested in-game.
This lightweight contract test protects the diagnostic shape used to identify
stock event ordering and late UMG overwrites without adding a recurring poll.

Usage:
    python3 ressources/tools/test-combat-cues.py
"""

import pathlib
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parents[2]
GAMEPLAY = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts/Gameplay.lua"
COMBAT_CUES = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts/QuietDawnCombatCues.lua"

failures = []


def check(description, condition):
    if condition:
        print(f"ok   {description}")
    else:
        failures.append(description)
        print(f"FAIL {description}")


def main():
    gameplay = GAMEPLAY.read_text()
    combat_cues = COMBAT_CUES.read_text()

    check(
        "each marker hook carries its exact source into the safe worker job",
        "markerEvent(context,source)" in gameplay
        and "rememberMarkerSource(job,source)" in gameplay,
    )
    check(
        "per-hook source counts remain available in the Debug summary",
        'D.count("markerEvent_"..source)' in gameplay,
    )
    check(
        "the probe records the stock state and Quiet Dawn target before a write",
        "combatCue probe event=%s icon=%s hardLock=%s" in gameplay
        and "beforeOpacity=%.3f targetOpacity=%d wrote=%s" in gameplay,
    )
    check(
        "the probe makes only one delayed overwrite verification, never a poll",
        "ExecuteInGameThreadWithDelay,16,function()" in gameplay
        and "it is intentionally not a recurring poll" in gameplay,
    )
    check(
        "the cue classifier exposes raw hard-lock state without changing its decision",
        "local hardLock=object.bHardLockEnabled==true" in combat_cues
        and "entry.cueHardLock,entry.cueHideDirections=hardLock,hideDirections" in combat_cues
        and "entry.cueShown=arrow~=nil or unblockable or lock or marker" in combat_cues,
    )
    check(
        "the verified hard-lock graph entry wakes the normal presentation path",
        "local markerHardLockEntry=1370" in gameplay
        and "if tonumber(unwrap(entryParam))~=markerHardLockEntry then return end" in gameplay
        and "markerEvent(context,\"HardLockToggle\")" in gameplay,
    )
    check(
        "unrelated indicator graph entries stay diagnostic-only",
        'if D.debugLogging then noteUbergraphEntry("WBP_CombatTargetIndicator",entryParam) end' in gameplay,
    )
    check(
        "the lock transition receives a finite next-frame worker handoff",
        "if markerUrgent then return runtime.workerFadeMs end" in gameplay
        and "markerUrgent=false" in gameplay,
    )
    check(
        "queued marker corrections run before prompts and time sampling",
        gameplay.index("if markersReady() and (markerUrgent or markerTurn or (cursor==0 and not dirty)) then")
        < gameplay.index("if promptsReady() and promptTurn then")
        < gameplay.index("if timeSampleTurn and timeWatcher"),
    )

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== combat-cue diagnostic checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
