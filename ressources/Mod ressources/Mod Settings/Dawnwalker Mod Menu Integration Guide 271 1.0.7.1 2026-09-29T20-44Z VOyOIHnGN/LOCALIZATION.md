# Translations

The menu supports English (en), French (fr), Italian (it), German (de), Spanish
from Spain (es), Latin American Spanish (es-419), Czech (cs), Hungarian (hu),
Japanese (ja), Korean (ko), Polish (pl), Brazilian Portuguese (pt-br), Simplified
Chinese (zh-hans), Traditional Chinese (zh-hant) and Turkish (tr).

## Translate your mod's integration

Keep the existing fields as the fallback text. Use English for those fields when
possible. Add translated fields with a lowercase language code after a dot in
the same section. For example:

```ini
[Mod]
Id = MyMod
Name = My Mod
Name.fr = Mon mod
Description = Change this mod's options.
Description.fr = Modifiez les options de ce mod.

[Setting.Enabled]
Id = enabled
Type = toggle
Label = Enabled
Label.fr = Activé
Description = Turn this feature on or off.
Description.fr = Activez ou désactivez cette fonction.
Group = Settings
Group.fr = Paramètres
PresetValues = 0|1
PresetLabels = Off|On
PresetLabels.fr = Désactivé|Activé
Default = 1
ConfigFile = config.ini
ConfigKey = Enabled
```

This example extends a working numeric integration; the existing config.ini
must contain Enabled = 1. Read MODDER-GUIDE.md for the full integration contract.

Supported localized fields:

- In [Mod]: Name and Description.
- In each [Setting] or [Setting.*]: Label, Description, Group, PresetLabels,
  Prefix and Suffix. Prefix and Suffix apply to sliders.

Do not translate IDs, section headers, ConfigFile, ConfigKey, ConfigSection,
Type, numeric choices, limits, steps or defaults. Translations change display
text only. Keep PresetLabels translations in the original value order and with
the same number of labels. Invalid label lists fall back to the original labels.
Keep any desired spacing in slider units in mind; values in INI fields are trimmed.

Use UTF-8. Missing or empty translations keep the fallback field. An optional
.en field supplies English fallback when the original field is in another
language. More specific language tags override general ones: fr-CA uses .en,
then .fr, then .fr-ca. Chinese regional tags map to zh-hans or zh-hant; Brazilian
Portuguese uses pt-br, and Latin American Spanish uses es-419. Untranslated text
is not automatically translated. Restart the game after changes.

## Translate the menu itself

Menu catalogs are plain UTF-8 files in DawnwalkerModMenu/Localization. Copy en.ini
as a template. The left side is the original menu text; translate only the right
side. Keep placeholders such as {count}, {hint}, {percent} and {detail} exactly
as written. Empty entries or entries with mismatched placeholders fall back.
A malformed file is ignored and reported in UE4SS.log. No Lua code is executed
from translation files. Do not put newlines inside an entry.

Language = auto in DawnwalkerModMenu/config.ini follows the game language.
A language code overrides only this menu. It does not change the game's settings.
Catalogs are cached. The main-menu label updates after a language change is
applied in vanilla settings. Close and reopen Mod Settings after an external
language change. Fully restart after editing a catalog or the menu override.

Please check long text, button labels, accents and Asian characters in game.
The menu uses the game's fonts. Technical engine/config error details may remain
in English even when the surrounding message is translated.
