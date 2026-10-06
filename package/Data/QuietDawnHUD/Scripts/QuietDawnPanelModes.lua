-- QuietDawnPanelModes.lua
-- Panel-mode constants and the preserving Always Hidden settings upgrade. MIT.
--
-- Mode values are stored in settings.ini, so they stay numeric and stable.
-- Keeping their names here avoids duplicating a fourth-mode magic number in
-- the loader, gameplay policy and tests.
local M = {
    VANILLA = 0,
    QUIET_DAWN = 1,
    FIXED_OPACITY = 2,
    ALWAYS_HIDDEN = 3,
}

local panels = {
    "HumanStats", "VampireStats", "WBP_Compass", "WBP_HUD_QuestInfo",
    "WBP_HUD_Quickslots", "Crosshair", "WBP_AA_Quickslots",
    "WBP_OpenFocusPrompt", "WBP_HUD_Quickslots_ChangePrompt",
    "WBP_ControlsLegend", "WBP_BuffContainer",
    "WBP_HUD_AbilityCooldownsContainer", "CombatFocusPanel",
    "WBP_HUD_FocusCharge_Bar", "WBP_HUD_SpecialAttackCooldown", "XPBar",
    "WBP_HudTimer",
}

-- Keep the policy separate from the file transaction so regression tests can
-- exercise every saved-value conversion without pretending to be Windows.
function M.upgradeValues(values)
    local changed = false
    for _, panel in ipairs(panels) do
        local modeKey = "mode_" .. panel
        local opacityKey = panel == "WBP_Compass" and "compassOpacity" or "opacity_" .. panel
        if values[modeKey] == M.FIXED_OPACITY and values[opacityKey] == 0 then
            values[modeKey] = M.ALWAYS_HIDDEN
            changed = true
        end
    end
    return changed
end

-- Replace only the mode values whose visual behavior is already exactly
-- hidden. This mirrors the verified timer-upgrade transaction: preserve the
-- original as a dedicated backup, write and reread a temporary file, then
-- replace atomically only when the source did not change underneath us.
function M.ensure(store, path, schema)
    local original, err = store.read(path)
    if not original then return nil, err end
    local values
    values, err = store.parse(original, schema)
    if not values then return nil, err end
    if not M.upgradeValues(values) then return values end

    local section = ""
    local text = original:gsub("([^\n]+)", function(line)
        local clean = line:gsub("^\239\187\191", ""):gsub("[;#].*$", ""):match("^%s*(.-)%s*$")
        local header = clean:match("^%[([^%]]+)%]$")
        if header then section = header end
        local key, raw = clean:match("^([%w_]+)%s*=%s*(.-)%s*$")
        if section == "Settings" and key and key:match("^mode_")
            and tonumber(raw) == M.FIXED_OPACITY and values[key] == M.ALWAYS_HIDDEN then
            return (line:gsub("^(%s*[%w_]+%s*=%s*)([^%s;#]+)", function(prefix)
                return prefix .. tostring(M.ALWAYS_HIDDEN)
            end, 1))
        end
        return line
    end)

    values, err = store.parse(text, schema)
    if not values or text == original then return values, err end
    local temporary, backup = path .. ".mode-upgrade", path .. ".before-always-hidden"
    local oldBackup, backupError, backupCode = store.read(backup)
    if oldBackup or backupCode ~= 2 then
        return nil, "Preserve/recover " .. backup .. ": " .. tostring(backupError or "already exists")
    end
    local created, createError = store.create(temporary, text)
    if not created then return nil, "Cannot prepare mode upgrade: " .. tostring(createError) end
    if store.read(temporary) ~= text or store.read(path) ~= original then
        os.remove(temporary)
        return nil, "Settings changed during mode upgrade; original retained"
    end
    local moved, moveError = os.rename(path, backup)
    if not moved then os.remove(temporary); return nil, "Cannot back up settings: " .. tostring(moveError) end
    local function recover(reason)
        local current, _, code = store.read(path)
        if not current and code == 2 then os.rename(backup, path) end
        return nil, reason .. "; preserve " .. temporary .. " and " .. backup .. " for recovery"
    end
    if store.read(backup) ~= original then return recover("Settings changed before backup") end
    local installed, installError = os.rename(temporary, path)
    if not installed then return recover("Cannot finish mode upgrade: " .. tostring(installError)) end
    if store.read(path) ~= text then return recover("Cannot verify mode upgrade") end
    return values
end

return M
