# Settings

Use Mod Setting Menu 1.0.6 or later and press Apply to save. Preferences live in `QuietDawnHUD/settings.ini`, under `[Settings]`. The menu has 105 controls in 21 categories. Hidden controls retain their saved values.

Mode values are 0 Vanilla, 1 Quiet Dawn, 2 Fixed Opacity and 3 Always Hidden. Opacity uses percentages. Scale uses percentages of original size. Quiet Dawn peek inclusion is controlled by `showHUD_*` (default 1); Fixed Opacity peek opt-in by `fixedPeek_*` (default 0). The four special panels have no peek inclusion control. Player effect-icon hiding overrides the buff panel without replacing its saved preferences.

Show HUD (`manualPeek`) is 0 Off, 1 Controls Legend or 2 Focus mode. Focus holds the included panels visible, then uses `manualPeekSeconds` after exit. Resource thresholds and contextual reveals are independent of peek inclusion. Fade duration sliders allow 0–2 seconds in 0.05 steps; valid previously saved durations are preserved.

## Menu keys

| Category | Control | Key | Default | Values |
| --- | --- | --- | --- | --- |
| General | Master Toggle | `enabled` | 1 | 0, 1 — OFF, ON |
| General | Fade elements in and out | `fadeTransitions` | 0 | 0, 1 — Disabled, Enabled |
| General | Fade in duration | `fadeInSeconds` | 0.35 | 0–2 (step 0.05) |
| General | Fade out duration | `fadeOutSeconds` | 1.30 | 0–2 (step 0.05) |
| Player status: Active buffs | Player Effect Icons | `hidePlayerEffectIcons` | 0 | 0, 1 — Show, Hide |
| Player status: Active buffs | Mode | `mode_WBP_BuffContainer` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Player status: Active buffs | Opacity | `opacity_WBP_BuffContainer` | 0 | 0–100 (step 5) |
| Player status: Active buffs | Size | `scale_WBP_BuffContainer` | 100 | 25–200 (step 5) |
| Player status: Active buffs | HUD Peek Behaviour | `showHUD_WBP_BuffContainer` | 1 | 0, 1 — Exclude, Include |
| Player status: Active buffs | HUD Peek Behaviour | `fixedPeek_WBP_BuffContainer` | 0 | 0, 1 — Don't change, Raise opacity |
| Player status: Combat effects | Hide Crimson Rush effect | `hidePlayerCombatEffects` | 0 | 0, 1 — Off, On |
| Player status: Experience | Mode | `mode_XPBar` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Player status: Experience | Opacity | `opacity_XPBar` | 0 | 0–100 (step 5) |
| Player status: Experience | Size | `scale_XPBar` | 100 | 25–200 (step 5) |
| Player status: Experience | HUD Peek Behaviour | `showHUD_XPBar` | 1 | 0, 1 — Exclude, Include |
| Player status: Experience | HUD Peek Behaviour | `fixedPeek_XPBar` | 0 | 0, 1 — Don't change, Raise opacity |
| Player status: Health and stamina | Human Mode | `mode_HumanStats` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Player status: Health and stamina | Opacity | `opacity_HumanStats` | 0 | 0–100 (step 5) |
| Player status: Health and stamina | Size | `scale_HumanStats` | 100 | 25–200 (step 5) |
| Player status: Health and stamina | HUD Peek Behaviour | `showHUD_HumanStats` | 1 | 0, 1 — Exclude, Include |
| Player status: Health and stamina | HUD Peek Behaviour | `fixedPeek_HumanStats` | 0 | 0, 1 — Don't change, Raise opacity |
| Player status: Health and stamina | Vampire Mode | `mode_VampireStats` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Player status: Health and stamina | Opacity | `opacity_VampireStats` | 0 | 0–100 (step 5) |
| Player status: Health and stamina | Size | `scale_VampireStats` | 100 | 25–200 (step 5) |
| Player status: Health and stamina | HUD Peek Behaviour | `showHUD_VampireStats` | 1 | 0, 1 — Exclude, Include |
| Player status: Health and stamina | HUD Peek Behaviour | `fixedPeek_VampireStats` | 0 | 0, 1 — Don't change, Raise opacity |
| Player status: Health and stamina | Keep health visible below | `healthThreshold` | 50 | 0–100 (step 5) |
| Player status: Health and stamina | Health / blood hold duration | `healthHoldSeconds` | 4 | 0–10 (step 0.5) |
| Player status: Health and stamina | Keep stamina visible below | `staminaThreshold` | 20 | 0–100 (step 5) |
| Player status: Health and stamina | Stamina hold duration | `staminaHoldSeconds` | 1.5 | 0–10 (step 0.5) |
| Combat: Ability cooldowns | Mode | `mode_WBP_HUD_AbilityCooldownsContainer` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Ability cooldowns | Opacity | `opacity_WBP_HUD_AbilityCooldownsContainer` | 0 | 0–100 (step 5) |
| Combat: Ability cooldowns | Size | `scale_WBP_HUD_AbilityCooldownsContainer` | 100 | 25–200 (step 5) |
| Combat: Ability cooldowns | HUD Peek Behaviour | `showHUD_WBP_HUD_AbilityCooldownsContainer` | 1 | 0, 1 — Exclude, Include |
| Combat: Ability cooldowns | HUD Peek Behaviour | `fixedPeek_WBP_HUD_AbilityCooldownsContainer` | 0 | 0, 1 — Don't change, Raise opacity |
| Combat: Crosshair | Mode | `mode_Crosshair` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Crosshair | Opacity | `opacity_Crosshair` | 0 | 0–100 (step 5) |
| Combat: Crosshair | Size | `scale_Crosshair` | 100 | 25–200 (step 5) |
| Combat: Crosshair | HUD Peek Behaviour | `showHUD_Crosshair` | 1 | 0, 1 — Exclude, Include |
| Combat: Crosshair | HUD Peek Behaviour | `fixedPeek_Crosshair` | 0 | 0, 1 — Don't change, Raise opacity |
| Combat: Enemies | Enemy Health Bars | `hideEnemyHealthBars` | 1 | 0, 1 — Show, Hide |
| Combat: Enemies | Enemy Names | `hideEnemyNames` | 1 | 0, 1 — Show, Hide |
| Combat: Enemies | Enemy Difficulty Icons | `hideEnemyDifficultyIcons` | 1 | 0, 1 — Show, Hide |
| Combat: Enemies | Enemy Effect Icons | `hideEnemyEffectIcons` | 0 | 0, 1 — Show, Hide |
| Combat: Enemies | Hide Shredded Touch marks | `hideClawSlashMarks` | 1 | 0, 1 — Show, Hide |
| Combat: Enemies | Hide vampire claw hit marks | `hideVampireClawHitMarks` | 1 | 0, 1 — Off, On |
| Combat: Toggle Active Abilities prompt | Mode | `mode_WBP_OpenFocusPrompt` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Toggle Active Abilities prompt | Opacity | `opacity_WBP_OpenFocusPrompt` | 0 | 0–100 (step 5) |
| Combat: Toggle Active Abilities prompt | Size | `scale_WBP_OpenFocusPrompt` | 100 | 25–200 (step 5) |
| Combat: Activation Charges | Mode | `mode_WBP_HUD_FocusCharge_Bar` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Activation Charges | Opacity | `opacity_WBP_HUD_FocusCharge_Bar` | 0 | 0–100 (step 5) |
| Combat: Activation Charges | Size | `scale_WBP_HUD_FocusCharge_Bar` | 100 | 25–200 (step 5) |
| Combat: Activation Charges | HUD Peek Behaviour | `showHUD_WBP_HUD_FocusCharge_Bar` | 1 | 0, 1 — Exclude, Include |
| Combat: Activation Charges | HUD Peek Behaviour | `fixedPeek_WBP_HUD_FocusCharge_Bar` | 0 | 0, 1 — Don't change, Raise opacity |
| Combat: Ability Wheel | Mode | `mode_CombatFocusPanel` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Ability Wheel | Opacity | `opacity_CombatFocusPanel` | 0 | 0–100 (step 5) |
| Combat: Ability Wheel | Size | `scale_CombatFocusPanel` | 100 | 25–200 (step 5) |
| Combat: Indicators | Size | `combatCueSize` | 100 | 10–200 (step 10) |
| Combat: Indicators | Enemy Red dot/diamond | `showEnemyMarker` | 0 | 0, 1 — Hide, Show |
| Combat: Indicators | Lock icon | `showLockIcon` | 0 | 0, 1 — Hide, Show |
| Combat: Indicators | Directional Attack Indicators | `showDirectionalParry` | 0 | 0, 1 — Hide, Show |
| Combat: Indicators | Perfect Riposte Indicator | `showCounterattackDirection` | 0 | 0, 1 — Hide, Show |
| Combat: Indicators | Unblockable Warning | `showUnblockableWarning` | 0 | 0, 1 — Hide, Show |
| Combat: Quickslots | Quickslots Consumables | `mode_WBP_HUD_Quickslots` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Quickslots | Opacity | `opacity_WBP_HUD_Quickslots` | 0 | 0–100 (step 5) |
| Combat: Quickslots | Size | `scale_WBP_HUD_Quickslots` | 100 | 25–200 (step 5) |
| Combat: Quickslots | HUD Peek Behaviour | `showHUD_WBP_HUD_Quickslots` | 1 | 0, 1 — Exclude, Include |
| Combat: Quickslots | HUD Peek Behaviour | `fixedPeek_WBP_HUD_Quickslots` | 0 | 0, 1 — Don't change, Raise opacity |
| Combat: Quickslots | Quickslots Abilities | `mode_WBP_AA_Quickslots` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Quickslots | Opacity | `opacity_WBP_AA_Quickslots` | 0 | 0–100 (step 5) |
| Combat: Quickslots | Size | `scale_WBP_AA_Quickslots` | 100 | 25–200 (step 5) |
| Combat: Quickslots | HUD Peek Behaviour | `showHUD_WBP_AA_Quickslots` | 1 | 0, 1 — Exclude, Include |
| Combat: Quickslots | HUD Peek Behaviour | `fixedPeek_WBP_AA_Quickslots` | 0 | 0, 1 — Don't change, Raise opacity |
| Combat: Quickslots | Switch Quicklots prompt | `mode_WBP_HUD_Quickslots_ChangePrompt` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Quickslots | Opacity | `opacity_WBP_HUD_Quickslots_ChangePrompt` | 0 | 0–100 (step 5) |
| Combat: Quickslots | Size | `scale_WBP_HUD_Quickslots_ChangePrompt` | 100 | 25–200 (step 5) |
| Combat: Quickslots | Keep on screen for | `switchRevealSeconds` | 3 | 0–10 (step 0.5) |
| Combat: Weapon Arts cooldown | Mode | `mode_WBP_HUD_SpecialAttackCooldown` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Combat: Weapon Arts cooldown | Opacity | `opacity_WBP_HUD_SpecialAttackCooldown` | 0 | 0–100 (step 5) |
| Combat: Weapon Arts cooldown | Size | `scale_WBP_HUD_SpecialAttackCooldown` | 100 | 25–200 (step 5) |
| Exploration: Compass | Mode | `mode_WBP_Compass` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Exploration: Compass | Opacity | `compassOpacity` | 0 | 0–100 (step 5) |
| Exploration: Compass | Size | `scale_WBP_Compass` | 100 | 25–200 (step 5) |
| Exploration: Compass | HUD Peek Behaviour | `showHUD_WBP_Compass` | 1 | 0, 1 — Exclude, Include |
| Exploration: Compass | HUD Peek Behaviour | `fixedPeek_WBP_Compass` | 0 | 0, 1 — Don't change, Raise opacity |
| Exploration: Quest tracker | Mode | `mode_WBP_HUD_QuestInfo` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Exploration: Quest tracker | Opacity | `opacity_WBP_HUD_QuestInfo` | 0 | 0–100 (step 5) |
| Exploration: Quest tracker | Size | `scale_WBP_HUD_QuestInfo` | 100 | 25–200 (step 5) |
| Exploration: Quest tracker | HUD Peek Behaviour | `showHUD_WBP_HUD_QuestInfo` | 1 | 0, 1 — Exclude, Include |
| Exploration: Quest tracker | HUD Peek Behaviour | `fixedPeek_WBP_HUD_QuestInfo` | 0 | 0, 1 — Don't change, Raise opacity |
| Exploration: Time of day | Mode | `mode_WBP_HudTimer` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Exploration: Time of day | Opacity | `opacity_WBP_HudTimer` | 0 | 0–100 (step 5) |
| Exploration: Time of day | Size | `scale_WBP_HudTimer` | 100 | 25–200 (step 5) |
| Exploration: Time of day | HUD Peek Behaviour | `showHUD_WBP_HudTimer` | 1 | 0, 1 — Exclude, Include |
| Exploration: Time of day | HUD Peek Behaviour | `fixedPeek_WBP_HudTimer` | 0 | 0, 1 — Don't change, Raise opacity |
| Exploration: Time of day | Time of day reveal duration | `timeHoldSeconds` | 4 | 0–10 (step 0.5) |
| Controls: Action prompts | Sprint/Haste prompt | `hideSprintPrompt` | 1 | 0, 1 — Show, Hide |
| Controls: Controls legend | Mode | `mode_WBP_ControlsLegend` | 1 | 0, 1, 2, 3 — Vanilla, Quiet Dawn, Fixed Opacity, Always Hidden |
| Controls: Controls legend | Opacity | `opacity_WBP_ControlsLegend` | 0 | 0–100 (step 5) |
| Controls: Controls legend | Size | `scale_WBP_ControlsLegend` | 100 | 25–200 (step 5) |
| Controls: Controls legend | HUD Peek Behaviour | `showHUD_WBP_ControlsLegend` | 1 | 0, 1 — Exclude, Include |
| Controls: Controls legend | HUD Peek Behaviour | `fixedPeek_WBP_ControlsLegend` | 0 | 0, 1 — Don't change, Raise opacity |
| Controls: HUD peek | Show HUD trigger | `manualPeek` | 1 | 0, 1, 2 — Off, Controls Legend, Focus Mode |
| Controls: HUD peek | Show HUD duration | `manualPeekSeconds` | 3 | 0–10 (step 0.5) |
| Diagnostics | Logging | `logLevel` | 2 | 0, 1, 2, 3, 4 — Off, Error, Warning, Info, Debug |

## Logging and recovery

`logLevel` is 0 Off, 1 Error, 2 Warning (default), 3 Info or 4 Debug. Each includes more severe messages. `debugLogging` is derived internally; old saved On becomes Debug and old Off becomes Warning. Debug adds aggregated counts and timings to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. INI-only controls are `SummarySeconds` (10, range 5–120), `SlowCallbackMs` (2, range 0.1–1000) and `MaxEventsPerSecond` (6, range 1–20).

Startup adds missing keys with recovery backups, preserves comments and unrelated sections, and rejects malformed, duplicate or invalid values before upgrading. An existing backup is never overwritten. Older Fixed Opacity 0% values migrate once to Always Hidden with a `.before-always-hidden` backup; choosing Fixed 0% afterwards is respected. The separate vampire claw hit setting initially inherits the saved Shredded Touch choice, then remains independent.

Back up `settings.ini` before manual editing. To recover, close the game and copy the desired backup over `settings.ini`, or repair the reported invalid assignment. A full file replacement replaces every preference in that file; it is not an automatic merge. To start from defaults, keep a backup and remove the generated settings file before starting the game. Legacy Lua and personal diagnostic INIs are first-use imports only. Apply commits staged menu changes; Restore and Discard retain the saved file, and Reset requires Apply. Reopen the menu to verify the saved choices.
