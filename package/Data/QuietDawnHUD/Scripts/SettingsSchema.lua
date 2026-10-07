-- SettingsSchema.lua
-- Settings contract shared by the loader and Mod Setting Menu. MIT License.
local directory = assert(debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])'))
local LogLevels = dofile(directory .. 'QuietDawnLogLevels.lua')
local function choices(maximum, step)
    local values = {}
    for value=0,maximum,step do values[#values+1]=value end
    return values
end
local durations = choices(10, 0.5)
local opacities = choices(100, 5)
local panelSizes = {}
for value=25,200,5 do panelSizes[#panelSizes+1]=value end
local cueSizes = {}
for value=10,200,10 do cueSizes[#cueSizes+1]=value end
-- Panel modes: 0 = Vanilla, 1 = Quiet Dawn, 2 = Fixed Opacity, 3 = Always Hidden.
return {
    {key="mode_HumanStats", default=1, values={0,1,2,3}},
    {key="mode_VampireStats", default=1, values={0,1,2,3}},
    {key="mode_WBP_Compass", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_QuestInfo", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_Quickslots", default=1, values={0,1,2,3}},
    {key="mode_Crosshair", default=1, values={0,1,2,3}},
    {key="mode_WBP_AA_Quickslots", default=1, values={0,1,2,3}},
    {key="mode_WBP_OpenFocusPrompt", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_Quickslots_ChangePrompt", default=1, values={0,1,2,3}},
    {key="mode_WBP_ControlsLegend", default=1, values={0,1,2,3}},
    {key="mode_WBP_BuffContainer", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_AbilityCooldownsContainer", default=1, values={0,1,2,3}},
    {key="mode_CombatFocusPanel", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_FocusCharge_Bar", default=1, values={0,1,2,3}},
    {key="mode_WBP_HUD_SpecialAttackCooldown", default=1, values={0,1,2,3}},
    {key="mode_XPBar", default=1, values={0,1,2,3}},
    {key="mode_WBP_HudTimer", default=1, values={0,1,2,3}},

    {key="scale_HumanStats", default=100, values=panelSizes},
    {key="scale_VampireStats", default=100, values=panelSizes},
    {key="scale_WBP_Compass", default=100, values=panelSizes},
    {key="scale_WBP_HUD_QuestInfo", default=100, values=panelSizes},
    {key="scale_WBP_HUD_Quickslots", default=100, values=panelSizes},
    {key="scale_Crosshair", default=100, values=panelSizes},
    {key="scale_WBP_AA_Quickslots", default=100, values=panelSizes},
    {key="scale_WBP_OpenFocusPrompt", default=100, values=panelSizes},
    {key="scale_WBP_HUD_Quickslots_ChangePrompt", default=100, values=panelSizes},
    {key="scale_WBP_ControlsLegend", default=100, values=panelSizes},
    {key="scale_WBP_BuffContainer", default=100, values=panelSizes},
    {key="scale_WBP_HUD_AbilityCooldownsContainer", default=100, values=panelSizes},
    {key="scale_CombatFocusPanel", default=100, values=panelSizes},
    {key="scale_WBP_HUD_FocusCharge_Bar", default=100, values=panelSizes},
    {key="scale_WBP_HUD_SpecialAttackCooldown", default=100, values=panelSizes},
    {key="scale_XPBar", default=100, values=panelSizes},
    {key="scale_WBP_HudTimer", default=100, values=panelSizes},
    {key="hideSprintPrompt", default=1, values={0,1}},
    {key="enabled", default=1, values={0,1}},
    {key="hideEnemyHealthBars", default=1, values={0,1}},
    {key="hideEnemyEffectIcons", default=0, values={0,1}},
    {key="hidePlayerEffectIcons", default=0, values={0,1}},
    {key="hidePlayerCombatEffects", default=0, values={0,1}},
    {key="hideClawSlashMarks", default=1, values={0,1}},
    {key="hideVampireClawHitMarks", default=1, values={0,1}},
    {key="hideEnemyNames", default=1, values={0,1}},
    {key="hideEnemyDifficultyIcons", default=1, values={0,1}},
    {key="showCounterattackDirection", default=0, values={0,1}},
    {key="showUnblockableWarning", default=0, values={0,1}},
    {key="showDirectionalParry", default=0, values={0,1}},
    {key="showEnemyMarker", default=0, values={0,1}},
    {key="showLockIcon", default=0, values={0,1}},
    {key="combatCueSize", default=100, values=cueSizes},
    {key="healthThreshold", default=50, min=0, max=100, integer=false},
    {key="staminaThreshold", default=20, min=0, max=100, integer=false},
    {key="healthHoldSeconds", default=4, values=durations},
    {key="staminaHoldSeconds", default=1.5, values=durations},
    {key="manualPeekSeconds", default=3, values=durations},
    {key="switchRevealSeconds", default=3, values=durations},
    -- HUD peek trigger: 0 off, 1 controls-legend hold, 2 Focus mode.
    -- Widened from {0,1}; both old values keep their exact meaning, so an
    -- existing settings.ini needs no migration.
    {key="manualPeek", default=1, values={0,1,2}},
    -- Every eligible panel remains included by default, preserving existing
    -- Show HUD behavior until the player deliberately excludes it.
    {key="showHUD_HumanStats", default=1, values={0,1}},
    {key="showHUD_VampireStats", default=1, values={0,1}},
    {key="showHUD_WBP_Compass", default=1, values={0,1}},
    {key="showHUD_WBP_HUD_QuestInfo", default=1, values={0,1}},
    {key="showHUD_WBP_HUD_Quickslots", default=1, values={0,1}},
    {key="showHUD_Crosshair", default=1, values={0,1}},
    {key="showHUD_WBP_AA_Quickslots", default=1, values={0,1}},
    {key="showHUD_WBP_ControlsLegend", default=1, values={0,1}},
    {key="showHUD_WBP_BuffContainer", default=1, values={0,1}},
    {key="showHUD_WBP_HUD_AbilityCooldownsContainer", default=1, values={0,1}},
    {key="showHUD_WBP_HUD_FocusCharge_Bar", default=1, values={0,1}},
    {key="showHUD_XPBar", default=1, values={0,1}},
    {key="showHUD_WBP_HudTimer", default=1, values={0,1}},
    -- Fixed panels normally ignore Show HUD. A separate default-off choice
    -- lets the player explicitly raise one to full opacity during a peek
    -- without changing any existing fixed-panel behavior.
    {key="fixedPeek_HumanStats", default=0, values={0,1}},
    {key="fixedPeek_VampireStats", default=0, values={0,1}},
    {key="fixedPeek_WBP_Compass", default=0, values={0,1}},
    {key="fixedPeek_WBP_HUD_QuestInfo", default=0, values={0,1}},
    {key="fixedPeek_WBP_HUD_Quickslots", default=0, values={0,1}},
    {key="fixedPeek_Crosshair", default=0, values={0,1}},
    {key="fixedPeek_WBP_AA_Quickslots", default=0, values={0,1}},
    {key="fixedPeek_WBP_ControlsLegend", default=0, values={0,1}},
    {key="fixedPeek_WBP_BuffContainer", default=0, values={0,1}},
    {key="fixedPeek_WBP_HUD_AbilityCooldownsContainer", default=0, values={0,1}},
    {key="fixedPeek_WBP_HUD_FocusCharge_Bar", default=0, values={0,1}},
    {key="fixedPeek_XPBar", default=0, values={0,1}},
    {key="fixedPeek_WBP_HudTimer", default=0, values={0,1}},
    -- Fading defaults to off so an existing settings.ini keeps its exact
    -- current behaviour; `ensure` simply adds the three missing keys.
    {key="fadeTransitions", default=0, values={0,1}},
    -- A 0.01-step slider emits values such as 1.1300000000000001, which no
    -- discrete grid can match, so these are continuous clamped ranges.
    {key="fadeInSeconds", default=0.35, min=0, max=2, integer=false},
    {key="fadeOutSeconds", default=1.30, min=0, max=2, integer=false},
    {key="compassOpacity", default=0, min=0, max=100, integer=false},
    -- Replaced the former `debugLogging` on/off toggle. See QuietDawnLogLevels.
    {key="logLevel", default=LogLevels.DEFAULT, values=LogLevels.ordered},
    {key="SummarySeconds", default=10, min=5, max=120, integer=false},
    {key="SlowCallbackMs", default=2, min=0.1, max=1000, integer=false},
    {key="MaxEventsPerSecond", default=6, min=1, max=20, integer=false},
    {key="opacity_HumanStats", default=0, values=opacities},
    {key="opacity_VampireStats", default=0, values=opacities},
    {key="opacity_WBP_HUD_QuestInfo", default=0, values=opacities},
    {key="opacity_WBP_HUD_Quickslots", default=0, values=opacities},
    {key="opacity_Crosshair", default=0, values=opacities},
    {key="opacity_WBP_AA_Quickslots", default=0, values=opacities},
    {key="opacity_WBP_OpenFocusPrompt", default=0, values=opacities},
    {key="opacity_WBP_HUD_Quickslots_ChangePrompt", default=0, values=opacities},
    {key="opacity_WBP_ControlsLegend", default=0, values=opacities},
    {key="opacity_WBP_BuffContainer", default=0, values=opacities},
    {key="opacity_WBP_HUD_AbilityCooldownsContainer", default=0, values=opacities},
    {key="opacity_CombatFocusPanel", default=0, values=opacities},
    {key="opacity_WBP_HUD_FocusCharge_Bar", default=0, values=opacities},
    {key="opacity_WBP_HUD_SpecialAttackCooldown", default=0, values=opacities},
    {key="timeHoldSeconds", default=4, values=durations},
    {key="opacity_WBP_HudTimer", default=0, values=opacities},
    {key="opacity_XPBar", default=0, values=opacities},
}
