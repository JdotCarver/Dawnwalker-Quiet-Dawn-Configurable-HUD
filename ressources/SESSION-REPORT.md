# Session report — Quiet Dawn Configurable HUD

Living document. Updated as work lands, so it can be handed to Camille at the
end of the session alongside the branch.

Branch: `arena/01a10d4b-dawnwalker-quiet-dawn-configur`
Base: `a2b3430`

Every commit is self-contained and cherry-pickable. Nothing here requires
taking anything else, with one exception noted under *Dependencies between
commits* below.

---

## Licensing and portability (researched 2026-10-06)

Recorded because it determines what can be built on what, and the answer is
the opposite of what was assumed.

### Quiet Dawn - Configurable HUD: MIT

`LICENSE` is MIT, "Copyright (c) 2026 my-mods", and the Nexus page repeats it.
That grants use, copy, modify, merge, publish, distribute, sublicense and
sell, with one obligation: preserve the copyright and permission notice.

**There is no legal red tape here.** The conventions this session has
followed -- untouched vendored modules, `ue4ss-common.lock.json` kept in
sync, atomic cherry-pickable commits -- are *contribution* conventions. They
exist only so Camille can take individual commits. A private fork owes none
of them.

### Dynamic HUD (Nexus mod 344, by Koriik): all rights reserved

The Nexus permissions are explicit:

* **Modification permission** -- *"You must get permission from me before you
  are allowed to modify my files to improve it"*
* **Asset use permission** -- *"You must get permission from me before you
  are allowed to use any of the assets in this file"*
* Conversion to other games: forbidden outright.

No licence file ships with it, so the default is all rights reserved.
Publishing a patched Dynamic HUD requires Koriik's permission first.

### It is also not abandonware

* Original upload **8 September 2026**, last updated **11 September 2026**.
* Three releases (1.1, 1.2, 1.3) within four days.
* 79 forum posts, 1 open bug report, 1,910 unique downloads.

A quiet month after a burst of releases is weak evidence of abandonment for a
mod barely a month old. The local copy in `ressources/` is **1.0**; upstream
is **1.3**, and 1.3's changelog covers a health fade fallback, config auto
population, and an ability cooldown toggle.

### Consequence

The direction of least friction runs the other way. Reusing Quiet Dawn's
MIT-licensed modules needs only an attribution notice; modifying Dynamic HUD
needs a person to say yes first.

## Bugs fixed

### Fading stuttered because of the clock, not the algorithm

Worth recording as a general rule for this codebase. `D.now()` is `os.clock`:
processor time consumed by the process, granularity about 15.6 ms on Windows,
no fixed relationship to wall time. The diagnostics header has always said so
-- *"clock=os.clock; phase timings overlap and are not engine frame times"*.
It is the right clock for comparing phase costs and the wrong one for
animating anything.

The mod already had the right clock and used it for the peek and time-of-day
holds: `GetGameTimeInSeconds`. Fading now takes the same one, injected by the
caller so the module still touches no UObject.

Game time is stoppable, which brings two consequences that are handled
explicitly:

* it **goes backwards** on a new world -- those transitions are dropped;
* it **freezes** while paused or alt-tabbed, so a time-based expiry can never
  fire in exactly the situation where a stuck worker hurts most. Transitions
  therefore also count the worker calls they survive and retire after 2000 of
  them whatever the clock says.

Beware when reading `slow phase=... elapsedMs=14.000` lines: values landing on
exactly 14/15/16 ms are the Windows timer granularity, not real cost.

### Commit hygiene slip

The game-time commit also contains an unrelated change: moving the class
default object guard out of `queueHealth` and into `healthStep`. Queuing runs
straight off `NotifyOnNewObject` during level load, on objects the engine may
still be constructing, and a reflected `GetFullName()` there is not safe --
a plausible contributor to the access violation seen on save load. It belongs
in its own commit; it was swept up by a `git add -A`. Recorded here rather
than rewritten, because the branch was already pushed.

### Still open: a crash on save load

`EXCEPTION_ACCESS_VIOLATION reading 0x0000000000000123` with an all-UE4SS
stack, plus hangs on alt-tab. Not yet attributed. The low address suggests a
field read off a near-null pointer, i.e. a destroyed or half-constructed
UObject. Two changes since then may bear on it -- the reflected call removed
from the load path, and the tick-based transition expiry -- but neither is
confirmed. Several other mods were loaded (CenterHUD, EasierParry, Save
Settings). **Next step is isolation: run with fading off, then with the mod
alone.**

### Confirmed: ubergraph entry 4026 is Focus LEAVE

Eight sightings, all `focusMode=false`, none during unrelated HUD activity.
It fires **twice** per release, so any consumer must debounce.

This is the useful half. The intent is to reveal the HUD once the player is
done with Focus, so a trigger on deactivation is what was wanted anyway.

Note that `slow phase=worker` lines appear on Focus *press* too. That is not
a hidden Focus hook: it is the ordinary resource callbacks (health, stamina,
focus charge) firing and waking the worker. It does mean that sampling
`bIsInFocusMode` on wakes the worker already receives would detect Focus
*entry* cheaply, if that is ever wanted.


### Fading rejected every existing settings.ini

The worst defect of the session, because backwards compatibility is the one
hard rule here. Adding the three fading keys made the mod refuse to load for
anyone who already had a `settings.ini`; it had to be deleted and recreated.

`ensure()` fills a missing key from the `defaults` table handed to it and
**never** from the schema. Given no entry it returns `Missing setting: <key>`
and the whole load fails. The fading step passed `{}`, assuming the schema's
own defaults applied. They are now derived from the schema so the two cannot
drift.

Fade durations also moved from a discrete 0.01 grid to a continuous clamped
range: a 0.01-step slider emits values such as `1.1300000000000001`, which no
grid of floats can match, so the grid was a second rejection waiting to
happen.

### Fading was jerky, out of step, and never let the worker sleep

Three defects, all visible in a single Debug log of a 2 s fade.

*One panel per worker call.* With ~50 worker calls a second and six panels
fading, each panel moved about eight times a second and they visibly arrived
at different moments. Every fading panel now advances inside one call, so one
call is one visual step.

*Transitions were never retired* when their panel stopped being written --
hidden, mode changed, widget gone. `pending()` then stayed true forever and
the worker never slept, turning an event-driven mod into a permanent 50 Hz
tick. This is what an idle log showing ~510 worker calls per ten seconds with
no events was, and the most likely cause of a hang when reloading a save.
Transitions now carry a deadline of their duration plus one second.

*Intermediate frames drowned the log*, tripping the events-per-second limiter
(129 suppressed events in the shipped log). They are counted as
`panelFadeFrames`; only the settled value is narrated.


### Diagnostic summaries were unreadable
`73fc7c2`

The periodic summary and the startup banner joined every field with `" | "`
into a single line that ran to several hundred characters. Each field now
prints on its own line, indented under its header.

They are printed one line per `print` call rather than as one string with
embedded newlines, so every line keeps its `[Quiet Dawn - Configurable HUD]`
prefix. A multi-line string would leave the continuation lines unattributed in
a log shared with every other mod.

### Log lines ran into each other (two attempts)

The first attempt was incomplete and is recorded here deliberately, because
the second fix only makes sense against it.

Attempt one changed the *structure* of diagnostic output: one `print` per
message instead of joining several with `" | "`. The output became
better-formed but the lines still ran together, because the real cause was
elsewhere.

Attempt two found it. **UE4SS's Lua `print` does not append a newline.** The
codebase already relied on this knowledge in two places — `main.lua:3` and
`dmm_api.lua:62` both write `print(... .. '\n')` — but
`QuietDawnDiagnostics.output()`, which carries *every* `D.log*`, `D.event`,
`D.count` and summary message, did not. So each line's text was immediately
followed by the next line's timestamp:

    [DEBUG] enabled build=diagnostics-common-1[21:43:19...

Both remaining unterminated sites now append `'\n'`:
`QuietDawnDiagnostics.output()` and the deliberate raw `[ERROR]` print in
`MenuSettings.lua`. The rule is recorded as a comment at the `output()` site
so the next person adding a print does not rediscover it.

### Enemy health updates fail, and said so 373 times

An in-game run showed `Gameplay.lua` raising
`attempt to call a TrivialObject value (method 'GetOwningPlayer')` on roughly
373 `enemyHealth` steps in a ten-second window. Two separate defects combined
to produce that:

*Flooding.* Each field retries 120 times before readiness is declared
exhausted, and the failure was logged on every attempt. Distinct causes are
now reported once per session, capped at 32 causes, with the per-attempt
detail kept as a counter.

*Invisibility.* The report was gated behind `debugLogging`, so a permanent
failure of enemy-health handling was silent at the default level. It is now a
WARNING, and it names the object that failed — without the identity the
message does not say which widget could not be read.

*Likely cause.* Class default objects are now skipped before being queued. A
CDO is not a live widget, has no world and no owning player, so it can never
pass the readiness checks and burns its whole retry budget; Dynamic HUD
filters `Default__` objects the same way. This is a hypothesis, not a
confirmed fix — it lives in its own guard so it can be reverted alone if the
next run shows a different object in the new WARNING line.

### Twenty-one messages ignored the logging setting
`8f6fd8a`

Failure and degradation messages were printed unconditionally, so turning
logging off never silenced them and turning it on never added context to them.
They now carry levels. See *Log levels* below.

### Hook registration failures were invisible
`8f6fd8a`

`reportHookError` was gated behind `debugLogging`, so the line naming the exact
engine function that failed to hook only appeared at full tracing verbosity.
It is the most useful single line when a panel silently stops responding. It is
now a warning. The once-per-hook-per-session guard is unchanged.

### The shipped logo was not a PNG
`d68ccf3`

`Camille Icon.png` was actually a WebP file (`RIFF`/`WEBPVP8L` header). The Mod
Menu accepts only PNG or JPEG and silently drops anything else, so the logo
would never have appeared. Converted losslessly to a real 100x100 PNG.

---

## Features added

### Log levels replace the on/off toggle
`19ec0b8` (control) and `8f6fd8a` (routing)

`Off → Error → Warning → Info → Debug`, cumulative. Levels are defined once in
the new `QuietDawnLogLevels.lua`.

**Warning is the default, not Off.** Roughly twenty messages were previously
printed unconditionally, so the old Off was never silent. Of those, about ten
are errors (the mod gave up) and eleven are warnings (one feature degraded,
the rest kept working). Defaulting to Error would have removed the eleven
degradation notices that explain *why* a panel stopped responding. Warning
reproduces the old behaviour exactly.

**The key was renamed `debugLogging` → `logLevel` rather than overloaded.** Old
`debugLogging=1` meant "everything" while a new `1` means "errors only", and
the two are indistinguishable on disk. Reusing the key would have silently
downgraded every user who had logging on, with no way for the migration to
detect it. Migration reads the retired key once and maps On→Debug, Off→Warning.

### Every HUD element has its own description
`7679688`

The menu had 76 descriptions but only 28 distinct. Three were repeated 17 times
each, once per panel, so the compass text was word for word the crosshair text.
75 of 76 also repeated "Apply to save and update the active game", which the
`[Mod]` description already states once.

All 76 are now unique and name what the panel actually is on screen, which the
labels do not — "Quickslot shortcuts mode" now explains it controls the
quickslot shortcut hints. Sentences conjugate for plural subjects.

**Line breaks are not possible.** `LOCALIZATION.md` states "Do not put newlines
inside an entry", and the format defines no escape sequence. These values are
single-line by design. Length was cut and ordering made consistent instead.

### HUD peek can be triggered by leaving Focus mode

The peek toggle became a three-way trigger: Off, Hold controls legend (the
existing behaviour, still the default), or After leaving Focus mode.

Focus exposes no event. Dynamic HUD reads `bIsInFocusMode` and polls; Quiet
Dawn does not poll, so the trigger is `WBP_GameHUD` ubergraph entry **4026**
-- on a graph the mod already hooks, so it costs no new hook.

4026 is Focus being **left**, established rather than assumed: eight
sightings logged with `bIsInFocusMode` sampled beside each, every reading
`false`, none during unrelated HUD activity. Leaving is the useful half --
the HUD should appear once the player is done with Focus.

It fires **twice** per release, so repeats within 0.2 s of game time collapse
into one reveal. A deliberate second press is far slower and still restarts
the hold.

Backwards compatible with no migration step: `manualPeek` widens `{0,1}` to
`{0,1,2}` and both old values keep their exact meaning, so an existing file
already holds a value the new schema accepts. The three-way value becomes
named intent (`peekOnLegendHold`, `peekOnFocusExit`) in `SettingsModel`, so
no gameplay code compares magic numbers.

### Optional fading when elements are shown and hidden

Elements appeared and vanished instantly. They can now ease in and out, with
separate durations per direction -- showing should feel responsive, hiding
should not snap away. The curve and the 0.22 s / 0.45 s defaults come from
Dynamic HUD.

The constraint worth recording is how it stays off the main thread's back.
Quiet Dawn has no permanent tick by design: the worker wakes on a game event,
drains the work, stops. Dynamic HUD's standing `LoopAsync(50)` was therefore
not portable. `QuietDawnFade` schedules nothing at all. It answers "what
opacity should this panel have right now" and reports through `pending()`
that it still owes frames; the existing worker keeps itself alive while that
is true and terminates normally once the last transition lands. Mid-fade it
revisits only the panels actually transitioning, reusing the pattern the
time-of-day job already follows.

The module touches no UObject, so the opacity-lease and session-journal
discipline is untouched: `writePanel` remains the single write site. With no
trustworthy clock, or a duration of zero, it lands on the target immediately
rather than guessing a frame rate.

Settings are a toggle plus two sliders, the sliders visible only when the
toggle is on. Fading defaults to **off**, so an existing `settings.ini` keeps
its exact behaviour.

### Debug-level ubergraph entry logging

A standing version of the technique that found the magic numbers in
`Gameplay.lua`. See "How Blueprint hooks are found" below.

### Menu headings use a colon
`182df73`

`Player status / Active buffs` → `Player status: Active buffs`. Display only:
the guide describes `Group` as free text that "adds a heading", with no
documented splitting on any character.

The one real risk was that `[Category.X]` is matched against `Group` literally,
so both sides had to move together — 73 `Group` lines and 18 `Category`
sections. The manifest validator confirms all 18 still match.

### The author's logo appears on the settings page
`d68ccf3`

`LogoFile = assets/logo.png` in `[Mod]`, resolved relative to the manifest.

---

## Workarounds used to stay compatible with upstream's way of working

### How Blueprint hooks are found

Worth writing down, because it is the whole reason some features are possible
and others are not.

UE4SS can hook a `UFunction`. If the game exposes a C++ function for an
event, you hook it and you are done. You find out by dumping: `DumpAllObjects`
for paths, and the CXX header dump for every class with its properties *and*
its function signatures. Grep that for the concept.

The two kinds of hit are not interchangeable:

* a **UFunction** is hookable -- event-driven, cheap, exact;
* a **UProperty** is not. You can only read it, which means polling.

When there is no C++ function, the Blueprint is the remaining route. A
Blueprint class compiles its entire event graph into a single function,
`ExecuteUbergraph_<Class>`, taking one argument: the bytecode offset to jump
to. So every event in that class sits behind one hook, distinguished only by
that integer. Quiet Dawn's controls-legend peek is exactly this -- hook
`WBP_ControlsLegend:ExecuteUbergraph_WBP_ControlsLegend`, act only on entry
`850`.

Nothing can look that number up at runtime. You hook the graph, log every
number you see, do the thing in game, and read which number appeared. That is
now a standing capability at Debug level rather than something needing a
one-off instrumented build.

The cost: **entry numbers are not stable across game patches.** Recompiling
the Blueprint moves the offsets. `850` is recorded against Steam build
25191761 for that reason, and any new number should be recorded the same way.

### Vendored modules were left untouched
Seven files under `package/Data/QuietDawnHUD/Scripts/` are copied from
`github.com/my-mods/ue4ss-common` and pinned by sha256 in
`ue4ss-common.lock.json`. All seven are still byte-identical to their pins.

This constrained two changes:

**Log levels live in `QuietDawnDiagnostics.lua`, not in the shared library.**
`UE4SSCommonDiagnostics.lua` takes a single `debugLogging` boolean and swaps its
whole implementation in `setEnabled`. Making it level-aware is the cleaner fix
but would cascade across every mod that vendors it. Instead the library is
switched on only at Debug — the one level that wants its per-event tracing and
timing summaries — and the levels sit above it. **Worth proposing upstream as a
follow-up; this is a working proof of concept.**

**`D.debugLogging` kept its original meaning.** It is read at roughly a hundred
call sites as a cheap per-event guard. It now means "the level is Debug", which
leaves every one of those sites correct and cheap without touching them.

### One bug could not be fixed here
`SettingsStore.lua` prints its messages with a `[Mod Settings]` prefix:

```
[Mod Settings] Legacy settings retained because the file changed: ...
```

Those are Quiet Dawn's logs wearing another mod's name. The file is vendored
and pristine, so **this fix belongs in `ue4ss-common`, not here.**

### Schema generations must stay strict subsets
`SettingsModel.lua` upgrades `settings.ini` one generation at a time, and
`UE4SSCommonSettingsUpgrade.ensure` adds every key its schema declares but the
file lacks. A historical schema naming the retired `debugLogging` key would
therefore write that key back into brand-new files. The pre-`logLevel` schema
is built by removing `logLevel` from the newest one, never by adding the old
key back.

### A hidden coupling the migration depends on
Those upgrades are steered by matching the **exact** string `Store.parse`
returns, for example `"Missing setting: logLevel"`. Adding a key in the wrong
position in `SettingsSchema.lua` changes which key is reported as "first
missing", which silently stops a recovery branch from firing and rejects
existing players' settings at startup. This is now covered by a test.

---

## External resources worth knowing about

Found by the mod's user, not used yet, recorded so the next session does not
have to rediscover them:

* **DawnwalkerSDK** -- https://github.com/Dekita/DawnwalkerSDK -- an SDK from
  Nexus Mods staff. Likely a far better source of class and property names
  than grepping a CXX dump by hand.
* **ue4ss-bridge** -- https://github.com/littleRabbit94/ue4ss-bridge -- a
  bridge by a well-regarded modder.

Both are worth evaluating before any further reverse engineering, especially
for the Focus-mode question.

## Dependencies between commits

Only one. `8f6fd8a` (routing messages to levels) calls `D.logError` /
`D.logWarning` / `D.logInfo`, which are introduced by `19ec0b8`. Take the
control commit first, or take neither.

Everything else is independent.

---

## Tooling added

Under `ressources/tools/`, outside the shipped mod. Not intended for upstream.

| Tool | Purpose |
| --- | --- |
| `setup.sh` | Installs lupa. Re-run after any sandbox restore. |
| `check-lua.py` | Compiles all 29 shipped scripts. Pinned to Lua 5.4, matching UE4SS. |
| `check-mod-settings.py` | Validates `mod_settings.ini` against the guide, plus schema parity and literal `[Category.X]` matching. |
| `test-settings-migration.py` | Covers the settings migration, including the exact-error-string coupling above. |
| `arena-turn-start.sh` | Harness sync. `--verify` re-checks tree integrity before committing. |

### Note on `check-lua.py`
lupa defaults to Lua **5.5**, which made the `for` loop variable const and so
falsely rejects `SettingsStore.lua` and `SettingsModel.lua`. The runtime is
pinned to 5.4 deliberately.

---

## Still open

### HUD peek selector (item 6) -- DONE, awaiting in-game confirmation
Agreed shape: `manualPeek` becomes a picker, `Off / Controls legend hold /
Focus mode`.

No settings migration is needed, which is unusual and worth noting: the old
values `0` and `1` keep their exact meaning, and widening the allowed set to
`{0,1,2}` leaves every existing `settings.ini` valid as written.

**The open risk is the Focus trigger.** Dynamic HUD detects focus by reading
the property `pawn.bIsInFocusMode` every tick; there is no event. Quiet Dawn's
existing peek works because it hooks a real blueprint entry point,
`ExecuteUbergraph_WBP_ControlsLegend` filtered to entry `850`. Focus has no
known equivalent hook, so either:

  * an equivalent entry point is found in the GameHUD ubergraph, which is
    already hooked for quickslot switching, and the same entry-number
    filtering technique applies; or
  * `bIsInFocusMode` is sampled on the events the worker already receives,
    which avoids a dedicated poll but makes responsiveness depend on those
    events firing.

Either way the trigger needs confirming in game. Keep it behind a small module
so swapping the detection method is a one-line change.

### Fade on show/hide (item 7)
Agreed shape: enable toggle plus separate fade-in and fade-out duration
sliders, defaulting to Dynamic HUD's values, shown only when fading is on.
Driven by the existing finite worker, not a permanent tick.

Dynamic HUD's algorithm, worth copying closely:

```lua
if target ~= r.target then r.from = r.mult; r.target = target; r.elapsed = 0 end
r.elapsed = r.elapsed + DT
local duration = target < r.from and 0.45 or 0.22   -- out slower than in
local t = math.min(1, r.elapsed / duration)
r.mult = r.from + (target - r.from) * (t*t*(3-2*t))  -- smoothstep
local desired = r.base * r.mult
```

Three details that matter:

  * **Asymmetric durations.** 0.45s out, 0.22s in. Fading out slowly reads as
    calm; fading in quickly reads as responsive. These become the slider
    defaults.
  * **Smoothstep** rather than linear interpolation.
  * **Base adoption.** `if math.abs(actual - r.last) > 0.002 then r.base = actual end`
    notices the game writing the opacity itself and re-bases instead of
    fighting it. Quiet Dawn's `QuietDawnPanelOpacity.lua` already has the
    readback discipline this needs.

**Why Dynamic HUD polls, and why Quiet Dawn does not have to.** Its tick serves
three purposes: sampling state that has no event, observing external opacity
writes for base adoption, and advancing the fade. Only the third is inherent to
fading. Quiet Dawn already solves the first with hooks, so a fade module can
intercept the existing opacity-write path and schedule the worker only while a
transition is in flight, going idle again afterwards.
