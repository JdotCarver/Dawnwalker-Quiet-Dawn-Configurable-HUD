# Settings

Required: [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271). Open Mod Settings and press Apply to save and update gameplay.

## Menu categories

The menu runs from General through Player status, Combat, Exploration and Controls, ending with Diagnostics. Categories are alphabetical within each group, using headings such as Combat / Crosshair and Exploration / Compass. Each panel keeps its mode, conditional opacity and size together, followed by related thresholds or reveal durations. Combat / Indicators contains counterattack directions, parry cues, unblockable warnings, the enemy dot/diamond, the lock icon and cue size. Logging remains the final entry.

| Category | Controls |
| --- | --- |
| General | Enabled |
| Player status / Active buffs | Hide player effect icons, Active buffs mode, opacity and size |
| Player status / Combat effects | Hide Crimson Rush effect |
| Player status / Experience | Experience bar opacity |
| Player status / Health and stamina | Human and vampire panel opacity, health/blood and stamina thresholds, and their hold durations |
| Combat / Ability cooldowns | Ability cooldowns opacity |
| Combat / Crosshair | Crosshair opacity |
| Combat / Enemies | Enemy health bars, names, difficulty icons, effect icons, Shredded Touch marks and vampire claw hit marks |
| Combat / Focus activation prompt | Toggle abilities hint opacity |
| Combat / Focus charge | Focus charge bar opacity |
| Combat / Focus panel | Combat focus panel opacity |
| Combat / Indicators | Counterattack directions, unblockable warnings, parry cues, enemy dot/diamond, lock icon and cue size |
| Combat / Quickslots | Item and ability quickslot opacity, switch prompt opacity and switch reveal duration |
| Combat / Special attack cooldown | Special attack cooldown opacity |
| Exploration / Compass | Compass opacity |
| Exploration / Quest tracker | Quest tracker opacity |
| Exploration / Time of day | Panel opacity and reveal duration |
| Controls / Action prompts | Hide sprint/haste prompt |
| Controls / Controls legend | Controls legend opacity |
| Controls / HUD peek | Show HUD on hold and its duration |
| Diagnostics | Logging |

Each player-panel category has a mode picker, an opacity slider visible only in Fixed opacity mode, and an independent size slider. The 17 size sliders use 25% to 200%, in 5% steps, with a 100% default.

## Default behavior

On a fresh install with no saved or imported preferences, the mod is enabled and all 17 player panels start in Quiet Dawn mode (automatic hiding and contextual reveals), with saved fixed opacities at 0%. All panel sizes start at 100%. Enemy health bars, enemy names, difficulty icons, claw slash marks, and sprint/haste prompts are hidden. All five combat indicator toggles are Off; cue size is 100%. Health/blood below 50% or stamina below 20% keeps the stat panels visible. Health alerts hold for 4 seconds and stamina alerts for 1.5 seconds. Holding Controls Legend reveals the HUD for 3 seconds; switching quickslots reveals them for 3 seconds; time changes reveal the time panel for 4 seconds. Logging is Off. Existing saved or supported imported preferences take precedence over these defaults.

Older settings files receive missing panel size keys at 100%, preserving existing values, comments and prior backups. Claw-mark upgrades retain `settings.ini.before-claw-slash-marks`; older `settings.ini.before-panel-scaling` backups are retained. Existing malformed or duplicate values are rejected without replacing the file.

New effect-icon settings are added as Off to older INIs, preserving existing entries and comments in the updated file and the original in `settings.ini.before-effect-icons`. Existing recovery backups are retained.

## Crimson Rush effect

**Hide Crimson Rush effect**, under Player status / Combat effects, hides Crimson Rush's bright red arm effect in human and vampire form. It defaults to Off and is separate from effect icons and enemy claw slash marks. Buff strength, duration and sound stay unchanged. Apply updates effects already active on the player; Off restores their visibility.

The setting is `hidePlayerCombatEffects` (0 = Off, 1 = On). Older INIs receive this missing key with a `settings.ini.before-player-combat-effects` backup. Existing preferences and comments are retained; conflicting backups and malformed values are rejected.

## Effect icons

**Hide enemy effect icons** under Combat / Enemies hides effect icons and timers, including bleeding, on ordinary enemies and bosses. It is independent of enemy health bars, names, difficulty icons, combat warnings and the two claw-mark settings.

**Hide player effect icons** under Player status / Active buffs hides the player's buff/debuff icons and their timers, including during Show HUD. While On it overrides Active buffs mode and opacity; turning it Off resumes those saved settings. Size preferences are retained.

Both toggles default to Off. They only hide HUD visuals; damage, bleeding, buffs, debuffs and their durations keep their game behavior. Press Apply to update the active game.

## Panel modes

Each of the 17 player panels has a **Vanilla / Quiet Dawn / Fixed opacity** mode picker. Vanilla leaves opacity and visibility to the game and excludes the panel from Quiet Dawn reveals. Quiet Dawn uses automatic hiding, resource alerts and contextual reveals. Fixed opacity shows a conditional 0%–100% slider in 5% steps; 0% keeps the panel hidden, including during cooldowns and HUD peek. Fixed values are not overridden by alerts, switching, time changes or peek. The game retains its contextual visibility rules. Size remains independent in all three modes.

The opacity slider appears immediately when Fixed opacity is selected and disappears in the other modes. Hidden sliders retain their saved values. Apply commits both mode and opacity together; Restore discards pending edits, and Reset returns modes to Quiet Dawn after Apply.

Older settings gain missing mode keys without changing opacity values, comments, unknown keys or existing recovery copies. Previous 0% becomes Quiet Dawn; positive values become Fixed opacity. The original file is backed up as `settings.ini.before-panel-modes`. Invalid or duplicate values are rejected before replacement. Selecting Vanilla during play conditionally restores the last unmodified game opacity and stops overriding it; later game updates remain in control. Panel size is independent: select 100% size for original proportions.

## Claw slash marks

**Hide vampire claw hit marks** hides the red scratch effects from ordinary vampire claw hits. **Hide Shredded Touch marks** independently hides Shredded Touch slash effects, including its sword variant. Both are under **Combat / Enemies** and default to On. Damage, bleeding, swing trails and separate hit sprays keep their game behavior. Apply to save and update the active game.

The Shredded Touch setting retains `hideClawSlashMarks`. On upgrade, missing `hideVampireClawHitMarks` inherits that saved value, retaining the previous combined preference. The original INI is backed up as `settings.ini.before-vampire-claw-hit-marks`; existing preferences, comments and older backups are preserved. Afterwards, the two settings are independent.

## Panel size

All 17 player panels have independent size sliders from 25% to 200% in 5% steps, defaulting to 100%. Edge panels grow inward and centered panels stay centered. Original layout spacing stays fixed, so large sizes can overlap nearby elements. Apply to save and update the active game. Scaling uses each panel's original proportions, including its text and icons. Size is independent of mode and contextual visibility. Quiet Dawn reveals use the selected size; Fixed opacity at 0% keeps the panel hidden.

Only initialization, replacement and settings Apply events apply transforms; there is no recurring size update. Returning to 100% or disabling the mod restores the original size and scaling origin.

## Manual configuration

1. Install Quiet Dawn through Vortex with its required UE4SS loader, then launch the game once. Quiet Dawn creates its own `settings.ini`; you can load a save and play immediately with the defaults.
2. Close the game and back up that generated file. Open `<game folder>/Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/settings.ini` in a text editor.
3. Edit the existing entries under `[Settings]`, keeping every other entry and the section header. Use `1` for On and `0` for Off; panel modes use 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity. Use percentages such as `50` (not `0.5`), and seconds such as `1.5`. Keep the exact key names and use a decimal point. Do not add duplicate keys or replace the file with the example below.
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

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Startup prepares the settings file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off. Panel size diagnostics report applied sizes, bounded readiness failures and transform-write counts through the existing worker timing summary.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| Player status / Active buffs | Hide player effect icons | Off, On (default Off) |
| Player status / Active buffs | Active buffs mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Player status / Active buffs | Active buffs opacity | 0% to 100% in 5-point steps |
| Player status / Combat effects | Hide Crimson Rush effect | Off, On (default Off) |
| Player status / Experience | Experience bar mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Player status / Experience | Experience bar opacity | 0% to 100% in 5-point steps |
| Player status / Health and stamina | Human health and stamina mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Player status / Health and stamina | Human health and stamina opacity | 0% to 100% in 5-point steps |
| Player status / Health and stamina | Vampire blood and stamina mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Player status / Health and stamina | Vampire blood and stamina opacity | 0% to 100% in 5-point steps |
| Player status / Health and stamina | Keep health visible below | 0% to 100% in 5-point steps (default 50%) |
| Player status / Health and stamina | Health / blood hold duration | 0 to 10 seconds in 0.5-second steps |
| Player status / Health and stamina | Keep stamina visible below | 0% to 100% in 5-point steps (default 20%) |
| Player status / Health and stamina | Stamina hold duration | 0 to 10 seconds in 0.5-second steps |
| Combat / Ability cooldowns | Ability cooldowns mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Ability cooldowns | Ability cooldowns opacity | 0% to 100% in 5-point steps |
| Combat / Crosshair | Crosshair mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Crosshair | Crosshair opacity | 0% to 100% in 5-point steps |
| Combat / Enemies | Hide enemy health bars | Off, On (default On) |
| Combat / Enemies | Hide enemy names | Off, On |
| Combat / Enemies | Hide enemy difficulty icons | Off, On |
| Combat / Enemies | Hide enemy effect icons | Off, On (default Off) |
| Combat / Enemies | Hide Shredded Touch marks | Off, On (default On) |
| Combat / Enemies | Hide vampire claw hit marks | Off, On (default On) |
| Combat / Focus activation prompt | Focus activation prompt mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Focus activation prompt | Focus activation prompt opacity | 0% to 100% in 5-point steps |
| Combat / Focus charge | Focus charge mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Focus charge | Focus charge opacity | 0% to 100% in 5-point steps |
| Combat / Focus panel | Combat focus mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Focus panel | Combat focus opacity | 0% to 100% in 5-point steps |
| Combat / Indicators | Show counterattack direction | Off (default), On |
| Combat / Indicators | Show unblockable warning | Off (default), On |
| Combat / Indicators | Show directional parry cues | Off (default), On |
| Combat / Indicators | Show enemy dot/diamond | Off (default), On |
| Combat / Indicators | Show lock icon | Off (default), On |
| Combat / Indicators | Combat cue size | 10%–200%, step 10%; default 100% |
| Combat / Quickslots | Quickslots mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Quickslots | Quickslots opacity | 0% to 100% in 5-point steps |
| Combat / Quickslots | Quickslot shortcuts mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Quickslots | Quickslot shortcuts opacity | 0% to 100% in 5-point steps |
| Combat / Quickslots | Switch quickslots prompt mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Quickslots | Switch quickslots prompt opacity | 0% to 100% in 5-point steps |
| Combat / Quickslots | Show quickslots after switching | 0 to 10 seconds in 0.5-second steps (default 3; 0 disables) |
| Combat / Special attack cooldown | Special attack cooldown mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Combat / Special attack cooldown | Special attack cooldown opacity | 0% to 100% in 5-point steps |
| Exploration / Compass | Compass mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Exploration / Compass | Compass opacity | 0% to 100% in 5-point steps |
| Exploration / Quest tracker | Quest tracker mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Exploration / Quest tracker | Quest tracker opacity | 0% to 100% in 5-point steps |
| Exploration / Time of day | Time of day mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Exploration / Time of day | Time of day opacity | 0% to 100% in 5-point steps |
| Exploration / Time of day | Time of day reveal duration | 0 to 10 seconds in 0.5-second steps (default 4 seconds) |
| Controls / Action prompts | Hide sprint/haste prompt | Off, On (default On) |
| Controls / Controls legend | Controls legend mode | Vanilla, Quiet Dawn (default), Fixed opacity |
| Controls / Controls legend | Controls legend opacity | 0% to 100% in 5-point steps |
| Controls / HUD peek | Show HUD on hold | Off, On |
| Controls / HUD peek | Show HUD duration | 0 to 10 seconds in 0.5-second steps |
| Diagnostics | Logging | Off, On |

Turn off **Hide enemy health bars** to restore ordinary enemy and boss health bars, end caps and boss health-phase indicators. Turn off **Hide enemy names** to restore name labels (boss names), or **Hide enemy difficulty icons** to restore difficulty indicators. All three choices are independent and restore the game's normal visibility for that information. Apply to save and update the active game. The player HUD peek keeps these choices in effect. At startup, older settings files receive any missing enemy-information options, set to On. Existing preferences and comments are preserved, with a backup before adding missing options.

The five Combat / Indicators toggles work independently of the game's Directional Indicator option. Counterattack directions show the attack opening after a perfect parry; unblockable warnings show the skull; directional parry cues show the incoming direction and highlight its arrow during the parry window; the lock option shows a padlock on a hard-locked target between cues. Show enemy dot/diamond restores the red marker independently of Show lock icon. It also controls the red secondary-enemy attack dot beside an enemy health bar: Off hides it, and On allows the game to show it when appropriate, independently of health-bar visibility. With only the marker enabled, locked and unlocked targets show the diamond. With both enabled, a hard-locked target shows the padlock. Directions and unblockable warnings take priority. An active unblockable warning retains its skull when soft-lock or hard-lock targets change, even with the enemy dot/diamond disabled. All five toggles default to Off. Combat cue size scales the whole cue group from 10% to 200% in 10% steps, defaulting to 100%. Apply to save and update the active game. Existing counterattack choices are retained when adding the new controls. Logging reports the observed icon, selected arrow or warning, lock state, size and readiness failures in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The optional interface uses toggles, labeled choices and sliders. For manual editing, use the exact numeric keys and values below.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.

**Panel modes and opacity:** Each of the 17 player panels has a **Vanilla / Quiet Dawn / Fixed opacity** mode picker. Vanilla leaves opacity and visibility to the game and excludes the panel from Quiet Dawn reveals. Quiet Dawn uses automatic hiding, resource alerts and contextual reveals. Fixed opacity shows a conditional 0%–100% slider in 5% steps; 0% keeps the panel hidden, including during cooldowns and HUD peek. Fixed values are not overridden by alerts, switching, time changes or peek. The game retains its contextual visibility rules. Size remains independent in all three modes.

**Show HUD** uses the game's **Toggle Controls Legend** action. Hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap. For keyboard, change the game's Controls Legend binding. Quiet Dawn follows the remapped action. Show HUD duration controls the time the HUD remains visible after activation. Show HUD brings eligible panels up together and restores their automatic visibility together when the peek ends. Panels with an active resource alert, cooldown or other independent reveal keep their own visibility rules. Only panels in Quiet Dawn mode participate in peek. The combat-focus action wheel remains hidden in Quiet Dawn mode; Vanilla and Fixed opacity keep their own behavior.

**Logging** is the final optional menu setting and the only diagnostic control; manually set `debugLogging` to `0` (Off) or `1` (On). Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Slash-effect diagnostics include preparation, retention and restoration counts, bounded failures and `clawMarks` worker timings. Ordinary claw hits additionally report hook readiness, visibility writes/restores and aggregate `clawHits` callback timings. Cached panel updates also report aggregate `visibility` timings and peek/resource/refresh commit counts. These timings overlap the main worker timing.

With Logging On, marker diagnostics also report unavailable ownership and skipped marker updates. Readiness retries stop after eight attempts and resume on a later marker event; these messages remain quiet with Logging Off.

**Timers:** all five HUD durations range from 0 to 10 seconds in 0.5-second steps. Zero disables that timed reveal. Health and stamina thresholds and positive panel opacity still apply independently. Defaults remain 4 seconds for health/blood, 1.5 seconds for stamina, 3 seconds for HUD peek, 3 seconds for quickslot switching and 4 seconds for time of day. Older durations above 10 seconds are capped at 10; other fractional durations round to the nearest half-second. If an existing settings file needs this adjustment, the original is kept as `settings.ini.before-short-timers`, preserving all other preferences and comments.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply only in Quiet Dawn mode. Fixed opacity is independent of resource-driven hiding; Vanilla follows the game.

Older On/Off panel settings are imported into the new opacity controls: Off becomes 0% and On becomes 100%. The upgrade adds the new keys while preserving existing settings, unknown keys and comments; it retains the original file under a `settings.ini.before-*` name for the upgrade being applied (currently `settings.ini.before-panel-modes`). Earlier recovery backups are retained. Compass opacity remains unchanged. Keep recovery files if an upgrade error is reported.

Switching items/abilities briefly reveals quickslots in Quiet Dawn mode. Their Fixed opacity and Vanilla choices do not use this reveal. The switch hint keeps its own mode. Quiet Dawn shows the special-attack panel only while recharging; Fixed opacity at 0% hides it even during recharge. Vanilla follows the game. Reveal durations use game time and pause with the game.

Small blood fluctuations below 0.2% of bar capacity do not renew the health hold. Low-resource thresholds and human damage/stamina alerts remain unchanged. Existing opacity settings gain the new duration without changing selected values; keep the `settings.ini.before-hud-events` recovery copy.

**Time of day:** Quiet Dawn mode hides the complete time panel between time changes and HUD peeks. Activities that advance time, including shrine restoration, reveal it at 100% and restart the reveal duration, which defaults to 4 seconds. If the activity hides the HUD, the full reveal waits until the HUD returns. Previewing an activity without advancing time does not reveal it. Pausing preserves the remaining duration. Set the duration to 0 seconds to disable automatic time-change reveals; HUD peek still works. Fixed opacity keeps the selected value without timed reveals or peek overrides. Vanilla follows the game. Existing settings gain these two options without resetting other preferences.

**Hide sprint/haste prompt** is in the **Controls / Action prompts** section. It suppresses only the running prompts in human and vampire form, including after prompt refreshes and during manual HUD peek. It suppresses running prompts at their source and works independently of the display language. Other action prompts retain game behavior. Apply to save and update the active game. Existing settings receive the new option set to On, with their preferences and comments preserved.

**Focus activation prompt:** Quiet Dawn mode or Fixed opacity at 0% keeps the Toggle abilities button and label hidden in Focus mode and during HUD peek. Vanilla restores game control; Fixed opacity uses the selected value when the game shows the prompt. Ability switching still works. Apply to save and update the active game.

**Healing and regeneration:** Health and blood gains of at least 0.2% of the bar reveal the stat panel and refresh the health hold duration (4 seconds by default). Repeated qualifying regeneration gains keep the panel visible until that duration expires after the last gain. Smaller gains stay quiet until the bar reaches full. That full-bar reveal rearms only after a deficit of at least 0.2%, preventing repeated near-full notifications. These alerts apply only to stat panels in Quiet Dawn mode; Fixed opacity and Vanilla do not use them. The health / blood hold duration also controls these healing reveals in Quiet Dawn mode; 0 disables them. Small stamina recovery does not trigger a reveal.

## Manual setting reference

All entries below belong under `[Settings]`. Defaults apply to a fresh install without imported preferences. Leave unlisted diagnostic tuning entries at their generated values.

| Setting | INI key | Default | Supported manual values |
| --- | --- | --- | --- |
| Enabled | `enabled` | `1` | 0 = Off, 1 = On |
| Hide enemy health bars | `hideEnemyHealthBars` | `1` | 0 = Off, 1 = On |
| Hide enemy effect icons | `hideEnemyEffectIcons` | `0` | 0 = Off, 1 = On |
| Hide player effect icons | `hidePlayerEffectIcons` | `0` | 0 = Off, 1 = On |
| Hide Crimson Rush effect | `hidePlayerCombatEffects` | `0` | 0 = Off, 1 = On |
| Hide enemy names | `hideEnemyNames` | `1` | 0 = Off, 1 = On |
| Hide enemy difficulty icons | `hideEnemyDifficultyIcons` | `1` | 0 = Off, 1 = On |
| Hide Shredded Touch marks | `hideClawSlashMarks` | `1` | 0 = Off, 1 = On |
| Hide vampire claw hit marks | `hideVampireClawHitMarks` | `1` | 0 = Off, 1 = On |
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
| Show HUD on hold | `manualPeek` | `1` | 0 = Off, 1 = On |
| Hide sprint/haste prompt | `hideSprintPrompt` | `1` | 0 = Off, 1 = On |
| Time of day mode | `mode_WBP_HudTimer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Time of day opacity | `opacity_WBP_HudTimer` | `0` | 0 to 100, step 5 |
| Time of day size | `scale_WBP_HudTimer` | `100` | 25 to 200, step 5 |
| Time of day reveal duration | `timeHoldSeconds` | `4` | 0 to 10, step 0.5 |
| Compass mode | `mode_WBP_Compass` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Compass opacity | `compassOpacity` | `0` | 0 to 100 percent; 5-point steps match the menu |
| Compass size | `scale_WBP_Compass` | `100` | 25 to 200, step 5 |
| Human health and stamina mode | `mode_HumanStats` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Human health and stamina opacity | `opacity_HumanStats` | `0` | 0 to 100, step 5 |
| Human health and stamina size | `scale_HumanStats` | `100` | 25 to 200, step 5 |
| Vampire blood and stamina mode | `mode_VampireStats` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Vampire blood and stamina opacity | `opacity_VampireStats` | `0` | 0 to 100, step 5 |
| Vampire blood and stamina size | `scale_VampireStats` | `100` | 25 to 200, step 5 |
| Quest tracker mode | `mode_WBP_HUD_QuestInfo` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Quest tracker opacity | `opacity_WBP_HUD_QuestInfo` | `0` | 0 to 100, step 5 |
| Quest tracker size | `scale_WBP_HUD_QuestInfo` | `100` | 25 to 200, step 5 |
| Quickslots mode | `mode_WBP_HUD_Quickslots` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Quickslots opacity | `opacity_WBP_HUD_Quickslots` | `0` | 0 to 100, step 5 |
| Quickslots size | `scale_WBP_HUD_Quickslots` | `100` | 25 to 200, step 5 |
| Crosshair mode | `mode_Crosshair` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Crosshair opacity | `opacity_Crosshair` | `0` | 0 to 100, step 5 |
| Crosshair size | `scale_Crosshair` | `100` | 25 to 200, step 5 |
| Quickslot shortcuts mode | `mode_WBP_AA_Quickslots` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Quickslot shortcuts opacity | `opacity_WBP_AA_Quickslots` | `0` | 0 to 100, step 5 |
| Quickslot shortcuts size | `scale_WBP_AA_Quickslots` | `100` | 25 to 200, step 5 |
| Focus activation prompt mode | `mode_WBP_OpenFocusPrompt` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Focus activation prompt opacity | `opacity_WBP_OpenFocusPrompt` | `0` | 0 to 100, step 5 |
| Focus activation prompt size | `scale_WBP_OpenFocusPrompt` | `100` | 25 to 200, step 5 |
| Switch quickslots prompt mode | `mode_WBP_HUD_Quickslots_ChangePrompt` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Switch quickslots prompt opacity | `opacity_WBP_HUD_Quickslots_ChangePrompt` | `0` | 0 to 100, step 5 |
| Switch quickslots prompt size | `scale_WBP_HUD_Quickslots_ChangePrompt` | `100` | 25 to 200, step 5 |
| Controls legend mode | `mode_WBP_ControlsLegend` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Controls legend opacity | `opacity_WBP_ControlsLegend` | `0` | 0 to 100, step 5 |
| Controls legend size | `scale_WBP_ControlsLegend` | `100` | 25 to 200, step 5 |
| Active buffs mode | `mode_WBP_BuffContainer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Active buffs opacity | `opacity_WBP_BuffContainer` | `0` | 0 to 100, step 5 |
| Active buffs size | `scale_WBP_BuffContainer` | `100` | 25 to 200, step 5 |
| Ability cooldowns mode | `mode_WBP_HUD_AbilityCooldownsContainer` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Ability cooldowns opacity | `opacity_WBP_HUD_AbilityCooldownsContainer` | `0` | 0 to 100, step 5 |
| Ability cooldowns size | `scale_WBP_HUD_AbilityCooldownsContainer` | `100` | 25 to 200, step 5 |
| Combat focus mode | `mode_CombatFocusPanel` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Combat focus opacity | `opacity_CombatFocusPanel` | `0` | 0 to 100, step 5 |
| Combat focus size | `scale_CombatFocusPanel` | `100` | 25 to 200, step 5 |
| Focus charge mode | `mode_WBP_HUD_FocusCharge_Bar` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Focus charge opacity | `opacity_WBP_HUD_FocusCharge_Bar` | `0` | 0 to 100, step 5 |
| Focus charge size | `scale_WBP_HUD_FocusCharge_Bar` | `100` | 25 to 200, step 5 |
| Special attack cooldown mode | `mode_WBP_HUD_SpecialAttackCooldown` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Special attack cooldown opacity | `opacity_WBP_HUD_SpecialAttackCooldown` | `0` | 0 to 100, step 5 |
| Special attack cooldown size | `scale_WBP_HUD_SpecialAttackCooldown` | `100` | 25 to 200, step 5 |
| Experience bar mode | `mode_XPBar` | `1` | 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed opacity |
| Experience bar opacity | `opacity_XPBar` | `0` | 0 to 100, step 5 |
| Experience bar size | `scale_XPBar` | `100` | 25 to 200, step 5 |
| Show quickslots after switching | `switchRevealSeconds` | `3` | 0 to 10, step 0.5 |
| Logging | `debugLogging` | `0` | 0 = Off, 1 = On |

Each `mode_<panel>` accepts 0 = Vanilla, 1 = Quiet Dawn, or 2 = Fixed opacity. The saved opacity percentage is used only in Fixed opacity mode; 0% hides the panel. Size remains independent. Timers accept 0 to 10 seconds in 0.5-second steps and apply only to Quiet Dawn reveals. Opacity and threshold percentages use a 0 to 100 scale. Panel sizes accept 25 to 200 in 5-point steps; combat cue size accepts 10 to 200 in 10-point steps.

If a value is malformed, duplicated, missing, or outside the supported range, the settings loader reports it in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Correct the existing line or restore your backup, then restart and load a save.

## Live Apply

Mod Setting Menu 1.0.6 or later is required. Its callback bridge also requires `HookProcessConsoleExec = 1` in `UE4SS-settings.ini`. Manage that loader setting through your Vortex loader configuration; this archive contains no replacement global UE4SS INI.

Settings are prepared when the game starts and are available from the main menu before the first save. Press **Apply** to save and update the active game. Changes made while loading are retained for the next valid player. Restore and Discard leave saved settings unchanged; Reset takes effect after Apply.

Only affected panels, resource reveals, combat cues, enemy visuals or prompts are queued. Repeated size changes use the original scale and pivot; returning to 100% restores them. Widget caches and native event bindings remain in place for ordinary changes.
