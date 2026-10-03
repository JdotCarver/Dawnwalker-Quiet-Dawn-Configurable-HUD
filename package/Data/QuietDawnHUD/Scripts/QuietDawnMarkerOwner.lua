-- MIT. Missing reflected methods can be truthy invalid userdata in UE4SS.
-- Inspect them without calling them; construction and replacement can precede
-- reflected readiness. The caller owns the finite retry budget.
local M = {}
local function method(object,name)
    local value=object[name]
    if type(value)=='function' then return value end
    if type(value)=='userdata' and value:type()=='UFunction' and value:IsValid() then return value end
end
function M.read(object)
    local ok,world,owner=pcall(function()
        if object==nil or not object:IsValid() then return end
        local getWorld=method(object,'GetWorld')
        local getOwner=method(object,'GetOwningPlayer')
        if not getWorld or not getOwner then return end
        return getWorld(object),getOwner(object)
    end)
    if ok then return world,owner end
end
return M
