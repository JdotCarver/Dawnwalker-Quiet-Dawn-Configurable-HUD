# Notes for Camille — findings from a private Quiet Dawn fork

Written from a personal fork of **Quiet Dawn - Configurable HUD**, run against
Blood of the Dawnwalker on a Steam build, with the Debug log on and several
other HUD mods installed.

Nothing here is a request. It is the subset of what we found that looked like
it might be useful to you, with enough detail to judge each item quickly.
Everything described is reproducible from the log lines quoted.

Some of it is plainly a bug in your mod; some of it is only a bug in our fork
and is included because the underlying trap is easy to fall into. Each item
says which.

---

## 1. `print` does not terminate a line — log output ran together

**Yours. Small, and the fix is one string.**

UE4SS's Lua `print` does not append a newline. `main.lua:3` and
`dmm_api.lua:62` already know this and write `print(... .. '\n')`, but
`QuietDawnDiagnostics.output()` does not — and it carries every `D.log*`,
`D.event`, `D.count` and summary message. The result is that each line runs
straight into the next line's timestamp:

```
[DEBUG] enabled build=diagnostics-common-1[21:43:19.0716684] [Lua] ...
```

Appending `"\n"` inside `output()` fixes every call site at once.

---

## 2. `main.lua` logs under another mod's name

**Yours. One line.**

```lua
-- Scripts/main.lua:3
local function report(message) print('[Save Settings] '..message..'\n') end
```

This looks like a leftover from the bootstrap this was adapted from. It
attributes the session journal and settings messages to a different mod:

```
[Lua] [Save Settings] Session cleanup skipped 24 unavailable or replaced object values
```

---

## 3. The boss bar's health bar is never hidden

**Yours. Player-visible.**

With `hideEnemyHealthBars = 1`, this repeats and then stops:

```
enemyHealth readiness exhausted: /Game/_Dawnwalker/UI/_Unified/Combat/
    WBP_Combat_BossBar.WBP_Combat_BossBar_C field=HealthBar
```

**Diagnosed.** A named widget is only reachable as `object.HealthBar` when
the Blueprint marks that widget **"Is Variable"** — that flag is what
promotes it to a property on the generated class. Walking the class with
`ForEachProperty` reports exactly one property for `WBP_Combat_BossBar_C`:

```
Class properties: UberGraphFrame
```

So `HealthBar` is not a property at all, and no number of retries could ever
have resolved it. `WBP_CombatCharacterBar` does set the flag, which is why
`SegmentedHealthBar`, `HealthBarLeftCap` and `HealthBarRightCap` work there.

My earlier guess that a game update had renamed the child was wrong; the
build-number mismatch in the comments is a red herring for this symptom.

**Fix:** fall back to `object:GetWidgetFromName(field)`, which searches the
widget tree and does not care about the flag:

```lua
local function findChild(object, field)
    local child = object[field]
    if valid(child) then return child end
    local found = select(2, pcall(function()
        return object:GetWidgetFromName(field)
    end))
    if valid(found) then return found end
    return nil
end
```

This also handles the lazily-built case correctly: the tree is only populated
once the widget exists, so a bar that is not built until a boss appears
returns nil and is retried, rather than being mistaken for a bad name.

Reported at Debug only, so by default a feature silently does not work.
Worth promoting to a warning, and worth printing the class's actual property
list alongside — that one line is what identified this.

---

## 4. One failure can emit hundreds of identical lines

**Yours. Diagnostics quality.**

`healthStep` retries each field 120 times and logs on every attempt. A single
unreachable widget produced ~373 `enemyHealth` steps in ten seconds, nearly
all logging the same message, which pushed the event limiter to
`suppressed=129` and buried everything else.

Reporting each distinct cause once per session, and counting the rest, keeps
the signal. The same pattern already exists in the hook-error path
(`reportHookError`), so it is consistent with the surrounding code.

---

## 5. `GetOwningPlayer` on a TrivialObject

**Yours, probably. Unconfirmed.**

```
Gameplay.lua:547: attempt to call a TrivialObject value (method 'GetOwningPlayer')
```

Continuous during combat, swallowed by the surrounding `pcall` and only
visible at Debug. Our hypothesis is a class default object reaching
`healthStep`: a CDO has no world and no owning player, so it can never pass
the readiness checks and burns its full retry budget. Dynamic HUD filters
`Default__` objects explicitly, which suggests the same thing bit its author.

Filtering them made the error stop recurring in our testing, but one clean run
is not proof.

**Caveat worth more than the fix:** we first put that filter in `queueHealth`,
which runs straight off `NotifyOnNewObject` — during level load, on objects
the engine may still be constructing. Calling `GetFullName()` there is not
safe, and `pcall` does not help because an access violation is not a Lua
error. It belongs after the `valid(object)` check inside `healthStep`.

---

## 6. Startup order leaves the HUD visible for about half a second

**Yours. Cosmetic but noticeable.**

On load, elements the player asked to hide stay visible until the first
refresh afterwards. The worker's priority order spends that time elsewhere:

```
hook      calls=30 avgMs=9.133  maxMs=19   slow=26
clawMarks calls=4  avgMs=58.500 maxMs=137  slow=4
```

Thirty hooks at one per frame is roughly half a second on its own, and claw
mark preloading peaks at 137 ms in a single slice. Both run ahead of the panel
pass in `step()`.

Letting the first full panel pass go first — with the three lifecycle specs
exempt, since they are what finds the HUD — removes the delay. Nothing else in
that list is visible to the player on the first frames.

---

## 7. `ensure()` takes defaults from its argument, never from the schema

**Ours, not yours — but the trap is in the shared helper.**

We added three settings and shipped a build that refused to load for anyone
with an existing `settings.ini`. `UE4SSCommonSettingsUpgrade.ensure` fills a
missing key from the `defaults` table passed to it; given no entry it returns
`Missing setting: <key>` and the whole load fails. We had passed `{}`,
assuming the schema's own defaults applied.

The schema already holds the right values, so deriving the table from it
removes the chance of drift:

```lua
local fadeDefaults = {}
for _, row in ipairs(newestSchema) do
    if FADE_KEYS[row.key] then fadeDefaults[row.key] = row.default end
end
```

A doc comment on `ensure` saying the defaults are not read from the schema
would have saved the incident.

---

## 8. Discrete `values` grids cannot match slider output

**Ours. Also a general trap.**

We declared a 0.01-step duration as a discrete `values` list. A 0.01-step
slider emits values like `1.1300000000000001`, which no list of floats can
match, so `Store.parse` rejects them. Continuous `min`/`max`/`integer=false`
is the right shape for any fine-grained slider. The coarse 0.5-second grids
used by the hold timers are fine because the menu emits exactly those values.

---

## 9. `os.clock` is the wrong clock for anything time-based

**Ours. Worth knowing before anyone else animates something.**

`D.now()` is `os.clock`: processor time consumed by the process, granularity
about 15.6 ms on Windows, no fixed relationship to wall time. Your diagnostics
header already warns about it —

```
clock=os.clock; phase timings overlap and are not engine frame times
```

— and it is correct for comparing phase costs. We used it to drive an opacity
transition and it visibly stuttered. `GetGameTimeInSeconds`, which the peek and
time-of-day holds already use, is smooth and stops while the game is paused.

Related reading note: `slow phase=... elapsedMs=14.000` values landing on
exactly 14/15/16 ms are the Windows timer tick, not real cost.

---

## 10. `Gameplay.lua` is at Lua's hard limit of 200 locals per chunk

**Structural. Not urgent, but it blocks edits silently.**

Three separate additions to the file failed to compile with

```
too many local variables (limit is 200) in main function
```

It is a hard limit per chunk, not a style guide, and it surfaces as a
compile error on whatever edit happens to be last rather than pointing at the
cause. Each new module-level helper or flag needs a slot, so the file is now
effectively closed to new top-level names unless something else is folded into
a table first. Extracting the worker would give the most headroom.

---

## 11. Blueprint ubergraph entry numbers

**Not a bug. A note on technique, since the numbers are undocumented.**

For anyone maintaining `850` (controls legend) and `4146` (quickslot toggle):
both are offsets into `ExecuteUbergraph_<Class>`, and they move when a game
update recompiles the Blueprint. They can be recovered by hooking the graph,
logging every entry number seen, performing the action, and reading which
number appeared.

We used that to find **4026** on `WBP_GameHUD`, which is Focus mode being
**left** (confirmed by sampling `bIsInFocusMode` on the pawn beside each
sighting — eight sightings, all `false`, none during unrelated HUD activity).
It fires **twice** per release, so a consumer needs to debounce. It is on a
graph the mod already hooks, so it costs no additional hook.

Focus exposes no event of its own; Dynamic HUD reads the `bIsInFocusMode`
property and polls, which is consistent with there being nothing to hook.

---

## 12. Still unexplained

Not attributed, and quite possibly not yours — several other HUD mods were
loaded (CenterHUD, EasierParry, Immersive HUD-style mods), and we had our own
changes in the build.

```
Unhandled Exception: EXCEPTION_ACCESS_VIOLATION reading address 0x0000000000000123
```

on loading a save, with an all-UE4SS stack, plus occasional hangs on alt-tab.
The low address suggests a field read off a near-null pointer, i.e. a
destroyed or half-constructed UObject. Mentioned only so it is on your radar
if a similar report reaches you.

---

## What we would actually suggest

In rough order of value for effort:

1. The `\n` in `QuietDawnDiagnostics.output()` — one string, fixes all output.
2. The `[Save Settings]` prefix in `main.lua` — one string.
3. Resolve enemy bar children with `GetWidgetFromName` as well as by
   property, and promote the readiness failure to a warning. See finding 3:
   `WBP_Combat_BossBar` does not mark its children "Is Variable".
4. Collapse repeated identical `enemyHealth` failures.
5. Let the first panel pass run before hook registration and claw mark
   preloads.

Items 7 to 10 are notes rather than suggestions — traps we fell into that the
surrounding code does not warn about.

Thanks for the mod, and for writing it in a way that made all of this legible
from the outside. The dependency injection in `QuietDawnCombatCues`,
`QuietDawnClawMarks` and `QuietDawnPlayerEffects` in particular made it
straightforward to reason about each piece in isolation.
