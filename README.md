<!-- README.md -->
# Quiet Dawn - Configurable HUD

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. In Quiet Dawn mode, combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy information:** health bars, names and difficulty icons are hidden by default, with three independent settings in the settings menu or `settings.ini`. Turn off **Hide enemy health bars** to restore ordinary enemy and boss health bars, their end caps and boss health-phase indicators. Turn off **Hide enemy names** to restore name labels (boss names). Enemy stamina retains game behavior; effect icons have their own toggle; combat warnings follow the separate cue settings.
- **Claw slash marks:** **Hide claw slash marks** hides the red Shredded Touch slash effects on enemies, including the sword variant. It defaults to On and changes only these visuals; damage, bleeding and ordinary blood effects keep their game behavior. Turn it Off under **Combat: Enemies**, or set `hideClawSlashMarks = 0` in `settings.ini`, to show the marks again. Apply to save and update the active game.
- **Enemy lock-on marker:** Five independent Combat: Indicators toggles control counterattack directions, unblockable warnings, directional parry cues, the enemy dot/diamond and the lock icon. All default to Off. **Show enemy dot/diamond** restores the red marker independently of **Show lock icon**. It also controls the red secondary-enemy attack dot beside an enemy health bar: Off hides it, and On allows the game to show it when appropriate, independently of health-bar visibility. When both are On, a hard-locked target shows the padlock. Directions and unblockable warnings take priority over the marker. Enabled unblockable warnings retain their skull icon when soft-lock or hard-lock targets change.
- **Player health and stamina:** in their default Quiet Dawn mode, shown together at full opacity after damage, meaningful healing or stamina use, while health is strictly below **50%**, or while stamina is strictly below **20%**. Vampire health follows the blood bar; human health follows HP.
- **Hide delay:** **4 seconds** after the last health/blood alert; **1.5 seconds** after the last stamina drop. Further meaningful drops restart the relevant delay; blood fluctuations smaller than 0.2% of the bar do not keep renewing it. Low health or stamina keeps the panel visible without a timeout. Exactly 50% health or 20% stamina does not qualify by itself.
- **Show HUD:** choose **Hold controls legend** (the default) to reveal the player HUD for **3 seconds** with the Controls Legend gesture (Menu on Xbox, Options on PlayStation, or L on keyboard by default). Choose **Focus mode** to keep the same included panels visible throughout Focus, then start that configured duration when Focus ends. Repeat the legend gesture to refresh its timed reveal. In Quiet Dawn mode, each eligible panel's default-on **HUD Peek Behaviour** is **Exclude** or **Include**. In Fixed Opacity mode, the same control is **Don't change** (the default) or **Raise opacity**, which raises the panel to 100% for a peek. Vanilla and Always Hidden panels show no irrelevant HUD Peek Behaviour control. Show HUD brings participating panels up together and restores their automatic visibility together when the reveal ends. Panels with an active resource alert, cooldown or other independent reveal keep their own visibility rules.
- **Parry/attack indicators:** Show directional parry cues displays the incoming attack direction and highlights its arrow during the parry window, independently of the game's Directional Indicator option.
- **Counterattack direction:** Show counterattack direction displays the weak-spot attack direction during counterattack openings, including after a perfect parry. The cue ends when the game clears the opening. Combat cue size adjusts all combat icons and directions together from 10% to 200% in 10% steps, defaulting to 100%.

Each of the 17 player panels has a **Vanilla / Quiet Dawn / Fixed Opacity / Always Hidden** mode picker. Vanilla leaves opacity and visibility to the game and excludes the panel from Quiet Dawn reveals. Quiet Dawn uses automatic hiding, resource alerts and contextual reveals. Fixed Opacity shows a conditional 0%–100% slider in 5% steps. Always Hidden keeps the panel at 0%, including during cooldowns and HUD peek, and hides its irrelevant Opacity, Size and HUD Peek Behaviour controls. Fixed values are not overridden by alerts, switching or time changes; their HUD Peek Behaviour can optionally raise them during a peek. The game retains its contextual visibility rules.

In Quiet Dawn mode, quickslots appear briefly after switching and the special-attack panel appears only during cooldown. HUD peek reveals eligible Quiet Dawn panels at full opacity; the combat-focus wheel, Focus hint, switch hint and special-attack panel keep their own rules. Interaction prompts, dialogue, subtitles, notifications and menus retain game behavior.

The Sprint and Haste button prompts stay hidden while running in human and vampire form, including after the game refreshes their text or button icon. Sprint/Haste suppression works independently of the display language. **Hide sprint/haste prompt** is in the **Controls: Action prompts** section. Turn off **Hide sprint/haste prompt** in the settings menu, or set `hideSprintPrompt = 0` in `settings.ini`, to restore them. Other action prompts retain game behavior, and manual HUD peek keeps running prompts hidden.

The Toggle abilities hint (RT with the remapped controller layout) stays hidden in Focus mode and during manual HUD peek. Ability switching still works. Select Vanilla, or select Fixed Opacity with a positive value, to restore the hint.

Health and blood gains of at least 0.2% of the bar reveal the stat panel and refresh the health hold duration (4 seconds by default). Repeated qualifying regeneration gains keep the panel visible until that duration expires after the last gain. Smaller gains stay quiet until the bar reaches full. That full-bar reveal rearms only after a deficit of at least 0.2%, preventing repeated near-full notifications. These alerts apply only to stat panels in Quiet Dawn mode; Fixed Opacity, Always Hidden and Vanilla do not use them.

The time-of-day panel is hidden by default. It appears at full opacity when an activity advances time, including shrine restoration, then hides after the configured duration (4 seconds by default). If the activity hides the HUD, the reveal starts when the HUD returns. Time of day reveal duration adjusts from 0 to 10 seconds in 0.5-second steps; 0 disables automatic reveals. Fixed Opacity keeps the selected value unless its HUD Peek Behaviour is set to **Raise opacity**; Always Hidden keeps it off completely. Vanilla follows the game. In Quiet Dawn mode, the panel's **HUD Peek Behaviour** controls whether a Show HUD trigger also reveals it.

## Player combat effects

**Hide player combat effects**, under Player status: Active buffs, hides Crimson Rush's bright red arm effect in human and vampire form. It defaults to Off and is separate from effect icons and enemy claw slash marks. Buff strength, duration and sound stay unchanged. Apply updates effects already active on the player; Off restores their visibility.

## Effect icons

**Hide enemy effect icons** under Combat: Enemies hides effect icons and timers, including bleeding, on ordinary enemies and bosses. It is independent of enemy health bars, names, difficulty icons, combat warnings and Hide claw slash marks.

**Hide player effect icons** under Player status: Active buffs hides the player's buff/debuff icons and their timers, including during Show HUD. While On it overrides Active buffs mode and opacity; turning it Off resumes those saved settings. Size preferences are retained.

Both toggles default to Off. They only hide HUD visuals; damage, bleeding, buffs, debuffs and their durations keep their game behavior. Press Apply to update the active game.

## Panel size

All 17 player panels have size sliders from 25% to 200% in 5% steps, defaulting to 100%. Edge panels grow inward and centered panels stay centered. Original layout spacing stays fixed, so large sizes can overlap nearby elements. Apply to save and update the active game. Scaling uses each panel's original proportions, including its text and icons. Size remains independent in Vanilla, Quiet Dawn and Fixed Opacity modes; Always Hidden conceals it because size cannot affect a hidden panel.

Only initialization, replacement and settings Apply events apply transforms; there is no recurring size update. Returning to 100% or disabling the mod restores the original size and scaling origin.

## Requirements

- Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271). Enable `HookProcessConsoleExec = 1` in your UE4SS loader profile for live Apply.
- Required: [UE4SS for Dawnwalker by Vercadi](https://www.nexusmods.com/thebloodofdawnwalker/mods/18) **1.3 (RC6) or later**, exposing `ExecuteInGameThreadWithDelay`, `CancelDelayedAction`, `KismetSystemLibrary.GetFrameCount`, and `GetGameTimeInSeconds`, with either Blueprint script hooks or the bundled native HUD adapter. Native helpers use the imported C++ APIs; no DLL fingerprint or fork-name restriction is imposed. Development reference: commit `97b7e501c`.

## Installation

- Vortex: Install `Quiet-Dawn-Configurable-HUD.zip` through Vortex, enable it and deploy.
- Manual: Copy the archive's `Data/QuietDawnHUD` folder into `<game folder>/Dawnwalker/Binaries/Win64/ue4ss/Mods`, preserving the folder structure.

## Compass

Compass size and mode work independently. For a smaller, translucent compass, select Fixed Opacity, 25% size and 40% opacity, then press Apply.

Select Compass mode in the settings menu: Vanilla follows the game, Quiet Dawn hides it between HUD peeks, Fixed Opacity exposes the percentage slider, and Always Hidden keeps it off. For manual editing, set `mode_WBP_Compass` to 0, 1, 2 or 3 respectively; `compassOpacity` stores the fixed percentage. The old Show Compass variant is no longer needed; its backed-up legacy preferences can be imported on first use.

## Settings

Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271). Open Mod Settings and press Apply to save and update gameplay.

The menu runs from General through Player status, Combat, Exploration and Controls, ending with Diagnostics. Categories are alphabetical within each group, using headings such as Combat: Crosshair and Exploration: Compass. Each panel keeps its mode, conditional opacity and size together, followed by related thresholds or reveal durations. Combat: Indicators contains counterattack directions, parry cues, unblockable warnings, the enemy dot/diamond, the lock icon and cue size. Logging remains the final entry.

### Defaults

On a fresh install with no saved or imported preferences, the mod is enabled and all 17 player panels start in Quiet Dawn mode (automatic hiding and contextual reveals), with saved fixed opacities at 0%. All panel sizes start at 100%. Enemy health bars, enemy names, difficulty icons, and sprint/haste prompts are hidden. All five combat indicator toggles are Off; cue size is 100%. Health/blood below 50% or stamina below 20% keeps the stat panels visible. Health alerts hold for 4 seconds and stamina alerts for 1.5 seconds. Holding Controls Legend reveals the HUD for 3 seconds; switching quickslots reveals them for 3 seconds; time changes reveal the time panel for 4 seconds. Logging is Warning. Existing saved or supported imported preferences take precedence over these defaults.

### Manual configuration

1. Install Quiet Dawn through Vortex with its required UE4SS loader, then launch the game once. Quiet Dawn creates its own `settings.ini`; you can load a save and play immediately with the defaults.
2. Close the game and back up that generated file. Open `<game folder>/Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/settings.ini` in a text editor.
3. Edit the existing entries under `[Settings]`, keeping every other entry and the section header. Use `1` for On and `0` for Off; panel modes use 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity and 3 = Always Hidden. Use percentages such as `50` (not `0.5`), and seconds such as `1.5`. Keep the exact key names and use a decimal point. Do not add duplicate keys or replace the file with the example below.
4. Save the file, restart the game, and load a save. The next save load reads your values; settings are not polled during play.

Example edits to the matching existing lines (this is not a complete settings file):

```ini
mode_WBP_Compass = 2
compassOpacity = 50
scale_WBP_Compass = 75
mode_Crosshair = 2
opacity_Crosshair = 100
hideSprintPrompt = 0
hideEnemyHealthBars = 0
hideEnemyNames = 0
hideEnemyDifficultyIcons = 0
showCounterattackDirection = 1
showDirectionalParry = 1
```

This shows the compass at half opacity and 75% size and the crosshair at full opacity when the game permits, restores running prompts and enemy health bars/names/difficulty icons, and enables counterattack and parry directions. Other preferences stay as saved. Set any option back to its listed default to restore that behavior.

Edit `settings.ini`, not `mod_settings.ini` (the settings menu definition), `Scripts/QuietDawnDefaults.lua` (first-use defaults), or the old import-only files. The menu and manual editing use the same settings file. Back it up before editing.

See [SETTINGS.md](SETTINGS.md) for every key, default, supported value, first-use import, and recovery details.

## Behavior and performance

The bundled native helper filters Quiet Dawn's HUD events. It copies event values into a bounded queue and delivers them through the existing game-thread scheduler. Player alerts take priority over enemy-widget bursts; saved changes update the active session. The helper adds no polling thread or continuous readiness timer.

Claw-mark suppression prepares the two slash effects when enabled. The native helper keeps their original assets available until the option is turned off or the save session closes. Missing or expired enemy widgets are skipped during reload cleanup so the new HUD can receive its settings. Logging includes slash preparation counts and timings.

Player creation and possession can activate the HUD when a loading-screen notification is missed. Readiness checks share one finite window of less than ten seconds; they stop after success or exhaustion and can resume on a later player event. An old world's player cannot activate a new session. Ordinary travel retains the settings snapshot.

Raise **Logging**, or set `logLevel` in `settings.ini`, for activation and HUD diagnostics in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. The Debug-only **Find visible Activation Charges widget** setting appears beside it at Logging = Debug. It runs one finite, explicitly enabled locator cycle on the next combat entry: each runtime Focus Charge entry is hidden for two seconds, restored for one second, and identified by class/address in the log. It restores every test entry and never runs during ordinary play. The levels are `0` Off, `1` Error, `2` Warning, `3` Info and `4` Debug, and each one includes the levels above it. Warning is the default: it reports what the mod gave up on and which features could not start, which is what earlier versions always printed. Debug adds per-event tracing and timing summaries and is the only level with a measurable cost. With fading enabled, Info records `Startup immediate baseline` with the HUD adoption route, panel and target whenever a direct startup baseline write bypasses a fade; the Debug summary counts these writes as `startupImmediateFadeBypass`. Apply to update diagnostics immediately; restart the game to diagnose an activation failure that prevents the new snapshot from loading. Activation summaries include the event source, readiness attempts, failure reason and aggregate CPU time. Hook-registration failures include the exact function path and exception once per hook per session.

Lifecycle callbacks initialize the named panels. Preset refreshes reapply cached panel opacity together and reserve separate slices for missing fields and size changes. Resource updates can interrupt a longer refresh, with regular slices reserved so both jobs make progress. Health, blood, and stamina change handlers, plus the stat widgets' event-driven update functions, request a coalesced read of the current player's active resource percentages. The update-function hooks also cover direct event-graph dispatch. Blood-bar capacity changes are covered by the same widget update path. There is no recurring stat sampler. The stamina handler is bound by the shared HUD's vampire stats widget during initialization in both forms. Rapid loss followed by recovery still records the largest loss in that event burst, even if a smaller blood fluctuation follows.

A single pending hide deadline uses cached resource values and game time; it never rereads health or stamina. Further meaningful damage or healing extends the health deadline; reaching full after a meaningful deficit also reveals health once. Pausing preserves the remaining hold time: an outstanding deadline may reschedule for the remaining game-time delay. The same deadline ends manual HUD peeks, quickslot reveals and time-change reveals independently, including while health is low. It then restores normal hiding for the other panels while leaving low health visible. Once the relevant holds expire, no deadline timer continues. Cached peek panels change opacity in one frame. Discovery, hook setup and size changes remain spread over separate frames.

Ownership checks use Unreal object addresses. Different Lua wrappers for the same object retain its cached state; old HUD/world events are ignored. Missing readings or unavailable resource hooks leave stat panels under normal game visibility when possible. Failed hook setup uses finite retries and can recover on a subsequent HUD/player lifecycle event. There is no polling fallback. Known health alerts use full opacity even if a stat panel was transparent during initialization. Form selection and the game's visibility presets remain in effect. Unknown forms or unavailable blood data leave the stat panels under game control.

Enemy health hiding uses the named health widgets verified in Steam build 25232147. Construction and target/owner changes schedule bounded work on the shared HUD worker, one named child per frame. It does not scan enemies, poll their stats, or change their actual health. A missing child exhausts its own readiness attempts; one later target/owner event gets one final bounded rearm, then that child stays dormant for the current bar if it remains unavailable. A replacement bar starts with a fresh readiness window, and other children continue processing. Active player-HUD fades take precedence over queued enemy-bar work, so an unavailable child cannot consume their intermediate frames. The secondary-enemy dot uses the same worker to hide its parent attachment, so its internal fade animation cannot reveal it. Turning Show enemy dot/diamond On releases that opacity override without forcing an inactive warning to appear.

Combat cue changes use the existing marker construction, icon-render and lock events. Each update touches a fixed set of named child widgets; no widget-tree search or recurring timer is added. Parry and counterattack directions suppress center icons, and the enemy marker toggle shows the stock diamond on near and far reticles between cues. The lock toggle independently shows a padlock on a hard-locked target, taking priority when both are enabled. The game retains control of distance fading and overall widget visibility. Readiness retries and the 64-entry marker cache/queue remain bounded. Logging reports the observed state, selected cue, size and readiness failures.

Claw slash hiding clears only the visual reference on two named static gameplay cues. The native effect handler skips empty references; session cleanup restores each original effect when still owned by the mod. Cue construction and save loads schedule bounded work on the shared HUD worker, with no per-hit hook. Logging includes cue names, applied/restored effect counts and readiness failures.

There are no global HUD searches, widget-tree walks, or recurring configuration reads. The panel worker terminates after each job. Resource events that leave visibility unchanged do not revisit panels; stat-widget refreshes check the affected opacity and queue a repair only when it differs. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events and when Show HUD begins or ends. Missing or failed fields receive up to eight separate recovery attempts per lifecycle event, without holding up other panels. Resource changes do not restart exhausted retries. Resource hooks and reads are disabled when neither stat panel uses Quiet Dawn mode. The Focus mode Show HUD trigger samples the pawn during this existing event-driven work, without a recurring Focus poll; it holds included Quiet Dawn panels at 100% during Focus and begins the configured duration on exit. Vanilla and Always Hidden panels are excluded from Show HUD. Eligible Quiet Dawn panels can opt out, while Fixed Opacity panels participate only when their HUD Peek Behaviour is explicitly set to Raise opacity.

## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS runtime DLL are included. The bundled native helper uses UE4SS APIs; their authors retain credit for the runtime and hook implementation. See LICENSES for third-party notices.

This mod includes the MIT-licensed [ue4ss-common Lua helpers](https://github.com/my-mods/ue4ss-common). No separate library installation is required. Its license is included in LICENSES/QuietDawnHUD-ue4ss-common.txt.

## Live settings

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Only affected panels, resource reveals, combat cues, enemy visuals or prompts are queued. Repeated size changes use the original scale and pivot; returning to 100% restores them. Widget caches and native event bindings remain in place for ordinary changes.

Logging is the final, sole diagnostic control. It changes immediately; verbose logging is Off by default. Logs are written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Settings are never polled.
