-- MenuSettings.lua
-- MIT. One converted snapshot per gameplay session; no file I/O on Apply.
local Model=require('SettingsModel')
local Levels=require('QuietDawnLogLevels')
local context=SaveLoadContext
local ok,values=pcall(function() return context and context.settings or Model.load() end)
if not ok then
    print('[Quiet Dawn - Configurable HUD] Settings rejected: '..tostring(values))
    -- Rejected settings still deserve to report why, so fall back to the
    -- default level rather than to silence.
    return {enabled=false,panels={},logLevel=Levels.DEFAULT,debugLogging=false}
end
return Model.convert(values)
