-- QuietDawnEnemyBars.lua
-- MIT. Hiding the enemy-facing combat bars: health, name, difficulty, the
-- secondary attack dot and the wound/effect icons.
--
-- These widgets are the one part of the HUD that does not live under
-- WBP_GameHUD. They are spawned per enemy, they come and go constantly, and
-- each named child follows its own setting, so they need their own queue
-- rather than the panel pass. That queue, its retry policy and its once-per
-- -session failure reporting are all self-contained here.
--
-- Nothing in this module reaches for a global. Everything it needs -- the
-- diagnostics handle, the settings, the validity helpers, the opacity lease
-- and the shared hook registry -- arrives through the context table, because
-- the host owns the session journal and the opacity discipline and this
-- module must not quietly acquire a second opinion about either.
local M = {}

-- Build 25232147: these named children and lifecycle functions are exported
-- by WBP_CombatCharacterBar and WBP_Combat_BossBar.
local CHARACTER_BAR = "/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatCharacterBar.WBP_CombatCharacterBar_C"
local BOSS_BAR = "/Game/_Dawnwalker/UI/_Unified/Combat/WBP_Combat_BossBar.WBP_Combat_BossBar_C"

-- Every child either bar can own, in the order they are applied. Used both
-- to build the initial field lists and to recompute them when a setting
-- changes at runtime, so the two can never disagree.
local CANDIDATE_FIELDS = {
    {"SegmentedHealthBar","HealthBarLeftCap","HealthBarRightCap","LevelIndicator",
     "HelperAttackIndicator","WBP_NPCWoundContainer"},
    {"HealthBar","HealthBarLeftCap","HealthBarRightCap","IndicatorBox","BossNameLabel",
     "LevelIndicator","WBP_NPCWoundContainer"},
}

-- Which setting governs which child.
--
-- The ordinary bar has no name label; boss names use BossNameLabel. The
-- difficulty widget is hidden by its parent so its internal icon animation
-- cannot reveal it. AttackIndicatorFade animates Image_118 inside the attack
-- attachment, so hiding the parent survives both that animation and the
-- stock SetIndicatorVisible calls. The shared combat warning and lock-on
-- widget is never suppressed here.
local function settingFor(field)
    if field=="WBP_NPCWoundContainer" then return "hideEnemyEffectIcons" end
    if field=="HelperAttackIndicator" then return "showEnemyMarker" end
    if field=="BossNameLabel" then return "hideEnemyNames" end
    if field=="LevelIndicator" then return "hideEnemyDifficultyIcons" end
    return "hideEnemyHealthBars"
end

-- How many frames a child may need to appear after its owning bar fires a
-- lifecycle event. More retries merely recheck a permanently absent widget,
-- delaying every other HUD job without making that widget more likely to exist.
local MAX_READINESS_ATTEMPTS = 8
-- Retries for a lifecycle hook that will not register.
local MAX_HOOK_ATTEMPTS = 12
-- Queue bound, and the per-spec cache of recently seen bars.
local MAX_QUEUED_JOBS, MAX_RECENT_OBJECTS = 64, 64
-- Distinct failures reported per session, so one unreachable widget cannot
-- emit hundreds of identical lines across its retry budget.
local MAX_REPORTED_FAILURES = 32
-- Child names listed in a diagnostic before the list is truncated.
local MAX_REPORTED_CHILDREN = 40

function M.new(context)
    local D, config, Session = context.D, context.config, context.Session
    local valid, sameObject, unwrap = context.valid, context.sameObject, context.unwrap
    local opacity, hooks = context.opacity, context.hooks
    local reportHookError, registerHook = context.reportHookError, context.registerHook
    local wake = context.wake

    -- Whether a child should currently be hidden. showEnemyMarker is the one
    -- inverted setting: it says show, the others say hide.
    local function hidden(field)
        if field=="HelperAttackIndicator" then return not config.showEnemyMarker end
        return config[settingFor(field)] and true or false
    end

    local function fieldsFor(index)
        local list = {}
        for _,field in ipairs(CANDIDATE_FIELDS[index]) do
            if hidden(field) then list[#list+1]=field end
        end
        return list
    end

    local specs = {
        {path=CHARACTER_BAR, className="WBP_CombatCharacterBar_C", fields=fieldsFor(1), events={"Construct","UpdateTarget"}},
        {path=BOSS_BAR, className="WBP_Combat_BossBar_C", fields=fieldsFor(2), events={"Update Owner"}},
    }

    local queue, queued, first, last = {}, {}, 1, 0
    local failures = {seen={}, count=0}

    local function reportOnce(signature, format, ...)
        if failures.seen[signature] or failures.count>=MAX_REPORTED_FAILURES then return end
        failures.seen[signature]=true
        failures.count=failures.count+1
        D.logWarning(format, ...)
    end

    -- Names of a widget's child properties, for diagnostics only. UE4SS
    -- exposes property reflection through ForEachProperty on newer builds;
    -- where it is missing this degrades to a plain note rather than failing.
    local function childNames(object)
        local class = object and object.GetClass and object:GetClass()
        if not class or not class.ForEachProperty then return "<reflection unavailable>" end
        local names,total = {},0
        local ok = pcall(function()
            class:ForEachProperty(function(property)
                total=total+1
                if total<=MAX_REPORTED_CHILDREN then names[#names+1]=property:GetFName():ToString() end
            end)
        end)
        if not ok or total==0 then return "<reflection unavailable>" end
        table.sort(names)
        local extra = total-MAX_REPORTED_CHILDREN
        return table.concat(names,", ")..(extra>0 and (" ... (+"..extra.." more)") or "")
    end

    -- Resolve a named child of a widget.
    --
    -- `object[field]` only works when the Blueprint marked that widget "Is
    -- Variable", because that is what promotes it to a property on the
    -- generated class. WBP_CombatCharacterBar does; WBP_Combat_BossBar does
    -- not -- walking its class reports exactly one property, UberGraphFrame
    -- -- so no amount of retrying could ever resolve its HealthBar. That is
    -- the boss health bar never being hidden.
    --
    -- GetWidgetFromName searches the widget tree instead and does not care
    -- about the flag. It also answers the other half of the question: the
    -- tree is only populated once the widget is actually built, so a bar
    -- that does not exist until a boss appears simply returns nil here and
    -- is retried, rather than being mistaken for a missing name.
    local function findChild(object, field)
        local child = object[field]
        if valid(child) then return child end
        local found = select(2, pcall(function()
            -- UE4SS converts a Lua string to FName for this parameter.
            return object:GetWidgetFromName(field)
        end))
        if valid(found) then return found end
        return nil
    end

    local function describe(object)
        if object==nil then return "<nil>" end
        local named,name = pcall(function() return object:GetFullName() end)
        return named and tostring(name) or "<name unavailable>"
    end

    -- UE4SS can deliver an object from an unrelated Blueprint while a class
    -- construction notification is still being routed. A valid UObject is not
    -- necessarily a UserWidget: a waypoint, for example, has no callable
    -- GetOwningPlayer method. Verify the exact generated widget class before
    -- any UMG-specific calls, then drop the job rather than retrying it.
    local function belongsToSpec(object, spec)
        local ok,className = pcall(function()
            return object:GetClass():GetFName():ToString()
        end)
        return ok and className==spec.className
    end

    local api = {}

    function api.specs() return specs end

    function api.ready()
        return first<=last and context.idle() and valid(context.hud())
    end

    function api.queue(object, spec, requestedFields)
        if object==nil then return end
        spec.recent,spec.recentSet = spec.recent or {}, spec.recentSet or {}
        if not spec.recentSet[object] then
            if #spec.recent>=MAX_RECENT_OBJECTS then spec.recentSet[table.remove(spec.recent,1)]=nil end
            spec.recent[#spec.recent+1]=object
            spec.recentSet[object]=true
        end
        local fields = requestedFields or spec.fields
        if #fields==0 then return end
        -- This bar is already in the queue. Rather than queue it twice, fold
        -- the newly requested fields into the job's next pass.
        if queued[object] then
            local job = queued[object]
            job.again = true
            local merged,seen = {},{}
            for _,list in ipairs({job.fields, job.nextFields or {}, fields}) do
                for _,field in ipairs(list) do
                    if not seen[field] then merged[#merged+1]=field; seen[field]=true end
                end
            end
            job.nextFields = merged
            return
        end
        if last-first+1>=MAX_QUEUED_JOBS then
            if D.debugLogging then D.count("enemyHealthQueueFull") end
            return
        end
        last=last+1
        queue[last] = {object=object, spec=spec, fields=fields, field=1, attempts=0}
        queued[object] = queue[last]
        wake("enemyHealth")
    end

    local function step()
        local job = queue[first]
        queue[first]=nil
        first=first+1
        if first>last then first,last = 1,0 end
        local object,spec = job.object, job.spec

        local function retry()
            job.attempts = job.attempts+1
            if job.attempts < MAX_READINESS_ATTEMPTS then return true end
            -- Giving up means that child never appeared. The usual cause is
            -- a name that moved in a game update, and the message alone
            -- cannot tell that apart from a widget that is simply empty
            -- right now. So report it once per path+field, and list the
            -- widget's actual children alongside, which names the real field.
            reportOnce("readiness:"..spec.path.."#"..tostring(job.fields[job.field]),
                "Enemy HUD child never appeared: %s field=%s. "
                .."Not a class variable and not in the widget tree. Class properties: %s",
                spec.path, tostring(job.fields[job.field]), childNames(object))
            return false
        end

        local function nextField()
            job.field = job.field+1
            job.attempts = 0
            if job.field<=#job.fields then return true end
            if job.again then
                job.field = 1
                job.fields = job.nextFields or spec.fields
                job.nextFields, job.again = nil, false
                return #job.fields>0
            end
            return false
        end

        -- Register this spec's lifecycle hooks before touching any child.
        -- One event per call, so a slow registration cannot stall a frame.
        local function registerNextEvent()
            local eventIndex = spec.eventIndex or 1
            if eventIndex>#spec.events then return false end
            local path = spec.path..":"..spec.events[eventIndex]
            if hooks[path] then spec.eventIndex=eventIndex+1; return true end
            local ok,pre,post = pcall(registerHook, path, function(hookContext)
                api.queue(unwrap(hookContext), spec)
            end)
            spec.hookAttempts = (spec.hookAttempts or 0)+1
            if ok and type(pre)=="number" and type(post)=="number" then
                hooks[path] = {pre,post}
                spec.eventIndex, spec.hookAttempts = eventIndex+1, 0
            else
                reportHookError(path, ok, pre, post)
                if spec.hookAttempts>=MAX_HOOK_ATTEMPTS then
                    spec.failedEvent = spec.failedEvent or eventIndex
                    spec.eventIndex, spec.hookAttempts = eventIndex+1, 0
                    if D.debugLogging then D.event("enemyHealth","lifecycle hook unavailable: %s",path) end
                end
            end
            return true
        end

        local keep = false
        local success,reason = pcall(function()
            if not valid(object) then return end
            if not belongsToSpec(object,spec) then
                if D.debugLogging then D.count("enemyHealthForeignObjectSkipped") end
                return
            end
            -- A class default object is not a live widget: no world, no
            -- owning player, so the readiness checks below can never pass
            -- and it would burn its whole retry budget on every field.
            -- Dynamic HUD filters these the same way.
            --
            -- Checked HERE rather than when the job is queued. Queuing
            -- happens straight off NotifyOnNewObject, during level load, on
            -- objects the engine may still be constructing; a reflected call
            -- at that moment is not safe. By this point it is revalidated.
            if describe(object):find("Default__",1,true) then
                if D.debugLogging then D.count("enemyHealthClassDefaultSkipped") end
                return
            end
            if registerNextEvent() then keep=true; return end

            local objectWorld,player = object:GetWorld(), object:GetOwningPlayer()
            if not valid(objectWorld) or not valid(player) then keep=retry(); return end
            local world,controller = context.world(), context.controller()
            if not sameObject(objectWorld,world) or not sameObject(player,controller)
                or not sameObject(controller:GetWorld(),world) then return end

            local field = job.fields[job.field]
            local child = findChild(object, field)
            if not valid(child) then
                -- A missing bar or label must not block independent
                -- children. Each field gets finite readiness, and later
                -- target events retry it.
                keep = retry() or nextField()
                return
            end
            if hidden(field) then
                if child:GetRenderOpacity()~=0 then
                    opacity(child,0)
                    if D.debugLogging then
                        D.count("enemyHealthWrites")
                        if field=="HelperAttackIndicator" then D.event("enemyAttackDot","hidden=true") end
                        if field=="WBP_NPCWoundContainer" then D.event("enemyEffects","hidden=true") end
                    end
                end
            else
                local restored = Session.restore("opacity:"..tostring(child:GetAddress()))
                if D.debugLogging and restored then
                    if field=="HelperAttackIndicator" then D.event("enemyAttackDot","hidden=false") end
                    if field=="WBP_NPCWoundContainer" then D.event("enemyEffects","hidden=false") end
                end
            end
            keep = nextField()
        end)

        if not success then
            keep = retry()
            -- Report each distinct cause once, with the object that
            -- triggered it. The identity is what makes this actionable: the
            -- message alone does not say which widget could not be read.
            reportOnce(spec.path.." | "..tostring(reason),
                "Enemy health update failed (reported once): %s | object=%s",
                tostring(reason), describe(object))
            if D.debugLogging then D.count("enemyHealthUpdateFailures") end
        end

        if keep then last=last+1; queue[last]=job else queued[object]=nil end
    end

    api.step = D.wrap("enemyHealth", step)

    -- A setting changed while the game is running. Recompute each spec's
    -- field list and re-queue every bar we have seen recently, asking only
    -- for the children whose setting actually moved -- re-applying the rest
    -- would needlessly re-walk widgets that are already correct.
    function api.reconfigure(changed)
        for index,spec in ipairs(specs) do
            local affected = {}
            spec.fields = {}
            for _,field in ipairs(CANDIDATE_FIELDS[index]) do
                if hidden(field) then spec.fields[#spec.fields+1]=field end
                if changed[settingFor(field)] then affected[#affected+1]=field end
            end
            for _,object in ipairs(spec.recent or {}) do api.queue(object, spec, affected) end
        end
    end

    -- Subscribe to every bar class the game spawns. A spec whose lifecycle
    -- hook previously gave up is rewound here: a fresh object means the
    -- class is loaded now, so registration is worth another try.
    function api.subscribe(notify)
        for _,spec in ipairs(specs) do
            local ok = pcall(notify, spec.path, function(object)
                if spec.failedEvent then
                    spec.eventIndex, spec.failedEvent, spec.hookAttempts = spec.failedEvent, nil, 0
                end
                api.queue(object, spec)
            end)
            if not ok then D.logWarning("Enemy health notification unavailable: %s", spec.path) end
        end
    end

    return api
end

return M
