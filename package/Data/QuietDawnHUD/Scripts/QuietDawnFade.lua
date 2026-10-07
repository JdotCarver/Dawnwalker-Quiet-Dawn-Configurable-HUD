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
-- keeps the session journal and the opacity lease discipline unchanged, and
-- supplies the clock, because which clock is used matters a great deal here.
-- D.now() is os.clock, i.e. processor time consumed by the process: coarse
-- (about 15.6 ms per tick on Windows) and not proportional to wall time. A
-- fade driven by it visibly stutters. The caller passes game time instead,
-- which is smooth, and which stops while the game is paused -- so a fade
-- does not silently complete behind a pause menu.
local M = {}

-- Panels are capped at 17 by the caller. The margin absorbs enemy bars and
-- markers should they ever fade too, and bounds memory if a caller leaks keys.
local MAX_TRANSITIONS = 32

-- A panel can stop being written at any moment: it is hidden, its mode
-- changes, the widget goes away. Its transition would then never complete,
-- and pending() would keep the worker awake for the rest of the session.
-- Every transition therefore expires shortly after it was due to finish.
local ORPHAN_GRACE_SECONDS = 1

-- And a second, clock-independent bound. A deadline is only as trustworthy as
-- the clock behind it: game time stops while the game is paused or the window
-- is in the background, so a time-based expiry alone can never fire in
-- exactly the situation where a stuck worker hurts most. Counting the worker
-- calls a transition survives cannot be fooled that way. At roughly 60 calls
-- a second this is about thirty seconds, far longer than any sane fade.
local MAX_TICKS = 2000

function M.new(D, clock)
    local transitions, transitionCount = {}, 0
    -- Reused so a fade allocates nothing per frame.
    local buffer = {}
    local enabled, fadeInSeconds, fadeOutSeconds = false, 0, 0

    -- Falls back to the diagnostics clock only if the caller supplied none.
    local function now()
        local ok, seconds = pcall(clock or D.now)
        if not ok or type(seconds) ~= "number" or seconds ~= seconds then return nil end
        return seconds
    end

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

    -- Whether fading is switched on at all. The caller needs this to decide
    -- whether it is worth deferring a write to keep panels in step: with
    -- fading off there is nothing to synchronise and the extra frame of
    -- latency would buy nothing.
    function api.enabled() return enabled end

    -- Whether this key is already mid-transition. A transition that is
    -- running is advanced in place; only a brand new one has a start moment
    -- to choose, and therefore only a brand new one needs synchronising.
    function api.active(key) return transitions[key] ~= nil end

    -- Queries are pure: logging, priority checks and scheduling must not age
    -- a transition or read the engine clock.
    function api.pending()
        return transitionCount > 0
    end

    -- Called exactly once per scheduled worker callback, even if rendering or
    -- game time stopped. Expiry lands owned live panels on their target before
    -- retiring them; missing owners are simply discarded by the caller.
    function api.expire(onExpired)
        if transitionCount==0 then return end
        local moment = now()
        for key, transition in pairs(transitions) do
            transition.ticks = transition.ticks + 1
            -- A clock that has gone backwards means a new world, or a reset
            -- game time. The transition refers to a world that no longer
            -- exists either way.
            local stale = moment == nil
                or moment > transition.deadline
                or moment < transition.start
                or transition.ticks > MAX_TICKS
            if stale then
                if onExpired then pcall(onExpired,key,transition.target) end
                discard(key)
            end
        end
    end

    -- Visits every key still owed frames. The caller advances them all inside
    -- a single worker call, so one call is one visual step: the panels stay in
    -- lockstep with each other, and the fade runs at the worker's rate rather
    -- than that rate divided by the number of panels.
    --
    -- The keys are snapshotted first because visiting one retires it.
    function api.forEach(visit)
        local total = 0
        for key in pairs(transitions) do total = total + 1; buffer[total] = key end
        for index = 1, total do visit(buffer[index]) end
        for index = 1, total do buffer[index] = nil end
    end

    -- The opacity to write this frame. When the returned value differs from
    -- `target` the caller must come back on a later frame; pending() reports
    -- that this is outstanding.
    function api.step(key, current, target)
        if not enabled then discard(key); return target end
        local moment = now()
        -- Without a trustworthy clock a fade cannot be timed. Landing on the
        -- target immediately is the honest fallback, not a guessed frame rate.
        if moment == nil then discard(key); return target end

        local transition = transitions[key]
        if transition ~= nil and moment < transition.start then
            -- Game time restarted under us; the old transition is meaningless.
            discard(key)
            transition = nil
        end
        if transition == nil or transition.target ~= target then
            if transition == nil then
                if transitionCount >= MAX_TRANSITIONS then return target end
                transitionCount = transitionCount + 1
            end
            -- Start from wherever the panel actually is, which for a reversed
            -- transition is somewhere in the middle of the previous one.
            --
            -- Hiding is slower than showing: an element appearing should feel
            -- responsive, one leaving should not snap away.
            local duration = target < current and fadeOutSeconds or fadeInSeconds
            transition = {from = current, target = target, start = moment, ticks = 0,
                duration = duration, deadline = moment + duration + ORPHAN_GRACE_SECONDS}
            transitions[key] = transition
        end

        if transition.duration <= 0 then discard(key); return target end

        local progress = (moment - transition.start) / transition.duration
        if progress >= 1 then discard(key); return target end
        return transition.from + (target - transition.from) * smoothstep(progress)
    end

    return api
end

return M
