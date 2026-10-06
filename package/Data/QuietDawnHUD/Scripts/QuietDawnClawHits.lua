-- Quiet Dawn - Configurable HUD. MIT.
-- Ordinary claw hits spawn this system directly, outside the Shred cues.
local M={}
function M.new(D,session,context)
    local hook='/Script/Niagara.NiagaraFunctionLibrary:SpawnSystemAtLocation'
    local effect='NiagaraSystem /Game/_Dawnwalker/VFX/03_BloodCombat/NS_BloodTrailClaws_01.NS_BloodTrailClaws_01'
    local weaponClass='BlueprintGeneratedClass /Game/_Dawnwalker/Blueprints/Items/HandToHand/BP_Weapon_VampireClaws.BP_Weapon_VampireClaws_C'
    local enabled,ready,pending,attempts=true,false,true,0
    local records,slots,nextSlot={},{},1
    local function valid(o) return o~=nil and o:IsValid() end
    local function same(a,b) return valid(a) and valid(b) and a:GetAddress()==b:GetAddress() end
    local function report(message)
        if D.debugLogging then D.event('clawHits','%s',message) end
    end
    local function identity(r)
        local c=r.component
        return valid(c) and c:GetAddress()==r.address and c:GetFullName()==r.name
            and same(c:GetClass(),r.class) and same(c:GetWorld(),r.world)
            and valid(c:GetAsset()) and c:GetAsset():GetFullName()==effect
    end
    local function restore(r)
        if not r.active then return end
        if identity(r) and r.component.bHiddenInGame==true then
            r.component:SetHiddenInGame(r.original,false)
            assert(r.component.bHiddenInGame==r.original,'Claw hit visibility restore failed')
            if D.debugLogging then D.count('clawHitRestores') end
        end
        r.active=false
    end
    local function spawned(_,result,worldContext,template)
        -- UE4SS native post callbacks pass the return value SECOND, followed by
        -- the original arguments. Never replace that return: the weapon keeps it.
        if not enabled and #records==0 then return end
        local system=template:get()
        if not valid(system) or system:GetFullName()~=effect then return end
        if D.debugLogging then D.count('clawHitSpawns') end
        local component=result:get()
        if not valid(component) or not same(component:GetAsset(),system) then return end
        local address=component:GetAddress()
        local slot=slots[address]
        local previous=slot and records[slot]
        -- AutoRelease reuses components. Release our previous visibility before
        -- classifying this spawn, including Off and a different weapon/owner.
        if previous then restore(previous) end
        if not enabled then return end
        local weapon=worldContext:get()
        if not valid(weapon) or not valid(weapon:GetClass())
            or weapon:GetClass():GetFullName()~=weaponClass or weapon:HasAnyFlags(0x3610) then return end
        local pawn,world=context()
        if not valid(pawn) or not valid(world) or not same(weapon:GetOwner(),pawn)
            or not same(weapon:GetWorld(),world) or not same(pawn:GetWorld(),world)
            or not same(component:GetWorld(),world) then
            if D.debugLogging then D.count('clawHitOwnerMisses');report('claw hit skipped: current player/world ownership unavailable') end
            return
        end
        local hidden=component.bHiddenInGame
        assert(type(hidden)=='boolean','Claw hit hidden flag unavailable')
        if hidden then return end -- preserve visibility owned by the game/another mod
        if not slot then
            slot=#records+1
            if slot>64 then
                slot=nextSlot;nextSlot=nextSlot%64+1
                restore(records[slot])
                slots[records[slot].address]=nil
            else
                local cleanupSlot=slot
                session.onClose(function()
                    local ok=pcall(restore,records[cleanupSlot])
                    if not ok then report('cosmetic restore unavailable') end
                end)
            end
        end
        local r={component=component,address=address,name=component:GetFullName(),class=component:GetClass(),
            world=world,original=hidden,active=true}
        records[slot]=r;slots[address]=slot
        -- The native spawn has finished on the game thread; hide before the
        -- weapon resumes, without delaying until a worker frame or stopping it.
        component:SetHiddenInGame(true,false)
        assert(component.bHiddenInGame==true,'Claw hit visibility write failed')
        if D.debugLogging then D.count('clawHitWrites') end
        report('ordinary vampire claw hit marks hidden')
    end
    local callback=D.wrap('clawHits',function(...)
        local ok,err=pcall(spawned,...)
        if not ok and D.debugLogging then D.count('clawHitFailures');report('spawn unavailable: '..tostring(err)) end
        -- No Lua return value: preserve the Niagara component returned to stock.
    end)
    local self={}
    function self.configure(value)
        enabled=value==true;pending=enabled and not ready;attempts=0
        for _,r in ipairs(records) do r.restorePending=not enabled and r.active end
    end
    function self.pending()
        if pending then return true end
        for _,r in ipairs(records) do if r.restorePending then return true end end
        return false
    end
    function self.step()
        for _,r in ipairs(records) do
            if r.restorePending then
                r.restorePending=false
                local ok=pcall(restore,r)
                if not ok then report('cosmetic restore unavailable') end
                return
            end
        end
        if not pending then return end
        attempts=attempts+1
        local ok,pre,post=pcall(function()
            local fn=StaticFindObject(hook)
            assert(valid(fn) and fn:GetFullName()=='Function '..hook
                and (fn:GetFunctionFlags() & 0x400)~=0,'Native Niagara spawn function unavailable')
            return RegisterHook(hook,function()end,callback)
        end)
        ready=ok and type(pre)=='number' and type(post)=='number'
        if ready or attempts>=8 then
            pending=false
            if ready then report('ordinary claw hit hook ready')
            elseif D.debugLogging then report('ordinary claw hit hook unavailable; Shred filtering remains active: '..hook..' '..tostring(pre)) end
        end
    end
    return self
end
return M
