# Quiet Dawn - Configurable HUD

Keep the world in view, with health and stamina returning when needed. For **The Blood of Dawnwalker**.

## Player HUD

Choose a mode for each of 17 panels:

- **Vanilla:** the game controls visibility and opacity.
- **Quiet Dawn:** hide the panel between relevant alerts or reveals.
- **Fixed Opacity:** choose 0–100% opacity in 5% steps, within the game's visibility rules.
- **Always Hidden:** keep the panel hidden, including during HUD peek and contextual reveals.

Each panel also has a 25–200% size setting in 5% steps. Size and opacity are independent. Returning to 100% restores the original size and pivot. Large panels can overlap nearby elements.

**Show HUD** defaults to the Controls Legend gesture (Menu on Xbox, Options on PlayStation, or L on keyboard with the default bindings). It reveals included panels for 3 seconds. Choose **Focus mode** to reveal them throughout Focus and start the same duration when Focus ends. Choose Off to disable manual reveals.

Thirteen panels have **HUD Peek Behaviour** controls. Quiet Dawn panels default to Include and can be excluded individually. Fixed Opacity panels default to Don't change; Raise opacity lets a peek bring them to 100%. Vanilla and Always Hidden ignore peeks. The combat-focus wheel, Focus activation hint, quickslot switch hint and special-attack panel keep their own rules. Resource alerts remain independent of peek inclusion.

Optional **Fade elements in and out** synchronizes panel transitions, including startup and interrupted transitions. It defaults to Disabled, with 0.35 seconds in and 1.30 seconds out. Both durations range from 0 to 2 seconds in 0.05-second steps; zero changes opacity immediately. Pausing suspends fades while settings and lifecycle changes can still be processed.

## Alerts and contextual reveals

- **Health/blood:** reveal the current form's stat panel after damage or healing of at least 0.2% of bar capacity, and for 4 seconds after the last qualifying change. Smaller healing reveals once upon reaching full, rearmed after a deficit of at least 0.2%. Low health remains visible strictly below 50% by default.
- **Stamina:** reveal after stamina use and for 1.5 seconds after the last drop. Low stamina remains visible strictly below 20% by default.
- **Quickslots:** reveal item and ability quickslots for 3 seconds after switching.
- **Time:** reveal for 4 seconds after an activity advances time, including shrine restoration. If the activity hides the HUD, the reveal waits for its return.
- **Special attack:** reveal its panel during the cooldown.

These automatic reveals apply to Quiet Dawn mode. Timed reveals range from 0 to 10 seconds in 0.5-second steps; zero disables that timed reveal. Low-resource thresholds remain independent. Vampire health uses blood; human health uses HP. Combat, weapon drawing and lock-on do not reveal the general HUD. Focus reveals it only when selected as Show HUD's trigger.

## Enemy information and combat effects

Enemy health bars, boss names and difficulty icons are hidden by default with independent settings. Showing health bars restores their end caps and boss phase indicators. Enemy stamina keeps game behavior.

Five independent indicator settings control counterattack directions, unblockable warnings, directional parry cues, the enemy dot/diamond and the lock icon. All default to Off. Enabled directions and unblockable warnings replace the marker during the attack; afterward, the marker returns. Hidden warnings leave the enabled lock icon or enemy dot visible without briefly flashing the warning. When marker and lock are enabled, a hard-locked target shows the padlock. The dot/diamond setting also controls the secondary-enemy attack dot beside its health bar. Combat cue size ranges from 10% to 200% in 10% steps.

**Hide Shredded Touch marks** and **Hide vampire claw hit marks** are separate, default-On settings under Combat: Enemies. They hide the red Shredded Touch slash effects (including the sword variant) and ordinary vampire claw hit marks respectively. Other blood spray, swing trails, damage and bleeding retain game behavior.

**Hide Crimson Rush effect**, under Player status: Combat effects, hides the bright red arm effect in either form. It defaults to Off. Buff strength, duration, audio and other effects are unchanged.

**Hide enemy effect icons** and **Hide player effect icons** default to Off. They hide status icons and their timers. Player icon hiding overrides every peek choice while preserving the saved Active buffs mode, opacity and size; turning it Off resumes those preferences.

## Prompts

Sprint/Haste prompts stay hidden while running in either form, across display languages. Turn off **Hide sprint/haste prompt** under Controls: Action prompts to restore them. Other action prompts retain game behavior. HUD peek keeps running prompts hidden.

The Focus Toggle abilities hint and quickslot switch hint are hidden by default. Select Vanilla or a positive Fixed Opacity to restore them. Ability switching, interaction prompts, dialogue, subtitles, notifications and menus retain game behavior.

## Requirements

- [Mod Setting Menu 1.0.6 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271), with `HookProcessConsoleExec = 1` in your UE4SS loader configuration for live Apply.
- [UE4SS for Dawnwalker by Vercadi](https://www.nexusmods.com/thebloodofdawnwalker/mods/18) **1.3 (RC6) or later**, exposing the game-thread delayed-action, cancellation, frame-count and game-time APIs, with Blueprint script hooks or support for the bundled native HUD adapter. Native support is checked against the APIs and layouts used.

## Installation

- Vortex: Install `Quiet-Dawn-Configurable-HUD.zip` through Vortex, enable it and deploy.
- Manual: Copy the archive's `Data/QuietDawnHUD` folder into `<game folder>/Dawnwalker/Binaries/Win64/ue4ss/Mods`, preserving the folder structure.

## Settings

Open Mod Settings and press **Apply** to save and update gameplay. The menu has 105 controls across 21 categories, ending with Logging. Conditional controls appear only when relevant. Reset takes effect after Apply; Restore and Discard leave saved settings unchanged.

Preferences are stored in `QuietDawnHUD/settings.ini`, created at startup. Back it up before manual editing. Do not edit `mod_settings.ini` or the default Lua files to change preferences. Startup upgrades preserve existing preferences, comments and unrelated sections and keep recovery copies. Older Fixed 0% settings migrate once to Always Hidden; later deliberate Fixed 0% choices remain Fixed. Legacy INI/Lua files are import-only. See [SETTINGS.md](SETTINGS.md) for every menu key and recovery details.

## Diagnostics

Logging is the final and only diagnostic menu control: **Off / Error / Warning / Info / Debug**. Warning is the default. Each level includes more severe messages. Old Logging On becomes Debug; old Off becomes Warning. Debug enables event tracing and aggregate counts/timings. Logs are in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Timing and rate controls remain INI-only.

HUD work is event-driven. Temporary fade, reveal and recovery work stops when settled; there is no permanent panel audit or resource sampler. Missing optional routes leave unrelated features available. Diagnostic timings are observations of callbacks, not game frame-time measurements.

## Credits and license

Created by **oOCamilleOo**. This version integrates HUD fades, Focus peek, Always Hidden, per-panel peek choices, logging levels, descriptions and menu artwork from [JdotCarver's Quiet Dawn fork](https://github.com/JdotCarver/Dawnwalker-Quiet-Dawn-Configurable-HUD/tree/b361d394c8c255b1dfa27aecf498d017098e388a), with integration fixes and the current upstream combat controls retained. Fork reference: `b361d394c8c255b1dfa27aecf498d017098e388a`.

MIT. Includes the pinned [ue4ss-common Lua helpers](https://github.com/my-mods/ue4ss-common); no separate library installation is required. See LICENSES for their notice. Thanks to the UE4SS authors for the runtime and hook APIs, and BryanHudson (Free Combat Camera) for reporting the secondary-enemy attack-dot issue. No game assets or UE4SS runtime DLL are included. Native build instructions are in [native/BUILD.md](native/BUILD.md).
