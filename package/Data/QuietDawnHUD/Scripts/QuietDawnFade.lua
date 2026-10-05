-- QuietDawnFade.lua
-- MIT. Time based opacity transitions for panel show and hide.
--
-- Quiet Dawn has no permanent tick on purpose: its worker wakes on a game
-- event, drains the work that event created, and stops. A fade needs frames,
-- so this module does not schedule any of its own. It only answers "what
-- opacity should this panel have right now", and reports through pending()
-- that it still owes frames. The existing worker keeps itself alive while
-- that is true, and terminates as usual once the last transition lands.
--
-- Nothing here touches a UObject. The caller owns every read and write, which
-- keeps the session journal and the opacity lease discipline unchanged.
local M = {}

-- Panels are capped at 17 by the caller. The margin absorbs enemy bars and
-- markers should they ever fade too, and bounds memory if a caller leaks keys.
local MAX_TRANSITIONS = 32

function M.new(D)
    local transitions, transitionCount = {}, 0
    local enabled, fadeInSeconds, fadeOutSeconds = false, 0, 0

    -- Smoothstep: ease into and out of the transition so a panel does not
    -- start and stop abruptly. Dynamic HUD uses the same curve.
    local function smoothstep(progress)
        return progress * progress * (3 - 2 * progress)
    end

    local function discard(key)
        if transitions[key] == nil then return end
        transitions[key] = nil
        transitionCount = transitionCount - 1
    end

    local api = {}

    function api.reset()
        transitions, transitionCount = {}, 0
    end

    function api.configure(isEnabled, inSeconds, outSeconds)
        enabled = isEnabled and true or false
        fadeInSeconds = tonumber(inSeconds) or 0
        fadeOutSeconds = tonumber(outSeconds) or 0
        -- Changing the settings must not strand a half finished transition at
        -- an intermediate opacity: drop them so the next write lands on target.
        api.reset()
    end

    api.forget = discard

    function api.pending()
        return transitionCount > 0
    end

    -- The keys still owed frames, so the worker can revisit exactly those
    -- panels instead of sweeping all of them every frame.
    function api.names(into)
        local names = into or {}
        for key in pairs(transitions) do names[#names + 1] = key end
        return names
    end

    -- The opacity to write this frame. When the returned value differs from
    -- `target` the caller must come back on a later frame; pending() reports
    -- that this is outstanding.
    function api.step(key, current, target)
        if not enabled then discard(key); return target end
        local now = D.now()
        -- Without a trustworthy clock a fade cannot be timed. Landing on the
        -- target immediately is the honest fallback, not a guessed frame rate.
        if now == nil then discard(key); return target end

        local transition = transitions[key]
        if transition == nil or transition.target ~= target then
            if transition == nil then
                if transitionCount >= MAX_TRANSITIONS then return target end
                transitionCount = transitionCount + 1
            end
            -- Start from wherever the panel actually is, which for a reversed
            -- transition is somewhere in the middle of the previous one.
            transition = {from = current, target = target, start = now}
            transitions[key] = transition
        end

        -- Hiding is slower than showing: an element appearing should feel
        -- responsive, one leaving should not snap away.
        local duration = target < transition.from and fadeOutSeconds or fadeInSeconds
        if duration <= 0 then discard(key); return target end

        local progress = (now - transition.start) / duration
        if progress >= 1 then discard(key); return target end
        return transition.from + (target - transition.from) * smoothstep(progress)
    end

    return api
end

return M
