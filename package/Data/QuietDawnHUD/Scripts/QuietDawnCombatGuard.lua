-- Quiet Dawn - Configurable HUD. MIT.
-- The native observer owns same-frame presentation. Discovery, settings and
-- cleanup enter through the existing registered game-thread Session worker.
local M={}
function M.new(config,D,session)
    local available=type(_QDNCuesVersion)=='function' and type(_QDNCuesConfigure)=='function'
        and type(_QDNCuesApply)=='function' and type(_QDNCuesRelease)=='function'
        and type(_QDNCuesStop)=='function' and type(_QDNCuesStats)=='function'
    if available then local ok,version=pcall(_QDNCuesVersion);available=ok and version==1 end
    local ready,warned=false,false
    local self={}
    local function warn(reason)
        if warned then return end
        warned=true
        D.logWarning('Same-frame combat icon guard unavailable: %s. Deferred icon recovery remains active.',tostring(reason))
    end
    function self.configure()
        ready=false
        if not available then warn('matching native combat guard API is missing');return end
        local options=(config.showEnemyMarker and 1 or 0)+(config.showLockIcon and 2 or 0)
            +(config.showDirectionalParry and 4 or 0)+(config.showUnblockableWarning and 8 or 0)
            +(config.showCounterattackDirection and 16 or 0)
        local ok,reason=pcall(_QDNCuesConfigure,options,config.logLevel or 2)
        ready=ok
        if not ok then warn(reason) end
    end
    function self.reset()
        if available then _QDNCuesStop() end
        self.configure()
    end
    function self.apply(object,entry)
        if not ready then return false end
        local address=object:GetAddress()
        local ok,applied,shown,token=pcall(_QDNCuesApply,address,entry.original)
        if not ok or applied~=true or type(token)~='number' then
            warn(ok and 'native presentation was not ready' or applied)
            return false
        end
        if entry.cueGuardToken~=token then
            entry.cueGuardToken=token
            -- One marker per Session cleanup slice. Tokens prevent an old
            -- widget's cleanup from releasing a reused address/zero serial.
            session.onClose(function() _QDNCuesRelease(address,token) end)
        end
        return true,shown==true
    end
    session.onClose(function()
        if not available then return end
        if D.debugLogging then
            local events,paints,writes,repairs,failures,stale,ms,setupMs=_QDNCuesStats()
            D.logInfo('Combat icon guard: events=%d paints=%d writes=%d sizeRepairs=%d failures=%d stale=%d paintMs=%.3f setupMs=%.3f',
                events,paints,writes,repairs,failures,stale,ms,setupMs)
        end
        _QDNCuesStop()
        ready=false
    end)
    self.configure()
    return self
end
return M
