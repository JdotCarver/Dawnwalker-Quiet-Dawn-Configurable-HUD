-- QuietDawnStartupBarrier.lua
-- Startup readiness model for Quiet Dawn's ordinary HUD baseline. MIT.
--
-- The game constructs its HUD one named widget at a time. This small model
-- records the Quiet Dawn baseline groups that must be ready before Gameplay
-- fades them away as a single wave. It deliberately has no clock or timeout:
-- readiness is defined by observed widgets, or by Gameplay's bounded failed
-- field-read outcome.
local Barrier = {}
local QUIET_DAWN, FIXED_OPACITY, ALWAYS_HIDDEN = 1, 2, 3

-- Human and vampire stats occupy one ordinary HUD position. Either live form
-- proves that position is ready; every other position has one exact container.
local groups = {
    {"HumanStats", "VampireStats"},
    {"XPBar"},
    {"WBP_Compass"},
    {"WBP_HUD_QuestInfo"},
    {"WBP_HUD_Quickslots"},
    {"WBP_AA_Quickslots"},
    {"WBP_HudTimer"},
}

function Barrier.new(panelModes, panelOpacities, startedAt)
    local barrier = {
        active = true,
        startedAt = startedAt,
        -- members join the initial hide wave: Quiet Dawn, Fixed 0% and
        -- Always Hidden ordinary baseline panels.
        members = {},
        -- watchers are all form candidates that can prove a group ready.
        watchers = {},
        pending = {},
        groups = 0,
        remaining = 0,
        wave = {},
        waveSize = 0,
        releasePending = false,
    }

    for groupIndex, names in ipairs(groups) do
        local enabled = false
        for _, name in ipairs(names) do
            -- Vanilla panels retain game ownership. Quiet Dawn and panels
            -- explicitly hidden at startup join the shared dismissal, so a
            -- saved Fixed 0% / Always Hidden setting never snaps away ahead
            -- of the ordinary baseline wave.
            local mode=panelModes[name]
            local opacity=panelOpacities[name]
            if mode == QUIET_DAWN or mode == ALWAYS_HIDDEN
                or (mode == FIXED_OPACITY and opacity == 0) then
                barrier.members[name] = groupIndex
                enabled = true
            end
        end
        if enabled then
            -- A player can load in either form. The group is ready as soon as
            -- either valid form container arrives, even if only the other
            -- form has a Quiet Dawn mode setting.
            for _, name in ipairs(names) do barrier.watchers[name] = groupIndex end
            barrier.pending[groupIndex] = true
            barrier.groups = barrier.groups + 1
            barrier.remaining = barrier.remaining + 1
        end
    end

    barrier.active = barrier.remaining > 0
    return barrier
end

-- Resolve the group that `name` belongs to. Returns its numeric identifier
-- once, or nil when that group was already resolved or is not participating.
-- Gameplay calls this for both an observed widget and an exhausted bounded
-- field retry, then supplies the diagnostic wording appropriate to that path.
function Barrier.resolve(barrier, name)
    if not barrier or not barrier.active then return nil end
    local group = barrier.watchers[name]
    if not group or not barrier.pending[group] then return nil end
    barrier.pending[group] = nil
    barrier.remaining = barrier.remaining - 1
    if barrier.remaining == 0 then barrier.releasePending = true end
    return group
end

return Barrier
