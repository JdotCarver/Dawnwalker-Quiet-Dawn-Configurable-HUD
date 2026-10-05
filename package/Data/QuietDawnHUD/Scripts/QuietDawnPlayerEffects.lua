-- Quiet Dawn - Configurable HUD. MIT.
-- Exact Crimson Rush cue actors only. Hide their existing Niagara component;
-- the cue, attribute listeners, audio and gameplay effect continue normally.
local M={}
function M.new(D,session,wake,context)
    local root='/Game/_Dawnwalker/Stats/GameplayCues/CrimsonRush/'
    local effect='NiagaraSystem /Game/_Dawnwalker/VFX/03_CrimsonRush/NS_CrimsonRush_B.NS_CrimsonRush_B'
    local types={}
    for _,name in ipairs({'GC_CrimsonRushBuff_Human','GC_CrimsonRushBuff_Vampire'}) do
        types[#types+1]={path=root..name..'.'..name..'_C',pending=true,attempts=0}
    end
    local enabled=true
    local queue,records={},{}
    local slots,cleanupSlots,nextSlot={},0,1
    local library
    local activationHook='/Script/GameplayAbilities.GameplayCueNotify_Actor:WhileActive'
    local hookReady,hookPending,hookAttempts=false,true,0
    local function valid(o) return o~=nil and o:IsValid() end
    local function same(a,b) return valid(a) and valid(b) and a:GetAddress()==b:GetAddress() end
    local function report(message)
        if D.debugLogging then D.event('playerEffects','%s',message) end
    end
    local function enqueue(object,spec)
        for _,item in ipairs(queue) do if item.object==object then return end end
        if #queue>=32 then return end
        queue[#queue+1]={object=object,spec=spec,attempts=0}
    end
    local function owned(record)
        return valid(record.component) and record.component:GetFullName()==record.name
            and same(record.component:GetClass(),record.class)
            and valid(record.cue) and same(record.cue.DurationEffectComponent,record.component)
            and valid(record.component:GetAsset()) and record.component:GetAsset():GetFullName()==effect
            and same(record.component:GetAttachParent(),record.parent)
            and same(record.parent:GetOwner(),record.pawn)
            and same(record.cue:GetWorld(),record.world)
    end
    local function restore(record)
        if not record.active then return end
        if owned(record) and record.component.bHiddenInGame==true then
            record.component:SetHiddenInGame(record.original,false)
            assert(record.component.bHiddenInGame==record.original,'Player effect visibility restore failed')
        end
        record.active=false
    end
    local function remember(record,address)
        local index=#records+1
        if index>32 then
            index=nextSlot;nextSlot=nextSlot%32+1
            local previous=records[index]
            if owned(previous) and previous.active then return false end
            if slots[previous.address]==index then slots[previous.address]=nil end
        end
        record.address=address;records[index]=record;slots[address]=index
        if index>cleanupSlots then
            cleanupSlots=index
            session.onClose(function()
                local ok=pcall(restore,records[index])
                if not ok then report('cosmetic restore unavailable') end
            end)
        end
        return true
    end
    local function apply(item)
        local cue=item.object
        if not valid(cue) then return true end
        local class=cue:GetClass()
        if not valid(class) then return true end
        local className=class:GetFullName()
        if not item.spec then
            for _,spec in ipairs(types) do
                if className=='BlueprintGeneratedClass '..spec.path then item.spec=spec;break end
            end
        end
        if not item.spec or className~='BlueprintGeneratedClass '..item.spec.path then return true end
        if cue:HasAnyFlags(0x3610) then return false end -- CDO/loading flags
        local pawn,world=context()
        if not valid(pawn) or not valid(world) then return false end
        if not same(cue:GetWorld(),world) then return true end
        local component=cue.DurationEffectComponent
        if not valid(component) then return false end
        local asset=component:GetAsset()
        if not valid(asset) or asset:GetFullName()~=effect then return true end
        local parent=component:GetAttachParent()
        if not valid(parent) or not same(parent:GetOwner(),pawn) then return true end
        local address=component:GetAddress()
        local found=slots[address] and records[slots[address]]
        if found and not owned(found) then slots[address]=nil;found=nil end
        if found and found.active and component.bHiddenInGame==true then return true end
        local hidden=component.bHiddenInGame
        if type(hidden)~='boolean' then error('Player effect hidden flag unavailable') end
        if hidden then return true end
        if not found then
            found={component=component,cue=cue,name=component:GetFullName(),class=component:GetClass(),original=hidden,
                parent=parent,pawn=pawn,world=world}
            if not remember(found,address) then return false end
        end
        found.active=true -- also covers a setter which mutates then throws
        component:SetHiddenInGame(true,false)
        assert(component.bHiddenInGame==true,'Player effect visibility write failed')
        if D.debugLogging then D.count('playerEffectWrites') end
        report('Crimson Rush arm effect hidden')
        return true
    end
    for _,spec in ipairs(types) do
        local ok=pcall(NotifyOnNewObject,spec.path,function(object)
            if not enabled then return end
            enqueue(object,spec);wake()
        end)
        if not ok then report('cue construction notification unavailable') end
    end
    local self={}
    function self.configure(value)
        enabled=value==true;queue={}
        hookPending=enabled and not hookReady;hookAttempts=0
        for _,spec in ipairs(types) do spec.pending=enabled;spec.attempts=0 end
        if not enabled then
            for _,record in ipairs(records) do if record.active then record.restorePending=true end end
        else
            for _,record in ipairs(records) do record.restorePending=false end
        end
    end
    function self.recover()
        if enabled then
            hookPending=not hookReady;hookAttempts=0
            for _,spec in ipairs(types) do spec.pending=true;spec.attempts=0 end
        end
    end
    function self.pending()
        if hookPending then return true end
        for _,record in ipairs(records) do if record.restorePending then return true end end
        for _,spec in ipairs(types) do if spec.pending then return true end end
        return #queue>0
    end
    function self.step()
        for _,record in ipairs(records) do
            if record.restorePending then
                record.restorePending=false
                local ok=pcall(restore,record)
                if not ok then report('cosmetic restore unavailable') end
                return
            end
        end
        if hookPending then
            hookAttempts=hookAttempts+1
            -- The two Blueprint WhileActive overrides call this native parent.
            -- Its post hook also covers pooled actors and replacement components.
            -- Read only the owned context wrapper here; classify in the worker.
            local ok,pre,post=pcall(RegisterHook,activationHook,function()end,function(ctx)
                if not enabled then return end
                local success,object=pcall(function()return ctx:get()end)
                if success and object then
                    if D.debugLogging then D.count('playerEffectActivationEvents') end
                    enqueue(object);wake()
                else report('activation context unavailable') end
            end)
            hookReady=ok and type(pre)=='number' and type(post)=='number'
            if hookReady or hookAttempts>=8 then
                hookPending=false
                if not hookReady then report('activation hook unavailable; construction and Apply remain active') end
            end
            return
        end
        -- One exact actor-class query per slice, only at enablement/HUD recovery.
        -- GameplayStatics uses the actor class index, not the global UObject array.
        for _,spec in ipairs(types) do
            if spec.pending then
                spec.attempts=spec.attempts+1
                local ok,done=pcall(function()
                    local pawn,world=context()
                    if not valid(pawn) or not valid(world) then return false end
                    local class=StaticFindObject(spec.path)
                    if not valid(class) then return true end -- construction recovers absence
                    if not valid(library) then library=StaticFindObject('/Script/Engine.Default__GameplayStatics') end
                    if not valid(library) then return false end
                    local actors={};library:GetAllActorsOfClass(world,class,actors)
                    for index=1,math.min(#actors,32) do enqueue(actors[index],spec) end
                    if D.debugLogging then D.count('playerEffectDiscoveries') end
                    return true
                end)
                if (ok and done) or spec.attempts>=8 then
                    spec.pending=false
                    if not ok then report('cue discovery unavailable; waiting for lifecycle/Apply') end
                end
                return
            end
        end
        local item=table.remove(queue,1)
        if not item then return end
        item.attempts=item.attempts+1
        local ok,done=pcall(apply,item)
        if not (ok and done) and item.attempts<8 then queue[#queue+1]=item
        elseif not (ok and done) then report('cue component unavailable; waiting for lifecycle/Apply') end
    end
    self.step=D.wrap('playerEffects',self.step)
    return self
end
return M
