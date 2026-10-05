-- QuietDawnDiagnostics.lua
-- MIT License. HUD-specific observations stay local; diagnostics are shared.
--
-- This file is the level-aware layer over UE4SSCommonDiagnostics. The shared
-- library is vendored from github.com/my-mods/ue4ss-common and pinned by
-- sha256, so it still speaks a single `debugLogging` boolean. Levels therefore
-- live here: the library is switched on only at Debug, which is the one level
-- that wants its per-event tracing and timing summaries.
local cfg=require('MenuSettings')
local Diagnostics=require('UE4SSCommonDiagnostics')
local Levels=require('QuietDawnLogLevels')
local lastVisible,lastGameTime,lastHealth,lastStamina,gapMax
local level=cfg.logLevel or Levels.DEFAULT
-- The shared library calls this with one argument, so its own output keeps the
-- Debug tag it has always had.
--
-- The trailing newline is required: UE4SS's print does NOT terminate a line,
-- so without it every message runs straight into the next one's timestamp.
-- main.lua and dmm_api.lua already append it for the same reason.
-- The resolution of the clock every timing in this file is built on.
--
-- D.now() is os.clock, which on Windows advances in steps of about 15.6 ms.
-- That is longer than a frame at 60 Hz, so a phase reported as "15 ms" may
-- have taken anything from a microsecond to 15.6 ms: the clock simply ticked
-- over once. Investigations have already been started from numbers that were
-- really one tick, so measure the step once and say so in the log.
local tickMs = 0
local function measureClockTick()
    local start = os.clock()
    local spins = 0
    -- Bounded: run once, during startup, and only with Debug enabled.
    while os.clock() == start and spins < 5000000 do spins = spins + 1 end
    local step = (os.clock() - start) * 1000
    if step > 0 and step < 1000 then return step end
    return 0
end
local function output(message,tag) print("[Quiet Dawn - Configurable HUD]["..(tag or Levels.tags[Levels.DEBUG]).."] "..message.."\n") end
-- Every line is printed on its own so the shared UE4SS log stays readable and
-- each line keeps the mod prefix, even when other mods interleave their output.
local function outputIndented(message) output("    "..message) end
local function summary(s)
    local timings,counts,dropped=s.timings,s.counts,s.dropped
    output(string.format("summary interval=%.3fs suppressed=%d sampleGapMaxMs=%.3f",s.interval,dropped,gapMax or 0))
    for _,name in ipairs({"worker","visibility","sample","marker","enemyHealth","directions","hook","clawMarks",
        "clawLookup","clawPrepare","clawApply","playerEffects"}) do
        local t=timings[name]
        if t then
            -- Flag any phase whose worst sample is within a tick or two of
            -- the clock's own resolution. Such a number measures the clock,
            -- not the work, and acting on it means optimising noise.
            local caveat = (tickMs > 0 and t.max <= tickMs*2) and "  (<= 2 clock ticks; not resolvable)" or ""
            outputIndented(string.format("%s calls=%d avgMs=%.3f maxMs=%.3f slow=%d%s",
                name,t.n,t.total/t.n,t.max,t.slow,caveat))
        end
    end
    local keys={};for name in pairs(counts) do keys[#keys+1]=name end;table.sort(keys)
    for _,name in ipairs(keys) do outputIndented(name.."="..counts[name]) end
    if lastHealth then outputIndented(string.format("health=%.4f stamina=%.4f wanted=%s",lastHealth,lastStamina,tostring(lastVisible))) end
    gapMax=0
end
if cfg.debugLogging then tickMs = measureClockTick() end
-- A "slow phase" threshold below the clock's resolution cannot mean anything:
-- any call unlucky enough to straddle a tick boundary reports as slow, and a
-- load was producing 25 such warnings for a phase that may have cost a
-- millisecond. Keep the configured value, but never let it sit under one
-- tick, so a slow warning always describes work rather than the clock.
local configuredSlowMs=math.max(0.1,math.min(1000,cfg.SlowCallbackMs or 2))
local effectiveSlowMs=math.max(configuredSlowMs,tickMs*1.5)
local D=Diagnostics.new({mutable=true,debugLogging=cfg.debugLogging,prefix='',output=output,
    summarySeconds=math.max(5,math.min(120,cfg.SummarySeconds or 10)),
    slowCallbackMs=effectiveSlowMs,
    maxEventsPerSecond=math.floor(math.max(1,math.min(20,cfg.MaxEventsPerSecond or 6))),
    onSummary=summary})
-- Level-aware output.
--
-- `D.debugLogging` keeps its original meaning, "the Debug level is active",
-- so the hot per-event guards spread across the gameplay scripts stay correct
-- and stay cheap. The functions below are for messages that deserve to be
-- seen at quieter levels.
local function describe(message,...)
    if select('#',...)==0 then return tostring(message) end
    local ok,text=pcall(string.format,message,...)
    return ok and text or tostring(message)
end
local function emit(severity,message,...)
    if level<severity then return end
    output(describe(message,...),Levels.tags[severity])
end
function D.logError(message,...) emit(Levels.ERROR,message,...) end
function D.logWarning(message,...) emit(Levels.WARNING,message,...) end
function D.logInfo(message,...) emit(Levels.INFO,message,...) end
function D.level() return level end
function D.allows(severity) return level>=severity end
-- Apply is allowed to change the level mid-session. Only Debug needs the
-- shared library's tracing machinery, so only Debug toggles it.
function D.setLevel(newLevel)
    if not Levels.valid(newLevel) then return end
    level=newLevel
    D.setEnabled(newLevel>=Levels.DEBUG)
end
function D.vitals() end
function D.vitals(health,stamina,visible,gameTime,healthUntil,staminaUntil)
    if not D.debugLogging then return end
    if lastGameTime and gameTime>=lastGameTime then
        gapMax=math.max(gapMax or 0,(gameTime-lastGameTime)*1000)
    end
    lastGameTime,lastHealth,lastStamina=gameTime,health,stamina
    if lastVisible~=visible then
        lastVisible=visible
        D.event("vitals","wanted=%s health=%.4f stamina=%.4f gameTime=%.3f healthHold=%.3f staminaHold=%.3f",tostring(visible),health,stamina,gameTime,math.max(0,(healthUntil or 0)-gameTime),math.max(0,(staminaUntil or 0)-gameTime))
    end
end
if D.debugLogging then
    output("enabled build=diagnostics-common-1")
    outputIndented("ini="..(cfg.path or "unavailable"))
    outputIndented(string.format("summarySeconds=%.1f",math.max(5,math.min(120,cfg.SummarySeconds or 10))))
    outputIndented(string.format("slowMs=%.2f configuredMs=%.2f",effectiveSlowMs,configuredSlowMs))
    outputIndented(string.format("eventLimit=%d",math.floor(math.max(1,math.min(20,cfg.MaxEventsPerSecond or 6)))))
    outputIndented(string.format("clock=os.clock resolutionMs=%.3f; a phase at or below this is unresolvable",tickMs))
    outputIndented("phase timings overlap and are not engine frame times")
end
return D
