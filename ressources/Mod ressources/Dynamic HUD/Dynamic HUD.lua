-- Dynamic HUD 1.0 -- independent widget fading for Blood of the Dawnwalker.
-- No visibility, bShown, input, or HUD-root opacity writes. UE4SS game thread only.
local PREFIX = '[DynamicHUD] '
local cfg = {SmoothFade=1, HideSprintPrompt=0, HideInfoButton=0}
cfg.QuickSlotTooltip=0;cfg.HideEnemyHealth=0;cfg.HealthModified=1;cfg.StaminaModified=1;cfg.TimeModified=1
cfg.HideBossHealth=0
cfg.HideQuickSlotAbilityCooldown=0
cfg.VitalsScale=100
cfg.CompassScale=100
cfg.QuickSlotsScale=100
cfg.TimeScale=100
cfg.ObjectivesScale=100
cfg.EnemyHealthScale=100
cfg.BossHealthScale=100
local groups = {'Health','Stamina','Experience','Compass','Objectives','QuickSlots','Time'}
for _,g in ipairs(groups) do
    cfg[g..'Idle']=1
    cfg[g..'Focus']=1;cfg[g..'Stance']=1
    cfg[g..'VisibleOpacity']=100;cfg[g..'HiddenOpacity']=0
end
local paths = {'ue4ss/Mods/DynamicHUD/config.ini','Mods/DynamicHUD/config.ini','DynamicHUD/config.ini'}
-- Resolve the installed mod even when the game's working directory differs.
do
    local ok,info=pcall(function() return debug.getinfo(1,'S') end)
    local source=ok and info and info.source
    if type(source)=='string' and source:sub(1,1)=='@' then
        local filename=source:sub(2):gsub('\\','/')
        local directory=filename:match('^(.*)/[Ss]cripts/[^/]+$')
        if directory then paths={directory..'/config.ini'} end
    end
end
local configText
local configPath
local function log(s) print(PREFIX .. s .. '\n') end
local function safe(fn) local ok,v=pcall(fn); if ok then return v end end
local function live(o) return o~=nil and safe(function() return o:IsValid() end)==true end
local function short(o) return live(o) and safe(function() return o:GetFName():ToString() end) or '' end
local function class(o) return live(o) and safe(function() return o:GetClass():GetFName():ToString() end) or '' end
local function identity(o) return live(o) and safe(function() return o:GetFullName() end) or '' end
local function readConfig()
    for _, path in ipairs(configPath and {configPath} or paths) do
        local f=io.open(path,'r')
        if f then
            configPath=path
            local text=f:read('*a'); f:close()
            if text==configText then return end
            -- Apply a complete snapshot on the game thread, never mutate from an async loop.
            local nextCfg={}; for k,v in pairs(cfg) do nextCfg[k]=v end
            local section
            for line in (text..'\n'):gmatch('(.-)\n') do
                line=line:gsub('^\239\187\191','')
                local heading=line:match('^%s*%[([^%]]+)%]')
                if heading then section=heading end
                local k,v=line:match('^%s*([%w_]+)%s*=%s*([%-%.%d]+)')
                local n=tonumber(v)
                if section=='Settings' and k and nextCfg[k]~=nil and n and n==n then
                    if k:match('Scale$') then nextCfg[k]=math.max(60,math.min(110,n))
                    elseif k=='HideQuickSlotAbilityCooldown' then nextCfg[k]=math.max(0,math.min(2,math.floor(n)))
                    elseif k:match('Opacity$') then nextCfg[k]=math.max(0,math.min(100,n))
                    else nextCfg[k]=n~=0 and 1 or 0 end
                end
            end
            cfg=nextCfg;configText=text;return
        end
    end
end
-- Defaults are captured before reading saved values. Migration runs once at startup.
local defaults={}
local configKeys={}
for key,value in pairs(cfg) do defaults[key]=value;configKeys[#configKeys+1]=key end
table.sort(configKeys)
local function addModifiedKeys()
    local path,original
    for _,candidate in ipairs(paths) do
        local f=io.open(candidate,'rb')
        if f then path=candidate;original=f:read('*a');f:close();break end
    end
    local function missingSettings(text)
        local found,legacy={},{}
        local section,insertAt
        local offset=1
        local newline=text:find('\r\n',1,true) and '\r\n' or '\n'
        for line,ending in text:gmatch('([^\n]*)(\n?)') do
            local clean=line:gsub('^\239\187\191','')
            local heading=clean:match('^%s*%[([^%]]+)%]')
            if heading then
                section=heading
                if heading=='Settings' and not insertAt then insertAt=offset+#line+#ending-1 end
            else
                local key,value=clean:match('^%s*([%w_]+)%s*=%s*(.*)')
                if section=='Settings' and key then
                    found[key]=true
                    legacy[key]=tonumber(value:match('^([%-%.%d]+)'))
                end
            end
            offset=offset+#line+#ending
        end
        local extra={}
        for _,key in ipairs(configKeys) do
            if not found[key] then
                local value=defaults[key]
                if key=='HideBossHealth' and legacy.ShowBossHealth~=nil then value=legacy.ShowBossHealth==0 and 1 or 0 end
                if key=='HideEnemyHealth' and legacy.EnemyHealth~=nil then value=legacy.EnemyHealth==0 and 1 or 0 end
                extra[#extra+1]=key..' = '..value..newline
            end
        end
        if #extra==0 then return text,0 end
        local additions=table.concat(extra)
        if insertAt then
            local before=text:sub(1,insertAt)
            if before:sub(-1)~='\n' then before=before..newline end
            return before..additions..text:sub(insertAt+1),#extra
        end
        local separator=(text=='' or text:sub(-1)=='\n') and '' or newline
        return text..separator..'[Settings]'..newline..additions,#extra
    end
    local updated,count=missingSettings(original or '')
    if count==0 then return end
    if not path then
        for _,candidate in ipairs(paths) do
            local manifest=io.open(candidate:gsub('config%.ini$','mod_settings.ini'),'rb')
            if manifest then
                manifest:close()
                local f,err=io.open(candidate,'wb')
                if not f then log('Config creation failed: '..tostring(err));return end
                local ok,writeError=f:write(updated);local closed,closeError=f:close()
                if ok and closed then
                    configPath=candidate
                    log('Default config created: '..candidate)
                else log('Default config write failed: '..tostring(writeError or closeError)) end
                return
            end
        end
        log('Config creation failed: could not locate mod_settings.ini beside the mod.')
        return
    end
    local backup=io.open(path:gsub('config%.ini$','config.bak'),'wb')
    if not backup then log('Config migration: backup unavailable. Config unchanged.');return end
    local saved=backup:write(original);local closed=backup:close()
    if not saved or not closed then log('Config migration: backup failed. Config unchanged.');return end
    local out=io.open(path,'wb')
    if not out then log('Config migration: write unavailable.');return end
    local written=out:write(updated);local finished=out:close()
    if written and finished then log('Config updated: '..count..' missing settings added.')
    else log('Config write failed; restore config.bak.') end
end
addModifiedKeys()
readConfig()
local root, rootId, records, timer = nil, '', {}, nil
local suppressed={}
local enemyRecords,enemyPending={},{}
local enemyRootId
local feedingFades={}
local feedingWidgets={}
local feeding=false
local healthBars={}
local staminaBars={}
local formSwitcher
local formOrder={}
local timerBars={}
local previousTimer={}
local modified={Health=false,Stamina=false,Time=false}
local emptyBars={}
local rebuild=true
local queue={}
local classGroups={WBP_HUD_HumanStats_C='Health',WBP_HUD_VampireStats_C='Health',
    WBP_HUD_PlayerStaminaBar_C='Stamina',WBP_HUD_XPBar_C='Experience'}
local topGroups={QuickslotContainer='QuickSlots',QuestContainer='Objectives',
    CompassContainer='Compass',TimeContainer='Time'}
local function opacity(w) return safe(function() return w.RenderOpacity end) end
local function write(w,v)
    if not live(w) then return false end
    return pcall(function() w:SetRenderOpacity(v) end)
end
local scaleKeys={Health='VitalsScale',Stamina='VitalsScale',Experience='VitalsScale',
    Compass='CompassScale',QuickSlots='QuickSlotsScale',Time='TimeScale',Objectives='ObjectivesScale'}
local function readScale(w)
    return safe(function()
        local v=w.RenderTransform.Scale
        return {X=v.X,Y=v.Y}
    end)
end
local function sameScale(a,b)
    return a and b and math.abs(a.X-b.X)<0.0001 and math.abs(a.Y-b.Y)<0.0001
end
local scalePivots={
    Health={X=0,Y=1},Stamina={X=0,Y=1},Experience={X=0,Y=1},
    QuickSlots={X=1,Y=1},Time={X=1,Y=0},Objectives={X=1,Y=0},
    Compass={X=0.5,Y=0},BossHealth={X=0.5,Y=0}}
local enemyPivot={X=0.5,Y=0.5}
local function readPivot(w)
    return safe(function() local p=w.RenderTransformPivot;return {X=p.X,Y=p.Y} end)
end
local function restorePivot(r)
    if not r.pivotLast then return end
    if sameScale(readPivot(r.w),r.pivotLast) then
        if not pcall(function() r.w:SetRenderTransformPivot(r.pivotBase) end) then return end
    end
    r.pivotLast=nil;r.pivotBase=nil
end
local function applyScale(r,percent)
    if percent==100 and not r.scaleLast and not r.pivotLast then return end
    if not live(r.w) then return end
    local actual=readScale(r.w)
    if not actual or type(actual.X)~='number' or type(actual.Y)~='number' then return end
    if percent==100 then
        if sameScale(actual,r.scaleLast) then
            local ok=pcall(function() r.w:SetRenderScale(r.scaleBase) end)
            if not ok then return end
        end
        restorePivot(r)
        r.scaleLast=nil;r.scaleBase=nil;return
    end
    if not r.scaleBase or (r.scaleLast and not sameScale(actual,r.scaleLast)) then r.scaleBase=actual end
    local pivot=scalePivots[r.group or r.kind] or enemyPivot
    local currentPivot=readPivot(r.w)
    if not currentPivot or type(currentPivot.X)~='number' or type(currentPivot.Y)~='number' then return end
    if not r.pivotBase then r.pivotBase=currentPivot end
    if not sameScale(currentPivot,pivot) then
        if not pcall(function() r.w:SetRenderTransformPivot(pivot) end) then return end
        r.pivotLast=pivot
    end
    local factor=percent/100
    local desired={X=r.scaleBase.X*factor,Y=r.scaleBase.Y*factor}
    if not sameScale(actual,desired) then
        if pcall(function() r.w:SetRenderScale(desired) end) then r.scaleLast=desired;r.geometryWait=true end
    end
end
local slateLibrary
local function moveTracker(r,delta,deltaX)
    deltaX=deltaX or 0
    if delta==0 and deltaX==0 and not r.offsetLast then return end
    if not live(r.w) then return end
    local actual=safe(function()
        local t=r.w.RenderTransform.Translation;return {X=t.X,Y=t.Y}
    end)
    if not actual or type(actual.X)~='number' or type(actual.Y)~='number' then return end
    if delta==0 and deltaX==0 then
        if sameScale(actual,r.offsetLast) then
            if not pcall(function() r.w:SetRenderTranslation(r.offsetBase) end) then return end
        end
        r.offsetBase=nil;r.offsetLast=nil;return
    end
    if not r.offsetBase or (r.offsetLast and not sameScale(actual,r.offsetLast)) then r.offsetBase=actual end
    local wanted={X=r.offsetBase.X+deltaX,Y=r.offsetBase.Y+delta}
    if not sameScale(actual,wanted) then
        if pcall(function() r.w:SetRenderTranslation(wanted) end) then r.offsetLast=wanted end
    end
end
local function updateTrackerSpacing()
    local timeRecord
    local wait=false
    for _,r in ipairs(records) do
        if r.group=='Time' then timeRecord=r end
        if (r.group=='Time' or r.group=='Objectives') and r.geometryWait then
            r.geometryWait=nil;wait=true
        end
    end
    -- Cached geometry must catch up with render-transform changes first.
    if wait or not timeRecord or not live(timeRecord.w) then return end
    if not live(slateLibrary) then slateLibrary=safe(function() return StaticFindObject('/Script/UMG.Default__SlateBlueprintLibrary') end) end
    if not live(slateLibrary) then return end
    local metrics=safe(function()
        local geometry=timeRecord.w:GetCachedGeometry()
        local size=slateLibrary:GetLocalSize(geometry)
        local centre=slateLibrary:LocalToAbsolute(geometry,{X=size.X/2,Y=0})
        return {height=size.Y,x=centre.X}
    end)
    if not metrics or metrics.height<=0 then return end
    local baseScale=timeRecord.scaleBase or readScale(timeRecord.w)
    if not baseScale then return end
    local delta=metrics.height*baseScale.Y*(cfg.TimeScale/100-1)
    for _,r in ipairs(records) do
        if r.group=='Objectives' and live(r.w) then
            local alignment=safe(function()
                local geometry=r.w:GetCachedGeometry()
                local size=slateLibrary:GetLocalSize(geometry)
                if size.X<=0 then return nil end
                local centre=slateLibrary:LocalToAbsolute(geometry,{X=size.X/2,Y=0})
                local unit=slateLibrary:LocalToAbsolute(geometry,{X=size.X/2+1,Y=0})
                local scale=r.w.RenderTransform.Scale.X
                local parentUnit=(unit.X-centre.X)/scale
                if math.abs(parentUnit)<0.0001 then return nil end
                local translation=r.w.RenderTransform.Translation.X
                local original=r.offsetBase and r.offsetBase.X or translation
                return translation-original+(metrics.x-centre.X)/parentUnit
            end)
            if type(alignment)=='number' then moveTracker(r,delta,alignment) end
        end
    end
end
local alignmentTicks=0
local lastTimeScale,lastObjectivesScale
local function updatePlayerScales()
    for _,r in ipairs(records) do applyScale(r,cfg[scaleKeys[r.group]]) end
    for _,r in ipairs(suppressed) do
        if r.kind=='BossHealth' then applyScale(r,cfg.BossHealthScale) end
    end
    local urgent=cfg.TimeScale~=lastTimeScale or cfg.ObjectivesScale~=lastObjectivesScale
    for _,r in ipairs(records) do
        if (r.group=='Time' or r.group=='Objectives') and r.geometryWait then urgent=true end
    end
    lastTimeScale=cfg.TimeScale;lastObjectivesScale=cfg.ObjectivesScale
    if urgent then alignmentTicks=0 end
    if alignmentTicks<=0 then
        updateTrackerSpacing()
        alignmentTicks=urgent and 0 or 4
    else alignmentTicks=alignmentTicks-1 end
end
local function restore()
    alignmentTicks=0
    for _,r in ipairs(records) do if r.group=='Objectives' then moveTracker(r,0) end end
    for _,r in ipairs(records) do applyScale(r,100) end
    for _,r in ipairs(suppressed) do if r.kind=='BossHealth' then applyScale(r,100) end end
    for _,r in ipairs(records) do
        if live(r.w) then
            local actual=opacity(r.w)
            -- Only undo our own last value; retain newer game-authored opacity.
            if r.last~=nil and type(actual)=='number' and math.abs(actual-r.last)<0.002 then
                write(r.w,r.base)
            end
        end
    end
    for _,r in ipairs(suppressed) do
        if live(r.w) and r.last~=nil then
            local actual=opacity(r.w)
            if type(actual)=='number' and math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
        end
    end
    records={};suppressed={}
end
local function children(w)
    local out={}
    local tree=safe(function() return w.WidgetTree end)
    local top=live(tree) and safe(function() return tree.RootWidget end) or nil
    if live(top) then out[#out+1]=top end
    local n=safe(function() return w:GetChildrenCount() end)
    if type(n)=='number' then
        for i=0,math.min(n,256)-1 do
            local c=safe(function() return w:GetChildAt(i) end)
            if live(c) then out[#out+1]=c end
        end
    end
    return out
end
local function findNamed(w,wanted,depth)
    if not live(w) or depth>16 then return nil end
    if short(w)==wanted then return w end
    for _,child in ipairs(children(w)) do
        local found=findNamed(child,wanted,depth+1)
        if found then return found end
    end
end
local function suppress(w,kind)
    local v=live(w) and opacity(w) or nil
    if type(v)=='number' then suppressed[#suppressed+1]={w=w,base=v,kind=kind} end
end
-- Enemy bars have their own lifecycle: never rebuild the player HUD for them.
local function queueEnemy(bar)
    if not live(bar) then return end
    local id=identity(bar)
    if id=='' or id:find('Default__',1,true) or enemyRecords[id] or enemyPending[id] then return end
    enemyPending[id]={w=bar,tries=0}
end
local enemyCleanupTicks=0
local function updateEnemies()
    enemyCleanupTicks=enemyCleanupTicks+1
    local cleanup=enemyCleanupTicks>=20
    if cleanup then enemyCleanupTicks=0 end
    for id,p in pairs(enemyPending) do
        if not live(p.w) then enemyPending[id]=nil
        else
            local target=findNamed(p.w,'Overlay_0',0)
            local v=live(target) and opacity(target) or nil
            if type(v)=='number' then
                enemyRecords[id]={w=target,base=v};enemyPending[id]=nil
            else
                p.tries=p.tries+1
                if p.tries>=20 then enemyPending[id]=nil end
            end
        end
    end
    local hide=cfg.HideEnemyHealth==1
    for id,r in pairs(enemyRecords) do
        local scaling=cfg.EnemyHealthScale~=100 or r.scaleLast~=nil or r.pivotLast~=nil
        if hide or r.last~=nil or scaling or cleanup then
        if scaling then applyScale(r,cfg.EnemyHealthScale) end
        if not live(r.w) then enemyRecords[id]=nil
        elseif hide or r.last~=nil then
            local actual=opacity(r.w)
            if type(actual)=='number' then
                if r.last~=nil and math.abs(actual-r.last)>0.002 then r.base=actual end
                if hide then
                    if actual~=0 then
                        if r.last==nil then r.base=actual end
                        if write(r.w,0) then r.last=0 end
                    end
                elseif r.last~=nil then
                    if math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
                    r.last=nil
                end
            end
        end
        end
    end
end
local function restoreFeedingFades()
    for _,r in pairs(feedingFades) do
        if live(r.w) and r.last~=nil then
            local actual=opacity(r.w)
            if type(actual)=='number' and math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
        end
    end
    feedingFades={}
end
local function updateFeedingFades()
    if cfg.SmoothFade==0 then
        if next(feedingFades) then restoreFeedingFades() end
        return
    end
    for id,r in pairs(feedingFades) do
        if not feedingWidgets[id] or not live(r.w) then feedingFades[id]=nil end
    end
    local frontend=rootId:match(' (%S+)%.WBP_GameHUD_C_[^%.]+$')
    for id,w in pairs(feedingWidgets) do
        if frontend and id:find(' '..frontend..'.WBP_HUD_DrinkBlood_C_',1,true) and live(w) then
            local r=feedingFades[id]
            if not r then
                local tree=safe(function() return w.WidgetTree end)
                local content=live(tree) and safe(function() return tree.RootWidget end) or nil
                local value=live(content) and opacity(content) or nil
                if type(value)=='number' then
                    r={w=content,base=value,mult=0,from=0,target=0,elapsed=0};feedingFades[id]=r
                end
            end
            if r and live(r.w) then
                local parentOpacity=opacity(w)
                local active=safe(function() return w:IsRendered() end)==true
                    and type(parentOpacity)=='number' and parentOpacity>0.001
                local target=active and 1 or 0
                if target~=r.target then r.from=r.mult;r.target=target;r.elapsed=0 end
                if r.mult~=target then
                    r.elapsed=r.elapsed+0.05
                    local duration=target<r.from and 0.45 or 0.22
                    local t=math.min(1,r.elapsed/duration)
                    r.mult=r.from+(target-r.from)*(t*t*(3-2*t))
                end
                local actual=opacity(r.w)
                if type(actual)=='number' then
                    if r.last~=nil and math.abs(actual-r.last)>0.002 then r.base=actual end
                    local desired=r.base*r.mult
                    if math.abs(actual-desired)>0.001 and write(r.w,desired) then r.last=desired end
                end
            end
        elseif feedingFades[id] then
            local r=feedingFades[id]
            if live(r.w) and r.last~=nil then
                local actual=opacity(r.w)
                if type(actual)=='number' and math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
            end
            feedingFades[id]=nil
        end
    end
end
local function trackFeeding(w)
    if not live(w) then return end
    local id=identity(w)
    if id~='' and not id:find('Default__',1,true) then feedingWidgets[id]=w end
end
local cooldownBuffs={}
local cooldownBuffRoot
local cooldownCleanup=0
local function trackCooldownBuff(w)
    if not live(w) then return end
    local id=identity(w)
    local path=rootId:match(' (%S+)$')
    if not path or id:find('Default__',1,true) then return end
    local prefix='WBP_HUD_Buff_C '..path..'.WidgetTree_'
    if id:sub(1,#prefix)~=prefix or not id:find('.WBP_HUD_AbilityCooldownsContainer.',#prefix,true) then return end
    if cooldownBuffs[id] then return end
    local value=opacity(w)
    if type(value)=='number' then cooldownBuffs[id]={w=w,base=value} end
end
local function restoreCooldownBuffs()
    for _,r in pairs(cooldownBuffs) do
        if r.last~=nil and live(r.w) then
            local actual=opacity(r.w)
            if type(actual)=='number' and math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
        end
    end
    cooldownBuffs={}
end
local function updateCooldownBuffs(hide)
    cooldownCleanup=cooldownCleanup+1
    local cleanup=cooldownCleanup>=20
    if cleanup then cooldownCleanup=0 end
    for id,r in pairs(cooldownBuffs) do
        if hide or r.last~=nil or cleanup then
            if not live(r.w) then cooldownBuffs[id]=nil
            elseif hide or r.last~=nil then
                local actual=opacity(r.w)
                if type(actual)=='number' then
                    if r.last~=nil and math.abs(actual-r.last)>0.002 then r.base=actual end
                    if hide then
                        if actual~=0 then
                            if r.last==nil then r.base=actual end
                            if write(r.w,0) then r.last=0 end
                        end
                    elseif r.last~=nil then
                        if math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
                        r.last=nil
                    end
                end
            end
        end
    end
end
local function build()
    restore(); timer=nil
    healthBars={};staminaBars={};formSwitcher=nil;formOrder={};timerBars={};previousTimer={}
    if not live(root) then return end
    local seen, budget={},2500
    -- Partition branches so health and stamina never receive nested multipliers.
    -- A branch shared by groups is split; a branch with one group gets one write.
    local function partition(w,inherited,depth)
        if not live(w) or depth>32 or budget<=0 then return {},{} end
        local id=identity(w);if id=='' or seen[id] then return {},{} end
        seen[id]=true;budget=budget-1
        local c=class(w)
        if c=='WBP_HUD_AbilityCooldownsContainer_C' then return {},{} end
        local group=classGroups[c] or inherited
        if c=='WBP_HudTimer_C' then timer=w end
        if c=='WidgetSwitcher' and short(w)=='StatSwitcher' then
            formSwitcher=w
            for index,child in ipairs(children(w)) do formOrder[index-1]=class(child) end
        end
        if c=='TippedProgressBar' then
            local full=identity(w)
            local n=short(w)
            if group=='Stamina' and n=='MainProgressBar' then
                local form=full:find('.HumanStats.',1,true) and 'WBP_HUD_HumanStats_C'
                    or (full:find('.VampireStats.',1,true) and 'WBP_HUD_VampireStats_C')
                if form then staminaBars[form]=w end
            elseif group=='Health' and n=='MainProgressBar' then
                local form=full:find('.HumanStats.',1,true) and full:find('.HPBar.',1,true) and 'WBP_HUD_HumanStats_C'
                    or (full:find('.VampireStats.',1,true) and full:find('.WBP_HUD_VampireStats_BloodSegment_C_',1,true) and 'WBP_HUD_VampireStats_C')
                if form then
                    healthBars[form]=healthBars[form] or {}
                    healthBars[form][#healthBars[form]+1]=w
                end
            elseif group=='Time' and (n=='MainProgressBar' or n=='BackgroundProgressBar') then timerBars[n]=w end
        end
        local set, list={},{}
        if group then set[group]=true end
        for _,child in ipairs(children(w)) do
            local cs,cl=partition(child,group,depth+1)
            for g in pairs(cs) do set[g]=true end
            for _,r in ipairs(cl) do list[#list+1]=r end
        end
        local sole,number=nil,0
        for g in pairs(set) do sole=g;number=number+1 end
        if group and number==1 and c~='NamedToggleableContainer' then return set,{{w=w,group=sole}} end
        return set,list
    end
    local tree=safe(function() return root.WidgetTree end)
    local top=live(tree) and safe(function() return tree.RootWidget end) or nil
    if not live(top) then return end
    for _,w in ipairs(children(top)) do
        local n=short(w)
        local targets={}
        if n=='PromptContainer' then
            -- Restrict the extra walk to the known prompt branch. Never suppress it
            -- wholesale: interaction prompts share these containers.
            local function collect(node,depth)
                if not live(node) or depth>12 then return end
                local c=class(node)
                if c=='WBP_InputPrompt_C' then
                    local label=findNamed(node,'PromptLabel',0)
                    local v=opacity(node)
                    if live(label) and type(v)=='number' then
                        suppressed[#suppressed+1]={w=node,label=label,base=v,kind='Sprint'}
                    end
                    return
                elseif c=='WBP_OpenFocusPrompt_C' then
                    -- This dedicated widget contains Toggle Active Abilities.
                    -- Hide its content so the game's parent fade remains untouched.
                    local border=findNamed(node,'Border_676',0)
                    local v=live(border) and opacity(border) or nil
                    if type(v)=='number' then suppressed[#suppressed+1]={w=border,base=v,kind='QuickSlotTooltip'} end
                    return
                elseif c=='WBP_ControlsLegend_C' then
                    -- Border_0 contains CTRLTGL and LegendImage, not the expandable list.
                    local border=findNamed(node,'Border_0',0)
                    local v=live(border) and opacity(border) or nil
                    if type(v)=='number' then suppressed[#suppressed+1]={w=border,base=v,kind='Info'} end
                    return
                end
                for _,child in ipairs(children(node)) do collect(child,depth+1) end
            end
            collect(w,0)
        elseif topGroups[n] then
            local _,list=partition(w,topGroups[n],0);targets=list
        elseif n=='StatContainer' then
            local _,list=partition(w,nil,0);targets=list
        elseif n=='TopWidgetSwitcher' then
            -- Only the compass; never alter the alternate boss/progress bars.
            for _,c in ipairs(children(w)) do
                if short(c)=='CompassContainer' then
                    local _,list=partition(c,'Compass',0)
                    for _,r in ipairs(list) do targets[#targets+1]=r end
                elseif short(c)=='BossBarContainer' then
                    local bar=findNamed(c,'BossBar',0)
                    if live(bar) then suppress(bar,'BossHealth') end
                end
            end
        end
        for _,r in ipairs(targets) do
            local v=opacity(r.w)
            if type(v)=='number' then
                r.base=v;r.mult=1;r.from=1;r.target=1;r.elapsed=0;r.last=nil
                records[#records+1]=r
            end
        end
    end
    if cooldownBuffRoot~=rootId then
        restoreCooldownBuffs();cooldownBuffRoot=rootId
        local buffs=safe(function() return FindAllOf('WBP_HUD_Buff_C') end)
        if type(buffs)=='table' then for _,w in pairs(buffs) do trackCooldownBuff(w) end end
    end
    -- Seed once per HUD instance; newly created enemy widgets use the queue.
    if enemyRootId~=rootId then
        enemyRootId=rootId
        restoreFeedingFades()
        feedingWidgets={};feeding=false
        local widgets=safe(function() return FindAllOf('WBP_HUD_DrinkBlood_C') end)
        if type(widgets)=='table' then for _,w in pairs(widgets) do trackFeeding(w) end end
        local bars=safe(function() return FindAllOf('WBP_CombatCharacterBar_C') end)
        if type(bars)=='table' then for _,bar in pairs(bars) do queueEnemy(bar) end end
    end
    -- DynamicEntryBox entries are not exposed by the normal panel child walk.
    -- Resolve the captured segment class only when rebuilding, scoped to this HUD.
    local rootName=identity(root):match(' (%S+)$')
    local segments=safe(function() return FindAllOf('WBP_HUD_VampireStats_BloodSegment_C') end)
    if rootName and type(segments)=='table' then
        for _,segment in pairs(segments) do
            if live(segment) and identity(segment):find(rootName..'.',1,true) then
                partition(segment,'Health',0)
            end
        end
    end
    local counts={};for _,r in ipairs(records) do counts[r.group]=(counts[r.group] or 0)+1 end
    local parts={};for _,g in ipairs(groups) do parts[#parts+1]=g..'='..(counts[g] or 0) end
    log('Mapped '..table.concat(parts,', '))
    if budget<=0 then log('Widget traversal limit reached; inspect Shift + F11 diagnostics.') end
end
local function promptText(label)
    return safe(function() return label.Text:ToString() end)
end
local combatSub
local combatRoot
local combatRetry=0
local function hideAbilityCooldown()
    if combatRoot~=rootId then combatRoot=rootId;combatSub=nil;combatRetry=0 end
    if cfg.HideQuickSlotAbilityCooldown~=2 then
        combatSub=nil;combatRetry=0
        return cfg.HideQuickSlotAbilityCooldown==1
    end
    if not live(combatSub) then
        combatSub=nil
        combatRetry=combatRetry-1
        if combatRetry<=0 then
            combatRetry=20
            local candidate=safe(function() return FindFirstOf('CombatSubsystem') end)
            if live(candidate) and not identity(candidate):find('Default__',1,true) then combatSub=candidate end
        end
    end
    return live(combatSub) and safe(function() return combatSub.bIsInCombat end)==true
end
local function hidePrompts()
    updateCooldownBuffs(hideAbilityCooldown())
    for _,r in ipairs(suppressed) do
        local active=(r.kind=='BossHealth' and cfg.HideBossHealth==1)
            or (r.kind=='Info' and cfg.HideInfoButton==1)
            or (r.kind=='QuickSlotTooltip' and cfg.QuickSlotTooltip==1)
            or (r.kind=='Sprint' and cfg.HideSprintPrompt==1)
        -- Off with nothing left to restore: no UObject reads.
        if active or r.last~=nil then
        if live(r.w) then
            local actual=opacity(r.w)
            if type(actual)=='number' then
                if r.last~=nil and math.abs(actual-r.last)>0.002 then r.base=actual end
                local hide=(r.kind=='BossHealth' and cfg.HideBossHealth==1) or (r.kind=='Info' and cfg.HideInfoButton==1) or (r.kind=='QuickSlotTooltip' and cfg.QuickSlotTooltip==1)
                if r.kind=='Sprint' and cfg.HideSprintPrompt==1 then
                    local text=promptText(r.label)
                    if type(text)=='string' then
                        text=text:match('^%s*(.-)%s*$'):lower()
                        hide=text=='haste' or text=='sprint'
                    end
                end
                if hide then
                    if actual~=0 then
                        if r.last==nil then r.base=actual end
                        if write(r.w,0) then r.last=0 end
                    end
                elseif r.last~=nil then
                    -- The shared prompt was repurposed. Restore our opacity immediately.
                    if math.abs(actual-r.last)<0.002 then write(r.w,r.base) end
                    r.last=nil
                end
            end
        else rebuild=true end
        end
    end
end
local function scalar(w,key)
    if live(w) then return safe(function() return w[key] end) end
end
local function updateModified()
    modified.Health=false;modified.Stamina=false;modified.Time=false
    local index=scalar(formSwitcher,'ActiveWidgetIndex')
    local form=type(index)=='number' and formOrder[index] or nil
    feeding=false
    if form=='WBP_HUD_VampireStats_C' then
        -- Feeding lives beside GameHUD under the active frontend, not inside it.
        local frontend=rootId:match(' (%S+)%.WBP_GameHUD_C_[^%.]+$')
        for id,w in pairs(feedingWidgets) do
            if not live(w) then feedingWidgets[id]=nil
            elseif frontend and id:find(' '..frontend..'.WBP_HUD_DrinkBlood_C_',1,true) then
                local rendered=safe(function() return w:IsRendered() end)
                local alpha=opacity(w)
                if rendered==true and type(alpha)=='number' and alpha>0.001 then feeding=true;break end
            end
        end
    end
    if cfg.HealthModified==1 then
        for _,bar in ipairs((form and healthBars[form]) or emptyBars) do
            local progress=scalar(bar,'Progress')
            -- Ignore the top 5% of health; allow for float rounding at exactly 95%.
            if type(progress)=='number' and progress>=0 and progress<(0.95-0.000001) then
                modified.Health=true;break
            end
        end
    end
    if cfg.StaminaModified==1 then
        local bar=form and staminaBars[form] or nil
        local progress=scalar(bar,'Progress')
        -- Read only the selected form's inner bar. DWW_StatBar.Progress stayed
        -- constant at 0.5 in the captures and is deliberately NOT used.
        modified.Stamina=type(progress)=='number' and progress>=0 and progress<0.99999
    end
    if cfg.TimeModified==1 then
        local current={
            segment=scalar(timer,'Segment Time'),
            offset=scalar(timer,'BackgroundSegmentOffset'),
            day=scalar(timer,'IsDay'),
            main=scalar(timerBars.MainProgressBar,'Progress'),
            background=scalar(timerBars.BackgroundProgressBar,'Progress')}
        if type(current.main)=='number' and type(current.background)=='number' then
            modified.Time=math.abs(current.main-current.background)>0.0001
        end
        for key,value in pairs(current) do
            local old=previousTimer[key]
            if old~=nil then
                if type(value)=='number' and type(old)=='number' then
                    if math.abs(value-old)>0.0001 then modified.Time=true end
                elseif type(value)=='boolean' and value~=old then modified.Time=true end
            end
        end
        previousTimer=current
    else previousTimer={} end
end
local pc
local function controller()
    if not live(pc) then pc=safe(function() return FindFirstOf('PlayerController') end) end
    return pc
end
local function signals()
    local p=controller()
    local pawn=live(p) and safe(function() return p.Pawn end) or nil
    if not live(pawn) then return nil end
    local part=safe(function() return pawn.CombatComponent end)
    local mode=live(part) and safe(function() return part.CurrentCombatMode end) or nil
    local n=tonumber(mode) or tonumber(tostring(mode):match('(%d+)$'))
    local focus=safe(function() return pawn.bIsInFocusMode end)
    if type(focus)~='boolean' or n==nil then return nil end
    return {focus=focus,stance=n~=0}
end
local function visible(group,state)
    if group=='Health' and feeding then return true end
    if modified[group]==true then return true end
    if state.focus then return cfg[group..'Focus']==1 end
    if state.stance then return cfg[group..'Stance']==1 end
    return cfg[group..'Idle']==1
end
local enemyTicks=0
local configTicks, scanTicks = 0,0
local sampledState
local stateTicks=0
local previousFocus=nil
local DT=0.05
local function acquire()
    local all=safe(function() return FindAllOf('WBP_GameHUD_C') end)
    if type(all)~='table' then return end
    local candidate
    for _,w in pairs(all) do
        if live(w) and not identity(w):find('Default__',1,true) then
            if safe(function() return w:IsInViewport() end)==true or safe(function() return w:IsRendered() end)==true then
                candidate=w;break
            end
            if not candidate then candidate=w end
        end
    end
    if candidate and identity(candidate)~=rootId then
        restore();root=candidate;rootId=identity(candidate);rebuild=true
        pc=nil;previousFocus=nil
    end
end
local function tick()
    configTicks=configTicks+1;scanTicks=scanTicks+1
    if configTicks>=40 then configTicks=0;readConfig() end
    local batch=queue;queue={}
    for _,w in ipairs(batch) do
        if live(w) then
            local c=class(w)
            if c=='WBP_GameHUD_C' then
                restore();root=w;rootId=identity(w);rebuild=true;pc=nil;previousFocus=nil
            elseif c=='WBP_HUD_DrinkBlood_C' then trackFeeding(w)
            elseif c=='WBP_CombatCharacterBar_C' then queueEnemy(w)
            elseif c=='WBP_HUD_Buff_C' then trackCooldownBuff(w)
            elseif classGroups[c] or c=='WBP_HudTimer_C' or c=='WBP_HUD_VampireStats_BloodSegment_C' then rebuild=true end
        end
    end
    enemyTicks=enemyTicks+1
    if enemyTicks>=2 then enemyTicks=0;updateEnemies() end
    if scanTicks>=40 then
        scanTicks=0
        if #records==0 then rebuild=true end
        -- Scan only when the HUD is absent or offscreen, including pooled old roots.
        if not live(root) or safe(function() return root:IsRendered() end)~=true then acquire() end
    end
    if not live(root) then sampledState=nil;stateTicks=0;return end
    local rebuilt=rebuild
    if rebuild then build();rebuild=false end
    -- Sample gameplay and prompt conditions at 10 Hz; animate at 20 Hz.
    stateTicks=stateTicks+1
    if rebuilt or stateTicks>=2 then
        stateTicks=0
        hidePrompts()
        updatePlayerScales()
        updateModified()
        sampledState=signals()
    end
    updateFeedingFades()
    local state=sampledState
    if not state then return end
    local focusChanged=previousFocus~=nil and previousFocus~=state.focus
    previousFocus=state.focus
    for _,r in ipairs(records) do
        if not live(r.w) then rebuild=true
        else
            local actual=opacity(r.w)
            if type(actual)=='number' then
                if r.group~='Health' and r.last~=nil and math.abs(actual-r.last)>0.002 then r.base=actual end
                local show=visible(r.group,state)
                if show then r.hideTime=0;r.immediateHide=false
                else
                    r.hideTime=math.min(1,(r.hideTime or 0)+DT)
                    if state.focus or focusChanged then r.immediateHide=true end
                end
                local target=cfg[r.group..(show and 'VisibleOpacity' or 'HiddenOpacity')]/100
                if not show and not r.immediateHide and r.hideTime<1 then target=r.target end
                if target~=r.target then r.from=r.mult;r.target=target;r.elapsed=0 end
                if cfg.SmoothFade==0 then r.mult=target
                elseif r.mult~=target then
                    r.elapsed=r.elapsed+DT
                    local duration=target<r.from and 0.45 or 0.22
                    local t=math.min(1,r.elapsed/duration)
                    r.mult=r.from+(target-r.from)*(t*t*(3-2*t))
                end
                -- Health opacity is owned by the selected settings, including nonzero hidden opacity.
                local desired=(r.group=='Health') and r.mult or r.base*r.mult
                if math.abs(actual-desired)>0.001 then
                    if write(r.w,desired) then r.last=desired end
                end
            end
        end
    end
end
NotifyOnNewObject('/Script/UMG.UserWidget',function(w)
    if #queue<2048 then queue[#queue+1]=w end
end)
local pending=false
LoopAsync(50,function()
    if not pending then
        pending=true
        ExecuteInGameThread(function()
            local ok,err=pcall(tick)
            pending=false
            if not ok then log('Update failed: '..tostring(err)) end
        end)
    end
    return false
end)
do
-- HUD Widget Diagnostics 1.1. Read-only, manual Shift + F11 capture for the supplied BoD build.
-- All UObject access stays in one game-thread callback; no retained UObject cache.
local PREFIX = '[DynamicHUD] '
local sequence = 0
local function safe(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end
local function live(o)
    return o ~= nil and safe(function() return o:IsValid() end) == true
end
local function name(o)
    if not live(o) then return '<unavailable>' end
    return safe(function() return o:GetFullName() end) or '<unnamed>'
end
local function scalar(v)
    local t = type(v)
    if t == 'number' or t == 'boolean' or t == 'string' then return tostring(v) end
    return '?'
end
-- Engine screen messages are separate from the faded UMG HUD. Some shipping
-- games suppress PrintString internally; a successful call cannot prove display.
local function notify(message, failed)
    print(PREFIX .. message .. '\n')
    local ok, err = pcall(function()
        local ksl = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
        local pc = FindFirstOf('PlayerController')
        if not live(ksl) or not live(pc) then error('notification context unavailable') end
        local colour = failed and {R=1, G=0.25, B=0.2, A=1}
            or {R=0.25, G=1, B=0.55, A=1}
        ksl:PrintString(pc, 'HUD Diagnostics: ' .. message, true, false,
            colour, 10.0, FName('None'))
    end)
    if not ok then print(PREFIX .. 'Screen notification unavailable: ' .. tostring(err) .. '\n') end
end
local paths = {
    'ue4ss/Mods/DynamicHUD/HUD-Widget-Dump.txt',
    'Mods/DynamicHUD/HUD-Widget-Dump.txt',
    'DynamicHUD/HUD-Widget-Dump.txt',
    'HUD-Widget-Dump.txt',
}
local function capture()
    sequence = sequence + 1
    local lines, seen, count = {}, {}, 0
    local function emit(s) lines[#lines + 1] = s end
    emit(('=== HUD Widget Diagnostics 1.1 | capture %d | %s ==='):format(sequence, os.date('%Y-%m-%d %H:%M:%S')))
    emit('Read-only snapshot. ? = unavailable. Visibility/opacity are local values, not effective ancestor visibility.')
    emit('Nested WidgetTree and panel-child edges are labelled below. Objects may be pooled/offscreen.')
    local function walk(w, depth, edge)
        if not live(w) then return end
        if count >= 5000 then return end
        local id = name(w)
        local pad = string.rep('  ', depth)
        if seen[id] then emit(pad .. edge .. ' -> [already listed] ' .. id); return end
        seen[id] = true
        count = count + 1
        local parent = safe(function() return w:GetParent() end)
        emit(pad .. edge .. ' ' .. id)
        emit(pad .. '  visibility=' .. scalar(safe(function() return w.Visibility end))
            .. ' opacity=' .. scalar(safe(function() return w.RenderOpacity end))
            .. ' bShown=' .. scalar(safe(function() return w.bShown end))
            .. ' percent=' .. scalar(safe(function() return w.Percent end)))
        emit(pad .. '  parent=' .. name(parent))
        local text = safe(function() return w.Text:ToString() end)
        if type(text)=='string' and text~='' then emit(pad .. '  text=' .. string.format('%q',text)) end
        if depth >= 40 then emit(pad .. '  [depth limit]'); return end
        -- UserWidget boundaries have a separate WidgetTree, not panel children.
        local tree = safe(function() return w.WidgetTree end)
        if live(tree) then
            local top = safe(function() return tree.RootWidget end)
            if live(top) then walk(top, depth + 1, 'WidgetTree.RootWidget') end
        end
        local n = safe(function() return w:GetChildrenCount() end)
        if type(n) == 'number' and n > 0 then
            for i = 0, math.min(n, 512) - 1 do
                local child = safe(function() return w:GetChildAt(i) end)
                walk(child, depth + 1, 'Child[' .. i .. ']')
            end
            if n > 512 then emit(pad .. '  [child limit]') end
        end
    end
    -- Only manual captures scan the object array. Roots first, then other loaded
    -- UserWidgets so sibling HUDs and independently hosted elements are included.
    local roots = safe(function() return FindAllOf('WBP_GameHUD_C') end)
    emit('\n--- Game HUD roots ---')
    if type(roots) == 'table' then
        for _, w in pairs(roots) do walk(w, 0, 'HUD') end
    else emit('No WBP_GameHUD_C instance found. Capture after loading into gameplay.') end
    emit('\n--- Other loaded UserWidgets (including pooled widgets) ---')
    local widgets = safe(function() return FindAllOf('UserWidget') end)
    if type(widgets) == 'table' then
        for _, w in pairs(widgets) do
            if live(w) and not seen[name(w)] then walk(w, 0, 'UserWidget') end
        end
    else emit('UserWidget scan unavailable or empty.') end
    emit(('\nUnique widgets: %d%s'):format(count, count >= 5000 and ' [capture limit reached]' or ''))
    emit('=== END CAPTURE ===\n')
    local payload = table.concat(lines, '\n') .. '\n'
    for _, path in ipairs(paths) do
        local f = io.open(path, 'a')
        if f then
            local ok, err = pcall(function()
                assert(f:write(payload))
                assert(f:flush())
            end)
            f:close()
            if ok then
                notify('Capture ' .. sequence .. ' saved (' .. count .. ' widgets): ' .. path)
                return
            end
            print(PREFIX .. 'Write failed: ' .. tostring(err) .. '\n')
        end
    end
    notify('File write failed. Capture is in UE4SS.log.', true)
    print(PREFIX .. payload)
end
local function captureHealthDecision()
    log('---- HEALTH DECISION CAPTURE ----')
    local state=signals()
    local index=safe(function() return formSwitcher.ActiveWidgetIndex end)
    log('Root='..rootId..' ActiveWidgetIndex='..tostring(index)..' Form='..tostring(formOrder[index]))
    log('State='..(state and (state.focus and 'Focus' or (state.stance and 'Stance' or 'Idle')) or 'Unavailable')
        ..' CachedModified='..tostring(modified.Health))
    for _,key in ipairs({'HealthModified','HealthIdle','HealthFocus','HealthStance','HealthVisibleOpacity','HealthHiddenOpacity'}) do
        log(key..'='..tostring(cfg[key]))
    end
    for form,bars in pairs(healthBars) do
        for _,bar in ipairs(bars) do
            local progress=safe(function() return bar.Progress end)
            log('HealthSource '..form..' '..identity(bar)..' Progress='
                ..(type(progress)=='number' and string.format('%.17g',progress) or tostring(progress)))
        end
    end
    for _,r in ipairs(records) do
        if r.group=='Health' then
            log('HealthTarget '..identity(r.w)..' Actual='..tostring(opacity(r.w))
                ..' Base='..tostring(r.base)..' Multiplier='..tostring(r.mult)
                ..' Target='..tostring(r.target)..' HideTime='..tostring(r.hideTime))
        end
    end
    log('---- END HEALTH DECISION CAPTURE ----')
end
RegisterKeyBind(Key.F11, {ModifierKey.SHIFT}, function()
    print(PREFIX .. 'Shift + F11 requested; waiting for game-thread capture.\n')
    ExecuteInGameThread(function()
        local healthOk,healthError=pcall(captureHealthDecision)
        if not healthOk then log('Health capture failed: '..tostring(healthError)) end
        notify('Shift + F11 received - capturing widgets...')
        local ok, err = pcall(capture)
        if not ok then notify('Capture failed. Check UE4SS.log.', true)
            print(PREFIX .. tostring(err) .. '\n') end
    end)
end)
print(PREFIX .. 'Dynamic HUD 1.0 by Koriik loaded. Shift + F11: widget dump.\n')


end
