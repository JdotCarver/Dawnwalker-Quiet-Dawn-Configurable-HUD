-- SettingsModel.lua
-- Shared startup snapshot for gameplay and diagnostics. MIT.
local directory = assert(debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])'))
local Store = dofile(directory .. 'SettingsStore.lua')
local schema = dofile(directory .. 'SettingsSchema.lua')
local Timers = dofile(directory .. 'QuietDawnTimers.lua')
local LogLevels = dofile(directory .. 'QuietDawnLogLevels.lua')
local effectDefaults={hideEnemyEffectIcons=0,hidePlayerEffectIcons=0}
local newestSchema = Timers.compatibleSchema(schema)
-- Each schema below describes one older generation of settings.ini, so the
-- upgrades further down can run in the order the keys were introduced.
--
-- They must stay STRICT SUBSETS of the newest schema. `ensure` adds every key
-- its schema declares but the file lacks, so a schema naming a retired key
-- would write that key back into an already-current file.
local FADE_KEYS = {fadeTransitions=true, fadeInSeconds=true, fadeOutSeconds=true}
local preFadeSchema = {}
for _,row in ipairs(newestSchema) do
    if not FADE_KEYS[row.key] then preFadeSchema[#preFadeSchema+1]=row end
end
local preLogLevelSchema = {}
for _,row in ipairs(preFadeSchema) do
    if row.key~="logLevel" then preLogLevelSchema[#preLogLevelSchema+1]=row end
end
local fullCompatibleSchema = {}
for _,row in ipairs(preLogLevelSchema) do
    if row.key~="hidePlayerCombatEffects" then fullCompatibleSchema[#fullCompatibleSchema+1]=row end
end
local compatibleSchema = {}
for _, row in ipairs(fullCompatibleSchema) do
    if effectDefaults[row.key]==nil then compatibleSchema[#compatibleSchema+1]=row end
end
local priorSchema = {}
for _, row in ipairs(compatibleSchema) do
    if not row.key:match('^mode_') then priorSchema[#priorSchema+1]=row end
end
local panels = {"HumanStats","VampireStats","WBP_Compass","WBP_HUD_QuestInfo","WBP_HUD_Quickslots","Crosshair","WBP_AA_Quickslots","WBP_OpenFocusPrompt","WBP_HUD_Quickslots_ChangePrompt","WBP_ControlsLegend","WBP_BuffContainer","WBP_HUD_AbilityCooldownsContainer","CombatFocusPanel","WBP_HUD_FocusCharge_Bar","WBP_HUD_SpecialAttackCooldown","XPBar","WBP_HudTimer"}
local M={}
function M.load()
local values, err = Store.load(directory, newestSchema, function()
    local legacyPath = directory .. 'QuietDawnConfig.lua'
    local legacy, le, lc = Store.read(legacyPath)
    local sources = legacy and {{path=legacyPath, text=legacy}} or {}
    if not legacy and lc ~= 2 then return nil, le end
    local ok, cfg
    if legacy then
        local chunk, ce = load(legacy, '@' .. directory .. 'QuietDawnConfig.lua', 't', {})
        if not chunk then return nil, ce end
        ok, cfg = pcall(chunk)
    else
        ok, cfg = pcall(dofile, directory .. 'QuietDawnDefaults.lua')
    end
    if not ok or type(cfg) ~= 'table' or type(cfg.panels) ~= 'table' then return nil, 'Invalid legacy QuietDawnConfig.lua' end
    local result = {}
    for _, key in ipairs({'enabled','healthThreshold','staminaThreshold','healthHoldSeconds','staminaHoldSeconds','manualPeek','manualPeekSeconds','compassOpacity'}) do
        local v = cfg[key]; if type(v)=='boolean' then v=v and 1 or 0 end; result[key]=v
    end
    -- Published Lua configs list hidden panels and use fractional resource values.
    for _, key in ipairs({'healthThreshold','staminaThreshold','compassOpacity'}) do
        if result[key]~=nil then result[key]=result[key]*100 end
    end
    local known = {};for _, p in ipairs(panels) do known[p]=true;if p~='WBP_Compass' then result['opacity_'..p]=100 end end
    local seen = {}
    for _, p in ipairs(cfg.panels) do
        if not known[p] or seen[p] then return nil, 'Unknown or duplicate legacy panel' end
        seen[p]=true;if p~='WBP_Compass' then result['opacity_'..p]=0 end
    end
    -- The time panel was not configurable in published Lua files.
    result.opacity_WBP_HudTimer=0
    -- Preserve legacy automatic versus fixed choices without changing opacity.
    for _, p in ipairs(panels) do
        local key=p=='WBP_Compass' and 'compassOpacity' or 'opacity_'..p
        result['mode_'..p]=(result[key] or 0)>0 and 2 or 1
    end
    local base=os.getenv('LOCALAPPDATA')
    if not base then return nil, 'LOCALAPPDATA unavailable for legacy migration' end
    local diagnosticsPath=base..'/Dawnwalker/Saved/Config/QuietDawnHUD.ini'
    local text, e, code=Store.read(diagnosticsPath)
    if text then sources[#sources+1]={path=diagnosticsPath, text=text} end
    if not text and code~=2 then return nil,e end
    local section, canonical, legacy='',nil,nil
    for line in (text or ''):gmatch('[^\r\n]+') do
        line=line:gsub('^\239\187\191',''):gsub('[;#].*$',''):match('^%s*(.-)%s*$')
        local header=line:match('^%[([^%]]+)%]$');if header then section=header:lower() end
        local key,value=line:match('^([%w_]+)%s*=%s*(.-)%s*$')
        if key and section=='debug' then
            key=key:lower();value=value:lower()
            local b=({['true']=1,['false']=0,['1']=1,['0']=0,on=1,off=0,yes=1,no=0})[value]
            if key=='debuglogging' or key=='enabled' then
                if b==nil then return nil,'Invalid legacy debug toggle' end
                if key=='debuglogging' then canonical=b else legacy=b end
            else
                local name=({summaryseconds='SummarySeconds',slowcallbackms='SlowCallbackMs',maxeventspersecond='MaxEventsPerSecond'})[key]
                if name then result[name]=tonumber(value);if not result[name] then return nil,'Invalid legacy diagnostics value' end end
            end
        end
    end
    -- The personal QuietDawnHUD.ini predates levels and only had an on/off
    -- switch, so translate it rather than dropping the player's choice.
    result.logLevel=LogLevels.fromLegacyToggle(canonical or legacy or 0)
    Timers.normalize(result)
    for key,value in pairs(effectDefaults) do result[key]=value end
    return result, nil, sources
end)
-- logLevel is the newest key, so a settings.ini from any earlier release stops
-- here. Re-parse against the schema that predates it, leaving the older
-- upgrades below free to run in their original order.
if not values and err=='Missing setting: logLevel' then
    local text=Store.read(Store.path(directory))
    if text then values,err=Store.parse(text,preLogLevelSchema) end
end
-- Validate any saved effect choices before older migrations can write. Missing
-- keys are added only after the prior schema has passed its own upgrade rules.
if not values and err=='Missing setting: hidePlayerCombatEffects' then
    local text=Store.read(Store.path(directory))
    if text then values,err=Store.parse(text,fullCompatibleSchema) end
end
if not values and err and err:match('^Missing setting:') then
    local text=Store.read(Store.path(directory))
    if text then
        for _,row in ipairs(newestSchema) do
            if effectDefaults[row.key]~=nil or row.key=='hidePlayerCombatEffects' then
                local _,effectError=Store.parse(text,{row})
                if effectError and not effectError:match('^Missing setting:') then
                    error('Quiet Dawn settings rejected: '..effectError)
                end
            end
        end
        if err:match('^Missing setting: hideEnemyEffectIcons$') or err:match('^Missing setting: hidePlayerEffectIcons$') then
            values,err=Store.parse(text,compatibleSchema)
        end
    end
end
-- Existing opacity settings precede panel modes. Validate them independently
-- first, so older feature upgrades keep their own backups and behavior.
if not values and err and err:match('^Missing setting: mode_') then
    local text, readError = Store.read(Store.path(directory))
    if text then
        local invalid
        for _, row in ipairs(compatibleSchema) do
            if row.key:match('^mode_') then
                local _, modeError=Store.parse(text,{row})
                if modeError and not modeError:match('^Missing setting:') then invalid=modeError;break end
            end
        end
        -- Reject a partial/corrupt mode migration before an older feature
        -- upgrade can write anything. Existing recovery copies stay intact.
        local backupPath=Store.path(directory)..'.before-panel-modes'
        local backup, backupError, backupCode=Store.read(backupPath)
        if invalid then err=invalid
        elseif backup or backupCode~=2 then err='Preserve/recover '..backupPath..': '..tostring(backupError or 'already exists')
        else values, err = Store.parse(text, priorSchema) end
    else err=readError end
end
if not values and err and err:match('^Missing setting:') then
    local defaults={showEnemyMarker=0,hideClawSlashMarks=1,hideEnemyHealthBars=1,showUnblockableWarning=0,showDirectionalParry=0,showLockIcon=0,combatCueSize=100,showCounterattackDirection=0,hideSprintPrompt=1,hideEnemyNames=1, hideEnemyDifficultyIcons=1, opacity_WBP_HudTimer=0, timeHoldSeconds=4, switchRevealSeconds=3}
    for _, p in ipairs(panels) do defaults['scale_'..p]=100 end
    local path=Store.path(directory)
    local text=Store.read(path)
    -- New keys avoid interpreting an old On=1 switch as 1% opacity. Require
    -- all old panel switches before deriving preferences; malformed input is
    -- rejected without replacing the original file.
    local legacySchema={}
    for _, row in ipairs(compatibleSchema) do
        if not row.key:match('^mode_') and not row.key:match('^scale_') and not row.key:match('^opacity_') and row.key~='timeHoldSeconds' and row.key~='switchRevealSeconds' and row.key~='hideSprintPrompt'
            and row.key~='showCounterattackDirection' and row.key~='showUnblockableWarning'
            and row.key~='showEnemyMarker' and row.key~='showDirectionalParry' and row.key~='showLockIcon' and row.key~='combatCueSize'
            and row.key~='hideClawSlashMarks' and not row.key:match('^hideEnemy') then legacySchema[#legacySchema+1]=row end
    end
    for _, p in ipairs(panels) do
        if p~='WBP_Compass' and p~='WBP_HudTimer' then legacySchema[#legacySchema+1]={key='panel_'..p,values={0,1}} end
    end
    local legacy=text and Store.parse(text,legacySchema)
    if legacy then
        for _, p in ipairs(panels) do
            if p~='WBP_Compass' and p~='WBP_HudTimer' then defaults['opacity_'..p]=legacy['panel_'..p]*100 end
        end
    end
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, path, priorSchema, defaults, 'enemy-marker')
end
if values then
    local defaults={}
    for _, p in ipairs(panels) do
        local key=p=='WBP_Compass' and 'compassOpacity' or 'opacity_'..p
        defaults['mode_'..p]=values[key]>0 and 2 or 1
    end
    -- This validates existing mode keys too; a partial upgrade never overwrites
    -- a saved choice, and malformed/duplicate modes never replace the file.
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, Store.path(directory), compatibleSchema, defaults, 'panel-modes')
end
if values then
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, Store.path(directory), fullCompatibleSchema, effectDefaults, 'effect-icons')
end
if values then
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, Store.path(directory), preLogLevelSchema, {hidePlayerCombatEffects=0}, 'player-combat-effects')
end
if values then
    -- logLevel replaced the debugLogging toggle. Read the retired key straight
    -- from the file so a player who had logging On stays verbose instead of
    -- silently dropping to the default. The stale line is then ignored:
    -- Store.parse skips keys the current schema does not declare.
    local saved=Store.read(Store.path(directory))
    local legacyLogging=saved and Store.parse(saved,{{key='debugLogging', values={0,1}}})
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, Store.path(directory), preFadeSchema,
        {logLevel=LogLevels.fromLegacyToggle(legacyLogging and legacyLogging.debugLogging or 0)},
        'log-levels')
end
if values then
    -- Fading added three keys. Their schema defaults already preserve existing
    -- behaviour (fading off), so no overrides are needed; this step exists to
    -- give the addition its own tag, so a file already stamped 'log-levels'
    -- still gains the new keys.
    values, err = dofile(directory..'UE4SSCommonSettingsUpgrade.lua').ensure(
        Store, Store.path(directory), newestSchema, {}, 'fade-transitions')
end
if values then
    local needsUpgrade=false
    for _, key in ipairs({'healthHoldSeconds','staminaHoldSeconds','manualPeekSeconds','timeHoldSeconds','switchRevealSeconds'}) do
        if values[key]>10 or values[key]*2%1~=0 then needsUpgrade=true;break end
    end
    if needsUpgrade then values,err=Timers.ensure(Store,Store.path(directory),schema) end
end
if not values then error('Quiet Dawn settings rejected: '..tostring(err)) end
return values

end
function M.convert(numeric)
local values={}
for key,value in pairs(numeric) do values[key]=value end
values.enabled=values.enabled==1;values.manualPeek=values.manualPeek==1
values.fadeTransitions=values.fadeTransitions==1
-- `debugLogging` survives as the hot per-event guard read across the gameplay
-- scripts and handed to the native bridge. It now means "the level is Debug".
values.debugLogging=values.logLevel>=LogLevels.DEBUG
values.hideEnemyHealthBars=values.hideEnemyHealthBars==1
values.hideEnemyEffectIcons=values.hideEnemyEffectIcons==1
values.hidePlayerEffectIcons=values.hidePlayerEffectIcons==1
values.hidePlayerCombatEffects=values.hidePlayerCombatEffects==1
values.hideClawSlashMarks=values.hideClawSlashMarks==1
values.hideEnemyNames=values.hideEnemyNames==1
values.hideEnemyDifficultyIcons=values.hideEnemyDifficultyIcons==1
values.showCounterattackDirection=values.showCounterattackDirection==1
values.showUnblockableWarning=values.showUnblockableWarning==1
values.showDirectionalParry=values.showDirectionalParry==1
values.showEnemyMarker=values.showEnemyMarker==1
values.showLockIcon=values.showLockIcon==1
values.hideSprintPrompt=values.hideSprintPrompt==1
-- Menu percentages become fractions only at the gameplay boundary.
for _, key in ipairs({'healthThreshold','staminaThreshold','compassOpacity'}) do values[key]=values[key]/100 end
-- Modes own opacity separately from size. Fixed zero means hidden; Quiet
-- Dawn ignores the saved fixed value and retains contextual reveals. Vanilla
-- releases our opacity override while the game keeps its contextual rules.
values.panels=panels
values.panelModes={}
values.panelOpacities={}
values.panelScales={}
for _, p in ipairs(panels) do
    values.panelScales[p]=values['scale_'..p]/100
    values.panelModes[p]=values['mode_'..p]
    values.panelOpacities[p]=values.panelModes[p]==1 and 0
        or (p=='WBP_Compass' and values.compassOpacity or values['opacity_'..p]/100)
end
-- Override only the runtime panel policy. Saved mode/opacity/size remain intact
-- and resume when the player-effect toggle is turned off.
if values.hidePlayerEffectIcons then
    values.panelModes.WBP_BuffContainer=2
    values.panelOpacities.WBP_BuffContainer=0
end
values.dynamicPanels={HumanStats=values.mode_HumanStats==1,VampireStats=values.mode_VampireStats==1}
values.path=Store.path(directory)
return values

end
return M
