-- QuietDawnFadePacing.lua
-- Render-frame and game-time pacing model for pausable Quiet Dawn fades. MIT.
--
-- A Dawnwalker pause menu can keep rendering frames while game time freezes.
-- A transition uses game time deliberately, so it must not keep running the
-- full panel worker on every rendered pause-menu frame. This model identifies
-- that exact combination and marks the fade paused without discarding it.
local Pacing = {}

function Pacing.new(frozenFrameLimit)
    local limit = math.max(1, math.floor(tonumber(frozenFrameLimit) or 4))
    local lastFrame, lastGameTime, frozenFrames, paused = nil, nil, 0, false

    local api = {}

    function api.reset()
        lastFrame, lastGameTime, frozenFrames, paused = nil, nil, 0, false
    end

    function api.paused() return paused end

    -- Feed one actually rendered frame while a fade is active. The return is
    -- `active`, `paused`, or `resumed`. A repeated timer callback from the
    -- same frame must not count: only independently rendered frames can prove
    -- that graphics continue while simulation time is frozen.
    function api.observe(frame, gameTime, fading)
        if not fading or type(frame) ~= "number" or type(gameTime) ~= "number" then
            api.reset()
            return "inactive"
        end
        if paused then
            if gameTime == lastGameTime then return "paused" end
            paused, frozenFrames = false, 0
            lastFrame, lastGameTime = frame, gameTime
            return "resumed"
        end
        if lastFrame ~= nil and frame > lastFrame and gameTime == lastGameTime then
            frozenFrames = frozenFrames + 1
            if frozenFrames >= limit then
                paused = true
                lastFrame = frame
                return "paused"
            end
        else
            frozenFrames = 0
        end
        lastFrame, lastGameTime = frame, gameTime
        return "active"
    end

    return api
end

return Pacing
