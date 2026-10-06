-- MIT. Small scalar opacity leases. Identity capture and cleanup are sliced by
-- the HUD worker; a reveal can change its already bound panels in one frame.
local M = {}
function M.new(Session, D)
    local leases, count = {}, 0
    local function equal(a,b) return type(a)=='number' and math.abs(a-b)<=1e-5 end
    local function identity(entry)
        local object=entry.object
        if not object:IsValid() then return false end
        local class=object:GetClass()
        return class:IsValid() and class:GetAddress()==entry.class
            and object:GetFullName()==entry.name
    end
    local function restore(entry)
        if entry.last==nil or not identity(entry) then return false end
        local current=entry.object:GetRenderOpacity()
        if not equal(current,entry.last) or equal(current,entry.original) then return false end
        entry.object:SetRenderOpacity(entry.original)
        assert(equal(entry.object:GetRenderOpacity(),entry.original),'Panel opacity restore readback failed')
        entry.last=nil
        return true
    end
    local api={}
    function api.bind(object)
        local address=object:GetAddress()
        local entry=leases[address]
        local class=object:GetClass()
        if not class:IsValid() then return end
        local classAddress,name=class:GetAddress(),object:GetFullName()
        if entry and entry.class==classAddress and entry.name==name and identity(entry) then return entry end
        if count>=256 then error('Panel opacity owner limit reached') end
        entry={object=object,class=classAddress,name=name}
        leases[address]=entry;count=count+1
        -- One owner per cleanup slice; no shared-library journal is modified.
        Session.onClose(function()
            local ok,err=pcall(restore,entry)
            if not ok and D.debugLogging then D.event('panelRestore','%s',tostring(err)) end
        end)
        return entry
    end
    function api.apply(entry,value)
        assert(entry and identity(entry),'Panel opacity owner changed')
        local object=entry.object
        local current=object:GetRenderOpacity()
        if equal(current,value) then return false end
        if entry.last==nil or not equal(current,entry.last) then entry.original=current end
        entry.last=value
        object:SetRenderOpacity(value)
        assert(equal(object:GetRenderOpacity(),value),'Panel opacity write readback failed')
        return true
    end
    -- A completed mediated Vanilla transition has reached the stock target.
    -- Treat that target as the stable external value, rather than restoring an
    -- intermediate stock animation sample if the session later closes.
    function api.commit(entry,value)
        assert(entry and identity(entry),'Panel opacity owner changed')
        entry.original=value
        entry.last=value
    end
    api.restore=restore
    return api
end
return M
