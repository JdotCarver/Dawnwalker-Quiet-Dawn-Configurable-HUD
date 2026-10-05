-- Quiet Dawn - Configurable HUD. MIT.
-- Two exact cue classes, including cue objects created before the defaults
-- were changed. No per-hit hooks or recurring discovery.
local M = {}
function M.new(D, session, wake)
    local root='/Game/_Dawnwalker/Stats/GameplayCues/Shred/'
    local effects='/Game/_Dawnwalker/VFX/03_ShreddedTouch/'
    local entries={
        {name='GC_ShredBleedingInflicted',effect='NS_Shred_Slash'},
        {name='GC_ShredBleedingInflicted_Sword',effect='NS_Shred_Sword'},
    }
    local cursor,enabled,registry=1,true,nil
    local instances,instanceQueue={},{}
    local instanceSlots,cleanupSlots,nextSlot={},0,1
    local retained=type(_QDNClawRetain)=='function' and type(_QDNClawRelease)=='function'
    local function valid(o) return o~=nil and o:IsValid() end
    local function matches(o,name) return valid(o) and o:GetFullName()==name end
    local function enqueue(entry,object)
        for _,item in ipairs(instanceQueue) do if item.object==object then return end end
        if #instanceQueue<64 then instanceQueue[#instanceQueue+1]={entry=entry,object=object,attempts=0} end
    end
    local function report(entry,message)
        if D.debugLogging and not entry.warned then
            entry.warned=true;D.event('clawMarks','cue=%s %s',entry.name,message)
        end
    end
    local function release(entry,record)
        if record.token then
            _QDNClawRelease(entry.slot,record.token);record.token=nil
            if D.debugLogging then D.count('clawMarkReleases') end
        end
    end
    local function restore(entry,record)
        if not record.owned then release(entry,record);return true end
        if not record.same() or valid(record.object.OneShotEffect) then
            record.owned=false;release(entry,record);return true
        end
        local effect=record.effect
        if not matches(effect,'NiagaraSystem '..entry.effectPath) then effect=LoadAsset(entry.effectPath) end
        assert(matches(effect,'NiagaraSystem '..entry.effectPath),'Claw marks original effect unavailable')
        record.object.OneShotEffect=effect
        assert(matches(record.object.OneShotEffect,'NiagaraSystem '..entry.effectPath),'Claw marks restore failed')
        record.owned=false;entry.applied=nil;release(entry,record)
        if D.debugLogging then D.count('clawMarkRestores') end
        return true
    end
    local function apply(entry,object)
        if not matches(object,entry.fullName) then return false end
        local class=object:GetClass()
        if not matches(class,'BlueprintGeneratedClass '..entry.classPath) then return false end
        -- Construction alone is not evidence that serialization has finished.
        if object:HasAnyFlags(0x3600) or class:HasAnyFlags(0x3600) then return false end
        local effect=object.OneShotEffect
        local record=entry.record
        if record and record.same() and record.owned and not valid(effect) then return true end
        if not matches(effect,'NiagaraSystem '..entry.effectPath) then return false end
        local classAddress=class:GetAddress()
        if not record or not record.same() then
            record={object=object,effect=effect,owned=false}
            entry.record=record
            record.same=function()
                return matches(object,entry.fullName) and matches(object:GetClass(),'BlueprintGeneratedClass '..entry.classPath)
                    and object:GetClass():GetAddress()==classAddress
            end
            session.onClose(function()
                -- An unavailable cosmetic restore must not strand every HUD
                -- setting. Native retention keeps the normal original alive.
                local ok,err=pcall(restore,entry,record)
                if not ok then
                    if D.debugLogging then report(entry,'cleanup failed: '..tostring(err)) end
                    pcall(release,entry,record)
                end
            end)
        end
        record.effect=effect
        -- Retain BEFORE clearing the only hard reference. A failed retain
        -- leaves the original effect untouched and retries finitely.
        if retained and not record.token then
            record.token=_QDNClawRetain(entry.slot,object:GetAddress(),effect:GetAddress())
            assert(type(record.token)=='number' and record.token>0,'Claw asset retention unavailable')
            if D.debugLogging then D.count('clawMarkRetains') end
        end
        record.owned=true -- also covers a setter that mutates then throws
        object.OneShotEffect=nil
        assert(not valid(object.OneShotEffect),'Claw marks write readback failed')
        entry.applied=object
        if D.debugLogging then D.count('clawMarkWrites');D.event('clawMarks','cue=%s hidden',entry.name) end
        return true
    end
    local function prepare(entry)
        -- Same UE5 AssetRegistryHelpers route as the pinned UE4SS Blueprint
        -- loader. Suppression follows synchronous load in this atomic slice.
        if not valid(registry) then registry=StaticFindObject('/Script/AssetRegistry.Default__AssetRegistryHelpers') end
        if not valid(registry) then return nil end
        if not entry.packageName then
            entry.packageName=FName(root..entry.name);entry.assetName=FName(entry.name..'_C')
        end
        if D.debugLogging then D.count('clawMarkPreloads') end
        local class=registry:GetAsset({PackageName=entry.packageName,AssetName=entry.assetName})
        if not matches(class,'BlueprintGeneratedClass '..entry.classPath) then return nil end
        return class:GetCDO()
    end
    local function applyInstance(entry,object)
        if not valid(object) then return true end
        local class=object:GetClass()
        if not matches(class,'BlueprintGeneratedClass '..entry.classPath) then return true end
        if matches(object,entry.fullName) then return true end
        if object:HasAnyFlags(0x3600) or class:HasAnyFlags(0x3600) then return false end
        -- The default owns native retention of the original system. Do not
        -- clear another reference if its preparation/retention failed.
        if not entry.record or not entry.record.owned or not entry.record.same() then return false end
        local effect=object.OneShotEffect
        if not valid(effect) then return true end
        if not matches(effect,'NiagaraSystem '..entry.effectPath) then return true end
        local name,address,classAddress=object:GetFullName(),object:GetAddress(),class:GetAddress()
        local slot=instanceSlots[address]
        local record=slot and instances[slot].record
        if record and not record.same() then instanceSlots[address]=nil;record=nil end
        if not record then
            slot=#instances+1
            if slot>64 then
                slot=nextSlot;nextSlot=nextSlot%64+1
                local previous=instances[slot]
                if previous.record.same() and previous.record.owned then return false end
                if instanceSlots[previous.address]==slot then instanceSlots[previous.address]=nil end
            end
            record={object=object,effect=effect,owned=false}
            record.same=function()
                return matches(object,name) and object:GetAddress()==address
                    and matches(object:GetClass(),'BlueprintGeneratedClass '..entry.classPath)
                    and object:GetClass():GetAddress()==classAddress
            end
            instances[slot]={entry=entry,record=record,address=address};instanceSlots[address]=slot
            if slot>cleanupSlots then
                cleanupSlots=slot
                session.onClose(function()
                    local item=instances[slot]
                    local ok=pcall(restore,item.entry,item.record)
                    if not ok then report(item.entry,'cue instance restore unavailable') end
                end)
            end
        end
        record.effect=effect;record.owned=true
        object.OneShotEffect=nil
        assert(not valid(object.OneShotEffect),'Claw instance write readback failed')
        if D.debugLogging then D.count('clawInstanceWrites');D.event('clawMarks','cue=%s instance hidden',entry.name) end
        return true
    end
    for i,entry in ipairs(entries) do
        entry.slot=i;entry.classPath=root..entry.name..'.'..entry.name..'_C'
        entry.path=root..entry.name..'.Default__'..entry.name..'_C'
        entry.fullName=entry.name..'_C '..entry.path;entry.effectPath=effects..entry.effect..'.'..entry.effect
        entry.pending=true;entry.attempts=0;entry.discover=true
        local ok=pcall(NotifyOnNewObject,entry.classPath,function(object)
            -- Resolve the exact default; an instance cannot displace it.
            -- Bursts mark one slot dirty. Construction performs no native reads.
            if not enabled or entry.preparing then return end
            enqueue(entry,object)
            if entry.pending then wake();return end
            entry.pending=true;entry.attempts=0;entry.preloaded=false;entry.object=nil;entry.warned=nil;wake()
        end)
        if not ok then report(entry,'construction notification unavailable') end
    end
    local self={}
    function self.configure(value)
        enabled=value==true
        instanceQueue={}
        for _,item in ipairs(instances) do item.restorePending=not enabled and item.record.owned or false end
        for _,entry in ipairs(entries) do
            entry.pending=enabled;entry.attempts=0;entry.preloaded=false;entry.object=nil;entry.warned=nil
            entry.restorePending=not enabled and entry.record and (entry.record.owned or entry.record.token) or false
            entry.discover=enabled
        end
    end
    function self.pending()
        for _,item in ipairs(instances) do if item.restorePending then return true end end
        if #instanceQueue>0 then return true end
        for _,entry in ipairs(entries) do if entry.discover or entry.restorePending or entry.pending then return true end end
        return false
    end
    function self.step()
        -- Restore instances before releasing the original asset's default lease.
        for _,item in ipairs(instances) do
            if item.restorePending then
                item.restorePending=false
                local ok=pcall(restore,item.entry,item.record)
                if not ok then report(item.entry,'cue instance restore unavailable') end
                return
            end
        end
        for _=1,#entries do
            local entry=entries[cursor];cursor=cursor%#entries+1
            if entry.restorePending or entry.pending then
                entry.attempts=entry.attempts+1
                local ok,done=pcall(function()
                    if entry.restorePending then return restore(entry,entry.record) end
                    local object=entry.object or (entry.record and entry.record.object)
                    if not valid(object) then
                        object=StaticFindObject(entry.path)
                        if D.debugLogging then D.count('clawMarkLookups') end
                    end
                    entry.object=object
                    if apply(entry,object) then return true end
                    if not entry.preloaded then
                        entry.preloaded=true;entry.preparing=true
                        local loaded,result=pcall(prepare,entry);entry.preparing=false
                        if not loaded then error(result) end
                        if valid(result) then entry.object=result;return apply(entry,result) end
                        if not valid(object) then
                            report(entry,'asset unavailable; waiting for lifecycle/Apply')
                            return true -- cache absence until a relevant event
                        end
                    end
                    return false
                end)
                if ok and done then entry.pending=false;entry.restorePending=false
                elseif entry.attempts>=8 then
                    entry.pending=false;entry.restorePending=false
                    if D.debugLogging then report(entry,ok and 'asset unavailable; waiting for lifecycle/Apply'
                        or 'operation failed: '..tostring(done)) end
                end
                return -- one cue per existing worker frame; no idle timer
            end
        end
        for _,entry in ipairs(entries) do
            if entry.discover then
                entry.discover=false
                -- One snapshot per exact class on enablement; construction
                -- notifications cover later objects. Never repeat while idle.
                local ok,objects=pcall(FindAllOf,entry.name..'_C')
                if ok and type(objects)=='table' then
                    for index=1,math.min(#objects,64) do enqueue(entry,objects[index]) end
                    if D.debugLogging then D.count('clawInstanceDiscoveries') end
                else report(entry,'existing cue discovery unavailable') end
                return
            end
        end
        local item=table.remove(instanceQueue,1)
        if item then
            item.attempts=item.attempts+1
            local ok,done=pcall(applyInstance,item.entry,item.object)
            if not (ok and done) and item.attempts<8 then instanceQueue[#instanceQueue+1]=item
            elseif not (ok and done) then report(item.entry,'cue instance unavailable; waiting for lifecycle/Apply') end
        end
    end
    self.step=D.wrap('clawMarks',self.step)
    return self
end
return M
