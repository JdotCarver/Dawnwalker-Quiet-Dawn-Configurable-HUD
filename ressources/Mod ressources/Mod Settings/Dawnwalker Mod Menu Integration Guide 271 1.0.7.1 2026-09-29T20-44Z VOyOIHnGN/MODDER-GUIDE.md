# Dawnwalker Mod Menu 1.0.7.1 - Integration guide

Add a mod_settings.ini file to your mod's folder under UE4SS Mods.
The menu reads this file and shows the settings you declare.
On Apply, it writes numeric values to your existing config.
Your mod must read that config and apply the values to gameplay.
An optional Apply callback is available in 1.0.6; your mod still supplies the
gameplay code. Existing file-only integrations need no changes.

## Limits and page loading (1.0.7+)

The list allows 1,000 entries, with integrated mods taking priority over
detected-only entries. Each integration can declare 256 setting sections;
there is no separate aggregate settings-row limit. Keep each manifest within
256 KiB. Invalid definitions affect their own page; duplicates and invalid
metadata are skipped, and overflow is reported.

The menu caches discovery and loads full definitions when a page first opens.
Each mod has its own page; visited pages stay available until Mod Settings closes.
Large lists and many opened pages use more memory. Apply saves values normally;
TestOnly values last until game restart. Restart after changing an integration
file. The settings format and Apply callback API are unchanged.

## A small example

Put these files together in ue4ss/Mods/MyMod/. Change MyMod, the display name,
author and descriptions for your mod. Use a unique Mod Id.

IDs can use letters; they do not need to be numbers. This example uses
`Id = MyMod` for the mod and `Id = enabled`, `Id = mode` and `Id = amount`
for its settings. Letters, numbers and underscores are a simple naming choice,
such as `MyCoolMod` or `damage_multiplier`.

The mod Id must be unique across installed mods. Each setting Id only needs to
be unique within your mod. IDs are case-sensitive and must be 1-128 UTF-8 bytes.
Name is the display name players see; it does not have to be unique.
The example only adds a settings page; your mod supplies the gameplay code.

mod_settings.ini:

```ini
[Mod]
Id = MyMod
Name = My Mod
Author = Your name
Version = 1.0.0
Description = Settings for My Mod.

[Setting.enabled]
Id = enabled
Type = toggle
Label = Enabled
Description = Turn the mod on or off.
Group = General
PresetValues = 0|1
PresetLabels = Off|On
Default = 1
ConfigFile = config.ini
ConfigSection = General
ConfigKey = Enabled

[Setting.mode]
Id = mode
VisibleWhen = enabled
VisibleValues = 1
Type = picker
Label = Mode
Description = Choose how strong the effect should be.
Group = General
PresetValues = 1|2|3
PresetLabels = Low|Normal|High
Default = 2
ConfigFile = config.ini
ConfigSection = General
ConfigKey = Mode

[Category.Tuning]
VisibleWhen = enabled
VisibleValues = 1

[Setting.amount]
Id = amount
VisibleWhen = mode
VisibleValues = 2|3
Type = integer
Label = Amount
Description = Set the amount used by the mod.
Group = Tuning
Minimum = 1
Maximum = 100
Step = 1
Decimals = 0
Default = 10
ConfigFile = config.ini
ConfigSection = General
ConfigKey = Amount
```

config.ini:

```ini
[General]
Enabled = 1
Mode = 2
Amount = 10
```

Ship the config with your mod or create it before the player opens its page.
Read Enabled as 0 or 1, Mode as 1, 2 or 3, and Amount as a number from 1 to 100.
If your mod reads config only at startup, tell players to restart after Apply.
Do not overwrite saved values with defaults each time the mod starts.

## Rules that matter

- Names are case-sensitive. Use [Mod] and distinct [Setting.name] sections.
  A single [Setting] section also works. Mod Id and Name are required.
  Give each setting a unique Id. The section suffix does not set its Id.
- ConfigFile is relative to the manifest. All settings in one mod must use
  the same file. Absolute paths, parent traversal and the manifest itself
  are not valid targets. The file must exist and be at most 1 MiB.
- ConfigKey must already exist exactly once in ConfigSection. Without
  ConfigSection, it must be unique across the whole file. Do not target the
  same key from two settings. Only numeric key=value assignments are supported.
- The current value must be inside the declared range or choice list.
  Default is used by Reset; it does not replace an existing value on opening.
- Toggle needs exactly two numeric PresetValues. Use 0|1 for Off|On, not
  true|false. Picker (or preset) accepts 2-64 distinct numeric values with the
  same number of nonempty PresetLabels, separated by |. Default must match a value.
- Group adds a heading. Section and Category are aliases for Group.
  They do not replace ConfigSection.
- Do not set TestOnly in a released integration. It saves only for the current
  session and does not write config.

## Numeric controls

The integer example is a whole-number slider. Other numeric types use the same
Minimum, Maximum, Step, Decimals, Default and config fields:

| Type | Use |
| --- | --- |
| integer | Whole-number bounds, step and default. |
| slider | Decimal slider; Decimals defaults to 2. |
| percent | Numeric slider; adds % unless Suffix is supplied. No value conversion. |
| stepped | Numeric slider with your Step. |

Decimals defaults to 0 for integer, percent and stepped. Set it explicitly when
using fractions. Prefix and Suffix change display text only.
Minimum must be below Maximum. Bounds and Default must be finite and within
+/-1 billion; Default must be inside the range. Step must be at least 0.000001
and no larger than the range. Decimals must be a whole number from 0 to 6.
An off-step default is allowed. Dragging snaps from Minimum; Left/Right steps
from the current value. Both range endpoints are reachable.

## Mod information

Author, Version and Description are optional fields in [Mod]. They appear in
All Mods. A setting's Description appears when that setting is selected.

Optional AuthorURL links the author name; ModURL links the version directly to
your mod page. Use your own HTTP or HTTPS links, or leave these fields out.

For a logo, add LogoFile with a relative PNG/JPEG path, such as assets/logo.png.
The file must be at most 8 MiB and 2048 pixels per dimension. The combined logo
limit is 8 million pixels per open menu. An optional LogoAsset must point to a
cooked Texture2D under /Game/ and takes precedence over LogoFile.

## Check your integration

Install UE4SS, one Dawnwalker Mod Menu version and your mod. Fully restart the
game after adding or editing the manifest; the mod list is cached for the run.
Open Mod Settings from Main Menu or Pause and check your page. Compatible Mods
is the default filter; All Mods remains available through the footer filter.

Change each setting and press Apply. Confirm the declared config values change,
unrelated text stays intact, and your mod uses the saved values. Reopen the page,
then restart and check again. Try Restore and both reset actions too.

If Apply reports an external config change, cancel and reopen the page. If it
reports a failed replacement, preserve any .dmm-toggle.tmp/.dmm-toggle.bak files
until you have checked the original config and backup. Config replacement is not
power-loss atomic. Keep a backup while testing your integration.

## Translation support

See LOCALIZATION.md for translated metadata, setting labels and menu catalogs.
Existing manifests remain compatible without changes.

## Linked presets

A picker can set other pickers in the same mod. Add PresetTargets with their Id values separated by |, and CustomValue with a value declared in the preset picker (for example 0 labelled Custom). Every non-custom preset value must exist in every target picker. The default can be a preset value such as 50. Targets must be ordinary pickers, cannot be shared by another preset, and still use their own config keys in the same config file.

Selecting a preset updates all target rows before Apply. Editing a target shows Custom when the values differ. Apply saves the complete selection together; Restore discards pending changes. Keep CustomValue distinct from the target values.


## Conditional visibility (1.0.5+)

Add `VisibleWhen = enabled` and `VisibleValues = 1` to a setting to show it only
when the setting with Id `enabled` has pending value 1. Use the numeric values,
not translated labels. A toggle or picker can control visibility; separate
multiple matching values with `|`, such as `2|3`. A setting without a row or
category condition always appears.

To control a whole category, add a `[Category.Tuning]` section with the same two
fields. It applies to every setting whose Group (or Section/Category alias) is
exactly `Tuning`, including separated runs of that group. Use the original group
name; translations do not change the match. The small example above combines
both rules: Enabled controls Tuning, while Mode controls the Amount row.

- A row with both rules appears only when both match. If its controlling setting
  is hidden, the dependent row is hidden too. Empty headings disappear.
- Keep the controlling toggle outside the category it hides. Missing setting IDs,
  invalid values, duplicate category declarations and dependency cycles are rejected.
- Visibility updates immediately while editing, including linked presets, Restore
  and reset. Keyboard/controller navigation skips hidden rows.
- Hiding preserves values. Apply also saves pending edits made before hiding a row;
  Restore discards them. Reset Page resets hidden settings too. Your mod still
  decides whether an option affects gameplay.

Control Gallery 1.0.6 includes these examples and a working Apply callback.
Use Mod Menu 1.0.6 for the complete gallery.


## Apply callback (1.0.6+)

Copy example/Scripts/dmm_api.lua into your own Scripts folder, then register
once in your mod's main.lua. Use the exact, case-sensitive [Mod] Id:

```lua
local API = require("dmm_api")
-- Load your initial config normally. This receives later saved changes.
local ok, unsubscribe = pcall(API.subscribe, "MyMod", function(values, changes)
    local enabled = values.enabled == 1
    local amount = values.amount
    -- Use these values in your mod. Only changed IDs appear in changes.
    if changes.amount then
        print("Amount: " .. changes.amount.old .. " -> " .. amount .. "\n")
    end
end)
if not ok then
    print("[MyMod] Settings callback unavailable: " .. tostring(unsubscribe) .. "\n")
end
```

- The callback runs on the game thread after a successful, changed Apply,
  including Apply in the unsaved-changes popup. Config is saved first. TestOnly
  integrations notify after committing their session values.
- values contains every setting's committed numeric value, indexed by setting
  Id. changes contains only changed IDs, each with old and new numeric values.
  Hidden settings and linked presets are included. These are copies.
- Editing, resetting before Apply, Restore, Discard, unchanged Apply and failed
  saves do not notify. Registration does not replay old changes or load config.
  External config edits are not watched. Load initial config normally.
- Cache values and keep the callback short. Validate gameplay objects before
  using them; defer expensive rebuilds to your mod's appropriate game event.
  Callback errors are logged and cannot undo the completed save.
- One subscriber per Mod Id. Calling subscribe again through the same required
  module replaces its callback. On success, unsubscribe() stops delivery; an old
  unsubscribe handle cannot cancel a newer subscription. Fully restart after
  script reloads; another Lua state cannot take an already registered Id.
- No polling is added. UE4SS uses a reserved command per Id to deliver the event
  to your Lua state; Lua functions are never shared between mods. Leave UE4SS's
  ProcessConsoleExec hook enabled. A visible console window is not required.
  With an older Mod Menu, no notifications arrive; config-file integration still
  works. Handle subscription failure as above if the bridge is unavailable.

The gallery's main.lua shows a complete subscriber. Change values and Apply;
look for [Control Gallery] Applied in UE4SS.log, then verify no notification
appears for Discard or an unchanged Apply.
