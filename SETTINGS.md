<!-- SETTINGS.md -->
# Settings

Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271). Open Mod Settings and press Apply to save and update gameplay.

## Menu categories

The menu runs from General through Player status, Combat, Exploration and Controls, ending with Diagnostics. Categories are alphabetical within each group, using headings such as Combat: Crosshair and Exploration: Compass. Each panel keeps its mode, conditional opacity and size together, followed by related thresholds or reveal durations. Combat: Indicators contains counterattack directions, parry cues, unblockable warnings, the enemy dot/diamond, the lock icon and cue size. Diagnostics contains Logging and the Debug-only Activation Charges visual locator.

| Category | Controls |
| --- | --- |
| General | Enabled, fade elements in and out, and the fade in/out durations |
| Player status: Active buffs | Hide player combat effects, Hide player effect icons, Active buffs mode, opacity and size |
| Player status: Experience | Experience bar opacity |
| Player status: Health and stamina | Human and vampire panel opacity, health/blood and stamina thresholds, and their hold durations |
| Combat: Ability cooldowns | Ability cooldowns opacity |
| Combat: Crosshair | Crosshair opacity |
| Combat: Enemies | Enemy health bars, names, difficulty icons, effect icons and claw slash marks |
| Combat: Focus activation prompt | Toggle abilities hint opacity |
| Combat: Focus charge | Focus charge bar opacity |
| Combat: Focus panel | Combat focus panel opacity |
| Combat: Indicators | Counterattack directions, unblockable warnings, parry cues, enemy dot/diamond, lock icon and cue size |
| Combat: Quickslots | Item and ability quickslot opacity, switch prompt opacity and switch reveal duration |
| Combat: Special attack cooldown | Special attack cooldown opacity |
| Exploration: Compass | Compass opacity |
| Exploration: Quest tracker | Quest tracker opacity |
| Exploration: Time of day | Panel opacity and reveal duration |
| Controls: Action prompts | Hide sprint/haste prompt |
| Controls: Controls legend | Controls legend opacity |
| Controls: HUD peek | Show HUD trigger and duration; each eligible panel category carries its HUD Peek Behaviour |
| Diagnostics | Logging; Find visible Activation Charges widget (Debug only) |

Each player-panel category has a mode picker, an opacity slider visible only in Fixed Opacity mode, and a size slider in every mode except Always Hidden. Its HUD Peek Behaviour appears only when it can affect that selected mode: Exclude/Include in Quiet Dawn, or Don't change/Raise opacity in Fixed Opacity. The 17 size sliders use 25% to 200%, in 5% steps, with a 100% default.

## Default behavior

On a fresh install with no saved or imported preferences, the mod is enabled and all 17 player panels start in Quiet Dawn mode (automatic hiding and contextual reveals), with saved fixed opacities at 0%. All panel sizes start at 100%. Enemy health bars, enemy names, difficulty icons, claw slash marks, and sprint/haste prompts are hidden. All five combat indicator toggles are Off; cue size is 100%. Health/blood below 50% or stamina below 20% keeps the stat panels visible. Health alerts hold for 4 seconds and stamina alerts for 1.5 seconds. Holding Controls Legend reveals the HUD for 3 seconds; switching quickslots reveals them for 3 seconds; time changes reveal the time panel for 4 seconds. Logging is Warning. Existing saved or supported imported preferences take precedence over these defaults.

Older settings files receive missing panel size keys at 100%, preserving existing values, comments and prior backups. Claw-mark upgrades retain `settings.ini.before-claw-slash-marks`; older `settings.ini.before-panel-scaling` backups are retained. Existing malformed or duplicate values are rejected without replacing the file.

New effect-icon settings are added as Off to older INIs, preserving existing entries and comments in the updated file and the original in `settings.ini.before-effect-icons`. Existing recovery backups are retained.

## Player combat effects

**Hide player combat effects**, under Player status: Active buffs, hides Crimson Rush's bright red arm effect in human and vampire form. It defaults to Off and is separate from effect icons and enemy claw slash marks. Buff strength, duration and sound stay unchanged. Apply updates effects already active on the player; Off restores their visibility.

The setting is `hidePlayerCombatEffects` (0 = Off, 1 = On). Older INIs receive this missing key with a `settings.ini.before-player-combat-effects` backup. Existing preferences and comments are retained; conflicting backups and malformed values are rejected.

## Effect icons

**Hide enemy effect icons** under Combat: Enemies hides effect icons and timers, including bleeding, on ordinary enemies and bosses. It is independent of enemy health bars, names, difficulty icons, combat warnings and Hide claw slash marks.

**Hide player effect icons** under Player status: Active buffs hides the player's buff/debuff icons and their timers, including during Show HUD. While On it overrides Active buffs mode and opacity; turning it Off resumes those saved settings. Size preferences are retained.

Both toggles default to Off. They only hide HUD visuals; damage, bleeding, buffs, debuffs and their durations keep their game behavior. Press Apply to update the active game.

## Panel modes

Each of the 17 player panels has a **Vanilla / Quiet Dawn / Fixed Opacity / Always Hidden** mode picker. Vanilla leaves opacity and visibility to the game and excludes the panel from Quiet Dawn reveals. Quiet Dawn uses automatic hiding, resource alerts and contextual reveals. Fixed Opacity shows a conditional 0%–100% slider in 5% steps. Always Hidden keeps the panel at 0%, including during cooldowns and HUD peek, and conceals its irrelevant Opacity, Size and HUD Peek Behaviour controls. Fixed values are not overridden by alerts, switching or time changes; their HUD Peek Behaviour can optionally raise them during a peek. The game retains its contextual visibility rules.

The Opacity slider appears only when Fixed Opacity is selected. The Size slider appears in Vanilla, Quiet Dawn and Fixed Opacity, but not Always Hidden. In Quiet Dawn, HUD Peek Behaviour offers Exclude or Include; in Fixed Opacity it offers Don't change (the default) or Raise opacity to 100% while Show HUD is active. Vanilla and Always Hidden do not show that irrelevant control. Hidden controls retain their saved values. Apply commits both mode and opacity together; Restore discards pending edits, and Reset returns modes to Quiet Dawn after Apply.

Older settings gain missing mode keys without changing opacity values, comments, unknown keys or existing recovery copies. Previous 0% becomes Quiet Dawn; positive values become Fixed Opacity. Current Fixed Opacity settings at exactly 0% are then promoted to Always Hidden without changing their visible behavior; the original file is backed up as `settings.ini.before-always-hidden`. Invalid or duplicate values are rejected before replacement. Selecting Vanilla during play conditionally restores the last unmodified game opacity and stops overriding it; later game updates remain in control. Select 100% size for original proportions. Existing settings also receive default-off `fixedPeek_<panel>` entries, preserving their former Fixed Opacity behavior; that upgrade keeps `settings.ini.before-fixed-hud-peek`.

## Claw slash marks

**Hide claw slash marks** hides the red Shredded Touch slash effects on enemies, including the sword variant. It defaults to On and changes only these visuals; damage, bleeding and ordinary blood effects keep their game behavior. Turn it Off under **Combat: Enemies**, or set `hideClawSlashMarks = 0` in `settings.ini`, to show the marks again. Apply to save and update the active game.

Existing settings gain only the missing `hideClawSlashMarks = 1` entry, with a `settings.ini.before-claw-slash-marks` backup. Existing preferences, comments and older backups are preserved.

## Panel size

All 17 player panels have size sliders from 25% to 200% in 5% steps, defaulting to 100%. Edge panels grow inward and centered panels stay centered. Original layout spacing stays fixed, so large sizes can overlap nearby elements. Apply to save and update the active game. Scaling uses each panel's original proportions, including its text and icons. Size remains independent in Vanilla, Quiet Dawn and Fixed Opacity modes; Always Hidden conceals it because size cannot affect a hidden panel.

Only initialization, replacement and settings Apply events apply transforms; there is no recurring size update. Returning to 100% or disabling the mod restores the original size and scaling origin.

## Manual configuration

1. Install Quiet Dawn through Vortex with its required UE4SS loader, then launch the game once. Quiet Dawn creates its own `settings.ini`; you can load a save and play immediately with the defaults.
2. Close the game and back up that generated file. Open `<game folder>/Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/settings.ini` in a text editor.
3. Edit the existing entries under `[Settings]`, keeping every other entry and the section header. Use `1` for On and `0` for Off; panel modes use 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden. Use percentages such as `50` (not `0.5`), and seconds such as `1.5`. Keep the exact key names and use a decimal point. Do not add duplicate keys or replace the file with the example below.
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

The stable menu ID is `oOCamilleOo_QuietDawnHUD`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Startup prepares the settings file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `logLevel` controls diagnostic verbosity; it defaults to `2` (Warning). Panel size diagnostics report applied sizes, bounded readiness failures and transform-write counts through the existing worker timing summary.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| General | Fade elements in and out | Off (default), On |
| General | Fade in duration | 0 to 2 seconds (default 0.35); shown only when fading is on |
| General | Fade out duration | 0 to 2 seconds (default 1.30); shown only when fading is on |
| Player status: Active buffs | Hide player combat effects | Off, On (default Off) |
| Player status: Active buffs | Hide player effect icons | Off, On (default Off) |
| Player status: Active buffs | Active buffs mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Player status: Active buffs | Active buffs opacity | 0% to 100% in 5-point steps |
| Player status: Experience | Experience bar mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Player status: Experience | Experience bar opacity | 0% to 100% in 5-point steps |
| Player status: Health and stamina | Human health and stamina mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Player status: Health and stamina | Human health and stamina opacity | 0% to 100% in 5-point steps |
| Player status: Health and stamina | Vampire blood and stamina mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Player status: Health and stamina | Vampire blood and stamina opacity | 0% to 100% in 5-point steps |
| Player status: Health and stamina | Keep health visible below | 0% to 100% in 5-point steps (default 50%) |
| Player status: Health and stamina | Health / blood hold duration | 0 to 10 seconds in 0.5-second steps |
| Player status: Health and stamina | Keep stamina visible below | 0% to 100% in 5-point steps (default 20%) |
| Player status: Health and stamina | Stamina hold duration | 0 to 10 seconds in 0.5-second steps |
| Combat: Ability cooldowns | Ability cooldowns mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Ability cooldowns | Ability cooldowns opacity | 0% to 100% in 5-point steps |
| Combat: Crosshair | Crosshair mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Crosshair | Crosshair opacity | 0% to 100% in 5-point steps |
| Combat: Enemies | Hide enemy health bars | Off, On (default On) |
| Combat: Enemies | Hide enemy names | Off, On |
| Combat: Enemies | Hide enemy difficulty icons | Off, On |
| Combat: Enemies | Hide enemy effect icons | Off, On (default Off) |
| Combat: Enemies | Hide claw slash marks | Off, On (default On) |
| Combat: Focus activation prompt | Focus activation prompt mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Focus activation prompt | Focus activation prompt opacity | 0% to 100% in 5-point steps |
| Combat: Focus charge | Focus charge mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Focus charge | Focus charge opacity | 0% to 100% in 5-point steps |
| Combat: Focus panel | Combat focus mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Focus panel | Combat focus opacity | 0% to 100% in 5-point steps |
| Combat: Indicators | Show counterattack direction | Off (default), On |
| Combat: Indicators | Show unblockable warning | Off (default), On |
| Combat: Indicators | Show directional parry cues | Off (default), On |
| Combat: Indicators | Show enemy dot/diamond | Off (default), On |
| Combat: Indicators | Show lock icon | Off (default), On |
| Combat: Indicators | Combat cue size | 10%–200%, step 10%; default 100% |
| Combat: Quickslots | Quickslots mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Quickslots | Quickslots opacity | 0% to 100% in 5-point steps |
| Combat: Quickslots | Quickslot shortcuts mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Quickslots | Quickslot shortcuts opacity | 0% to 100% in 5-point steps |
| Combat: Quickslots | Switch quickslots prompt mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Quickslots | Switch quickslots prompt opacity | 0% to 100% in 5-point steps |
| Combat: Quickslots | Show quickslots after switching | 0 to 10 seconds in 0.5-second steps (default 3; 0 disables) |
| Combat: Special attack cooldown | Special attack cooldown mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Combat: Special attack cooldown | Special attack cooldown opacity | 0% to 100% in 5-point steps |
| Exploration: Compass | Compass mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Exploration: Compass | Compass opacity | 0% to 100% in 5-point steps |
| Exploration: Quest tracker | Quest tracker mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Exploration: Quest tracker | Quest tracker opacity | 0% to 100% in 5-point steps |
| Exploration: Time of day | Time of day mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Exploration: Time of day | Time of day opacity | 0% to 100% in 5-point steps |
| Exploration: Time of day | Time of day reveal duration | 0 to 10 seconds in 0.5-second steps (default 4 seconds) |
| Controls: Action prompts | Hide sprint/haste prompt | Off, On (default On) |
| Controls: Controls legend | Controls legend mode | Vanilla, Quiet Dawn (default), Fixed Opacity, Always Hidden |
| Controls: Controls legend | Controls legend opacity | 0% to 100% in 5-point steps |
| Controls: HUD peek | Show HUD trigger | Off, Hold controls legend (default), Focus mode |
| Controls: HUD peek | Show HUD duration | 0 to 10 seconds in 0.5-second steps |
| Each eligible Quiet Dawn player-panel category | HUD Peek Behaviour | Exclude, Include (default) |
| Each eligible Fixed Opacity player-panel category | HUD Peek Behaviour | Don't change (default), Raise opacity |
| Diagnostics | Logging | Off, Error, Warning (default), Info, Debug |
| Diagnostics | Find visible Activation Charges widget | Off (default), On; shown only when Logging is Debug |

Turn off **Hide enemy health bars** to restore ordinary enemy and boss health bars, end caps and boss health-phase indicators. Turn off **Hide enemy names** to restore name labels (boss names), or **Hide enemy difficulty icons** to restore difficulty indicators. All three choices are independent and restore the game's normal visibility for that information. Apply to save and update the active game. The player HUD peek keeps these choices in effect. A named child gets a short construction readiness window and one later target/owner rearm; if it remains unavailable, that field is dormant for the current bar rather than repeatedly searching on every event. A newly constructed bar receives a fresh window. At startup, older settings files receive any missing enemy-information options, set to On. Existing preferences and comments are preserved, with a backup before adding missing options.

The five Combat: Indicators toggles work independently of the game's Directional Indicator option. Counterattack directions show the attack opening after a perfect parry; unblockable warnings show the skull; directional parry cues show the incoming direction and highlight its arrow during the parry window; the lock option shows a padlock on a hard-locked target between cues. Show enemy dot/diamond restores the red marker independently of Show lock icon. It also controls the red secondary-enemy attack dot beside an enemy health bar: Off hides it, and On allows the game to show it when appropriate, independently of health-bar visibility. With only the marker enabled, locked and unlocked targets show the diamond. With both enabled, a hard-locked target shows the padlock. Directions and unblockable warnings take priority. An active unblockable warning retains its skull when soft-lock or hard-lock targets change, even with the enemy dot/diamond disabled. All five toggles default to Off. Combat cue size scales the whole cue group from 10% to 200% in 10% steps, defaulting to 100%. Apply to save and update the active game. Existing counterattack choices are retained when adding the new controls. Logging reports the observed icon, selected arrow or warning, lock state, size and readiness failures in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The optional interface uses toggles, labeled choices and sliders. For manual editing, use the exact numeric keys and values below.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.

**Panel modes and opacity:** Each of the 17 player panels has a **Vanilla / Quiet Dawn / Fixed Opacity / Always Hidden** mode picker. Vanilla leaves opacity and visibility to the game and excludes the panel from Quiet Dawn reveals. Quiet Dawn uses automatic hiding, resource alerts and contextual reveals. Fixed Opacity shows a conditional 0%–100% slider in 5% steps. Always Hidden keeps the panel at 0%, including during cooldowns and HUD peek, and conceals its irrelevant Opacity, Size and HUD Peek Behaviour controls. Fixed values are not overridden by alerts, switching or time changes; their HUD Peek Behaviour can optionally raise them during a peek. The game retains its contextual visibility rules.

**Show HUD** has three trigger choices. **Off** disables it. **Hold controls legend** (the default) uses the game's **Toggle Controls Legend** action: hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap; for keyboard, change the game's Controls Legend binding. **Focus mode** keeps participating panels visible for the complete time Focus is active, then begins the configured Show HUD duration when Focus ends. Show HUD duration controls each timed reveal after its trigger. A Quiet Dawn panel's **HUD Peek Behaviour** offers default-on **Include** or **Exclude**, which keeps it under its normal Quiet Rule during both triggers. A Fixed Opacity panel instead offers default **Don't change** or **Raise opacity**, which temporarily raises it to 100%. Always Hidden and Vanilla expose no HUD Peek Behaviour because it cannot affect them. Show HUD brings participating panels up together and restores their automatic visibility together when the peek ends. Panels with an active resource alert, cooldown or other independent reveal keep their own visibility rules. The combat-focus action wheel remains hidden in Quiet Dawn mode; Vanilla, Fixed Opacity and Always Hidden keep their own behavior.

**Logging** accepts `0` (Off), `1` (Error), `2` (Warning), `3` (Info) or `4` (Debug). Each level also includes the ones above it, and everything is written to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Warning is the default and suits normal play: it reports failures and features that could not start, without per-event noise. Debug is the troubleshooting level and the only one with a measurable cost. Logging replaced the earlier `debugLogging` toggle; on first run the old value is carried over, with On becoming Debug and Off becoming Warning, and the retired key is then ignored. Slash-effect diagnostics include preparation, retention and restoration counts, bounded failures and `clawMarks` worker timings. Cached panel updates also report aggregate `visibility` timings and peek/resource/refresh commit counts. These timings overlap the main worker timing.

**Find visible Activation Charges widget** appears only while Logging is Debug. Turn it On, Apply, then enter combat once with Activation Charges in Vanilla mode. After a short settle delay the locator asks the owned Focus Charge `DynamicEntryBox` for its runtime entries, hides each of the game's up-to-four charge slots for two seconds, restores it, and leaves one visible second before testing the next. The log identifies each candidate by ordinal, class and native address. The cycle runs once per HUD session; Apply Off then On to arm it again. It performs no global widget search, does not run during ordinary gameplay, restores entries after every test and at session close, and never changes the normal Fade contract.

With Logging On, marker diagnostics also report unavailable ownership and skipped marker updates. Readiness retries stop after eight attempts and resume on a later marker event; these messages remain quiet with Logging Off.

**Timers:** all five HUD durations range from 0 to 10 seconds in 0.5-second steps. Zero disables that timed reveal. With the Focus mode Show HUD trigger, zero skips only the post-Focus hold: eligible panels remain visible for as long as Focus stays active. Health and stamina thresholds and positive panel opacity still apply independently. Defaults remain 4 seconds for health/blood, 1.5 seconds for stamina, 3 seconds for HUD peek, 3 seconds for quickslot switching and 4 seconds for time of day. Older durations above 10 seconds are capped at 10; other fractional durations round to the nearest half-second. If an existing settings file needs this adjustment, the original is kept as `settings.ini.before-short-timers`, preserving all other preferences and comments.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply only in Quiet Dawn mode. Fixed Opacity is independent of resource-driven hiding; Vanilla follows the game and Always Hidden remains hidden.

Older On/Off panel settings are imported into the new opacity controls: Off becomes 0% and On becomes 100%. The upgrade adds the new keys while preserving existing settings, unknown keys and comments; it retains the original file under a `settings.ini.before-*` name for the upgrade being applied (currently `settings.ini.before-panel-modes`). Earlier recovery backups are retained. Compass opacity remains unchanged. Keep recovery files if an upgrade error is reported.

Switching items/abilities briefly reveals quickslots in Quiet Dawn mode. Their Always Hidden and Vanilla choices do not use this reveal; Fixed Opacity uses its selected value except when its HUD Peek Behaviour explicitly raises it. The switch hint keeps its own mode. Quiet Dawn shows the special-attack panel only while recharging; Always Hidden keeps it hidden even during recharge. Vanilla follows the game. Reveal durations use game time and pause with the game.

Small blood fluctuations below 0.2% of bar capacity do not renew the health hold. Low-resource thresholds and human damage/stamina alerts remain unchanged. Existing opacity settings gain the new duration without changing selected values; keep the `settings.ini.before-hud-events` recovery copy.

**Time of day:** Quiet Dawn mode hides the complete time panel between time changes and HUD peeks. Activities that advance time, including shrine restoration, reveal it at 100% and restart the reveal duration, which defaults to 4 seconds. If the activity hides the HUD, the full reveal waits until the HUD returns. Previewing an activity without advancing time does not reveal it. Pausing preserves the remaining duration. Set the duration to 0 seconds to disable automatic time-change reveals; HUD peek still works. Fixed Opacity keeps the selected value without timed reveals and raises only if its HUD Peek Behaviour explicitly selects Raise opacity. Vanilla follows the game. Existing settings gain these two options without resetting other preferences.

**Hide sprint/haste prompt** is in the **Controls: Action prompts** section. It suppresses only the running prompts in human and vampire form, including after prompt refreshes and during manual HUD peek. It suppresses running prompts at their source and works independently of the display language. Other action prompts retain game behavior. Apply to save and update the active game. Existing settings receive the new option set to On, with their preferences and comments preserved.

**Focus activation prompt:** Quiet Dawn mode or Always Hidden keeps the Toggle abilities button and label hidden in Focus mode and during HUD peek. Vanilla restores game control; Fixed Opacity uses the selected value when the game shows the prompt unless its HUD Peek Behaviour explicitly raises it. Ability switching still works. Apply to save and update the active game.

**Healing and regeneration:** Health and blood gains of at least 0.2% of the bar reveal the stat panel and refresh the health hold duration (4 seconds by default). Repeated qualifying regeneration gains keep the panel visible until that duration expires after the last gain. Smaller gains stay quiet until the bar reaches full. That full-bar reveal rearms only after a deficit of at least 0.2%, preventing repeated near-full notifications. These alerts apply only to stat panels in Quiet Dawn mode; Fixed Opacity, Always Hidden and Vanilla do not use them. The health / blood hold duration also controls these healing reveals in Quiet Dawn mode; 0 disables them. Small stamina recovery does not trigger a reveal.

## Manual setting reference

All entries below belong under `[Settings]`. Defaults apply to a fresh install without imported preferences. Leave unlisted diagnostic tuning entries at their generated values.

| Setting | INI key | Default | Supported manual values |
| --- | --- | --- | --- |
| Enabled | `enabled` | `1` | 0 = Off, 1 = On |
| Hide enemy health bars | `hideEnemyHealthBars` | `1` | 0 = Off, 1 = On |
| Hide enemy effect icons | `hideEnemyEffectIcons` | `0` | 0 = Off, 1 = On |
| Hide player effect icons | `hidePlayerEffectIcons` | `0` | 0 = Off, 1 = On |
| Hide player combat effects | `hidePlayerCombatEffects` | `0` | 0 = Off, 1 = On |
| Hide enemy names | `hideEnemyNames` | `1` | 0 = Off, 1 = On |
| Hide enemy difficulty icons | `hideEnemyDifficultyIcons` | `1` | 0 = Off, 1 = On |
| Hide claw slash marks | `hideClawSlashMarks` | `1` | 0 = Off, 1 = On |
| Show counterattack direction | `showCounterattackDirection` | `0` | 0 = Off, 1 = On |
| Show unblockable warning | `showUnblockableWarning` | `0` | 0 = Off, 1 = On |
| Show directional parry cues | `showDirectionalParry` | `0` | 0 = Off, 1 = On |
| Show enemy dot/diamond | `showEnemyMarker` | `0` | 0 = Off, 1 = On |
| Show lock icon | `showLockIcon` | `0` | 0 = Off, 1 = On |
| Combat cue size | `combatCueSize` | `100` | 10 to 200, step 10 |
| Keep health visible below | `healthThreshold` | `50` | 0 to 100 percent; 5-point steps match the menu |
| Keep stamina visible below | `staminaThreshold` | `20` | 0 to 100 percent; 5-point steps match the menu |
| Health / blood hold duration | `healthHoldSeconds` | `4` | 0 to 10, step 0.5 |
| Stamina hold duration | `staminaHoldSeconds` | `1.5` | 0 to 10, step 0.5 |
| Show HUD duration | `manualPeekSeconds` | `3` | 0 to 10, step 0.5 |
| Fade elements in and out | `fadeTransitions` | `0` | 0 = Off, 1 = On |
| Fade in duration | `fadeInSeconds` | `0.35` | 0 to 2 seconds, step 0.01 |
| Fade out duration | `fadeOutSeconds` | `1.30` | 0 to 2 seconds, step 0.01 |
| Show HUD trigger | `manualPeek` | `1` | 0 = Off, 1 = Hold controls legend, 2 = Focus mode |
| Hide sprint/haste prompt | `hideSprintPrompt` | `1` | 0 = Off, 1 = On |
| Time of day mode | `mode_WBP_HudTimer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Time of day opacity | `opacity_WBP_HudTimer` | `0` | 0 to 100, step 5 |
| Time of day size | `scale_WBP_HudTimer` | `100` | 25 to 200, step 5 |
| Time of day reveal duration | `timeHoldSeconds` | `4` | 0 to 10, step 0.5 |
| Compass mode | `mode_WBP_Compass` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Compass opacity | `compassOpacity` | `0` | 0 to 100 percent; 5-point steps match the menu |
| Compass size | `scale_WBP_Compass` | `100` | 25 to 200, step 5 |
| Human health and stamina mode | `mode_HumanStats` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Human health and stamina opacity | `opacity_HumanStats` | `0` | 0 to 100, step 5 |
| Human health and stamina size | `scale_HumanStats` | `100` | 25 to 200, step 5 |
| Vampire blood and stamina mode | `mode_VampireStats` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Vampire blood and stamina opacity | `opacity_VampireStats` | `0` | 0 to 100, step 5 |
| Vampire blood and stamina size | `scale_VampireStats` | `100` | 25 to 200, step 5 |
| Quest tracker mode | `mode_WBP_HUD_QuestInfo` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Quest tracker opacity | `opacity_WBP_HUD_QuestInfo` | `0` | 0 to 100, step 5 |
| Quest tracker size | `scale_WBP_HUD_QuestInfo` | `100` | 25 to 200, step 5 |
| Quickslots mode | `mode_WBP_HUD_Quickslots` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Quickslots opacity | `opacity_WBP_HUD_Quickslots` | `0` | 0 to 100, step 5 |
| Quickslots size | `scale_WBP_HUD_Quickslots` | `100` | 25 to 200, step 5 |
| Crosshair mode | `mode_Crosshair` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Crosshair opacity | `opacity_Crosshair` | `0` | 0 to 100, step 5 |
| Crosshair size | `scale_Crosshair` | `100` | 25 to 200, step 5 |
| Quickslot shortcuts mode | `mode_WBP_AA_Quickslots` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Quickslot shortcuts opacity | `opacity_WBP_AA_Quickslots` | `0` | 0 to 100, step 5 |
| Quickslot shortcuts size | `scale_WBP_AA_Quickslots` | `100` | 25 to 200, step 5 |
| Focus activation prompt mode | `mode_WBP_OpenFocusPrompt` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Focus activation prompt opacity | `opacity_WBP_OpenFocusPrompt` | `0` | 0 to 100, step 5 |
| Focus activation prompt size | `scale_WBP_OpenFocusPrompt` | `100` | 25 to 200, step 5 |
| Switch quickslots prompt mode | `mode_WBP_HUD_Quickslots_ChangePrompt` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Switch quickslots prompt opacity | `opacity_WBP_HUD_Quickslots_ChangePrompt` | `0` | 0 to 100, step 5 |
| Switch quickslots prompt size | `scale_WBP_HUD_Quickslots_ChangePrompt` | `100` | 25 to 200, step 5 |
| Controls legend mode | `mode_WBP_ControlsLegend` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Controls legend opacity | `opacity_WBP_ControlsLegend` | `0` | 0 to 100, step 5 |
| Controls legend size | `scale_WBP_ControlsLegend` | `100` | 25 to 200, step 5 |
| Active buffs mode | `mode_WBP_BuffContainer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Active buffs opacity | `opacity_WBP_BuffContainer` | `0` | 0 to 100, step 5 |
| Active buffs size | `scale_WBP_BuffContainer` | `100` | 25 to 200, step 5 |
| Ability cooldowns mode | `mode_WBP_HUD_AbilityCooldownsContainer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Ability cooldowns opacity | `opacity_WBP_HUD_AbilityCooldownsContainer` | `0` | 0 to 100, step 5 |
| Ability cooldowns size | `scale_WBP_HUD_AbilityCooldownsContainer` | `100` | 25 to 200, step 5 |
| Combat focus mode | `mode_CombatFocusPanel` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Combat focus opacity | `opacity_CombatFocusPanel` | `0` | 0 to 100, step 5 |
| Combat focus size | `scale_CombatFocusPanel` | `100` | 25 to 200, step 5 |
| Focus charge mode | `mode_WBP_HUD_FocusCharge_Bar` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Focus charge opacity | `opacity_WBP_HUD_FocusCharge_Bar` | `0` | 0 to 100, step 5 |
| Focus charge size | `scale_WBP_HUD_FocusCharge_Bar` | `100` | 25 to 200, step 5 |
| Special attack cooldown mode | `mode_WBP_HUD_SpecialAttackCooldown` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Special attack cooldown opacity | `opacity_WBP_HUD_SpecialAttackCooldown` | `0` | 0 to 100, step 5 |
| Special attack cooldown size | `scale_WBP_HUD_SpecialAttackCooldown` | `100` | 25 to 200, step 5 |
| Experience bar mode | `mode_XPBar` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden |
| Experience bar opacity | `opacity_XPBar` | `0` | 0 to 100, step 5 |
| Experience bar size | `scale_XPBar` | `100` | 25 to 200, step 5 |
| Show quickslots after switching | `switchRevealSeconds` | `3` | 0 to 10, step 0.5 |
| Logging | `logLevel` | `2` | 0 = Off, 1 = Error, 2 = Warning, 3 = Info, 4 = Debug |
| Find visible Activation Charges widget | `debugFocusChargeLocator` | `0` | 0 = Off, 1 = one Debug-only visual locator cycle on the next combat entry |

Each `mode_<panel>` accepts 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity or 3 = Always Hidden. The saved opacity percentage is used only in Fixed Opacity mode. Always Hidden forces 0% and hides the saved Opacity, Size and HUD Peek Behaviour controls. For eligible panels, `showHUD_<panel>` uses 0 = Exclude and 1 = Include in Quiet Dawn mode; `fixedPeek_<panel>` uses 0 = Don't change and 1 = Raise opacity in Fixed Opacity mode. Timers accept 0 to 10 seconds in 0.5-second steps and apply only to Quiet Dawn reveals. Opacity and threshold percentages use a 0 to 100 scale. Panel sizes accept 25 to 200 in 5-point steps; combat cue size accepts 10 to 200 in 10-point steps.

If a value is malformed, duplicated, missing, or outside the supported range, the settings loader reports it in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Correct the existing line or restore your backup, then restart and load a save.

## Live Apply

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Only affected panels, resource reveals, combat cues, enemy visuals or prompts are queued. Repeated size changes use the original scale and pivot; returning to 100% restores them. Widget caches and native event bindings remain in place for ordinary changes.
