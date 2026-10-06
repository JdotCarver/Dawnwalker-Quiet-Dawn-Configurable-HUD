-- QuietDawnFocusPeek.lua
-- Pure Focus-mode transition model for Quiet Dawn's Show HUD trigger. MIT.
--
-- Gameplay reads bIsInFocusMode during work that the existing HUD/resource
-- worker already performs. Keeping the edge decision here makes the policy
-- explicit and testable: Focus entry holds the HUD open; exit starts the
-- existing timed reveal exactly once.
local FocusPeek = {}

-- Return the remembered state and an edge name. `active` must already be a
-- real boolean from the pawn; unreadable values leave the previous state
-- untouched so a transient reflected-field failure cannot fabricate an exit.
function FocusPeek.transition(previous, active)
    if type(active) ~= "boolean" then return previous, nil end
    if active and previous ~= true then return true, "entered" end
    if previous == true and not active then return false, "exited" end
    return active, nil
end

return FocusPeek
