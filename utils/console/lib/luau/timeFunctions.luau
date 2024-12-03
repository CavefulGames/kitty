--!strict
local safeWeakMap = require(script.Parent:WaitForChild('safeMap'))
local primordials = require(script.Parent:WaitForChild('primordials'))

type timesStore = {
    kBindStreamsEager: any,
    enumerable: any,
    writable: any,
    value: safeWeakMap.SafeMap,
}

local kSkipLog = 0;

local kSecond = 1000
local kMinute = 60 * kSecond
local kHour = 60 * kMinute

local function pad(value)
    return primordials.stringPrototypePadStart(`{value}`, 2, '0')
end

local function formatTime(ms): string
    local hours = 0
    local minutes = 0
    local seconds = 0

    if ms >= kSecond then
        if ms >= kMinute then
            if ms >= kHour then
                hours = math.floor(ms /kHour)
                ms = ms % kHour
            end
            minutes = math.floor(ms / kMinute)
            ms = ms % kMinute
        end
        seconds = ms / kSecond
    end

    if hours ~= 0 or minutes ~= 0 then
        local splitString = string.split(tostring(primordials.numberPrototypeToFixed(seconds, 3)), '.')
        seconds, ms = tonumber(splitString[1]) :: number, tonumber(splitString[2]) :: number

        local res = if hours ~= 0 then `{hours}:{pad(minutes)}` else minutes
        return `{res}:{pad(seconds)}.{ms} ({if hours ~= 0 then 'h:m' else ''}m:ss.mmm)`
    end

    if seconds ~= 0 then
        return `{primordials.numberPrototypeToFixed(seconds, 3)}s`
    end

    return `{primordials.numberPrototypeToFixed(ms, 3)}ms`
end

local function timeLogImpl(timesStore: timesStore, implementation, logImp: any, label, args)
    local getTime = timesStore.value:get(label)
    if getTime == nil then
        print(`No such label "{label}" for {implementation}`)
        return
    end
    
    local duration = getTime
    local ms = if duration == 0 then
        0 
    else 
        tonumber(tostring(duration):sub(1, (10 // duration + 1)) .. '.' .. tostring(duration):sub((10 // duration + 1), (10 // duration + 1) + 4)) :: number
    
    local formatted = formatTime(ms)

    if args == nil then
        logImp(label, formatted)
    else
        logImp(label, formatted, args)
    end
end

local timeImpl = {
    kNone = 0,
}

function timeImpl.time(
    timesStore: timesStore, 
    traceCategory, 
    implementation, 
    timerFlags, 
    logLable, 
    traceLabel
)
    if logLable == nil then
        logLable = 'default'
    end

    logLable = `{logLable}`

    if traceLabel ~= nil then
        traceLabel = `{traceLabel}`
    else
        traceLabel = logLable
    end

    if timesStore.value:has(logLable) then
        print(`Label "{logLable}" already exists for {implementation}`)
        return
    end

    timesStore.value:set(logLable, os.clock())
end

function timeImpl.timeEnd(
    timesStore: timesStore,
    traceCategory,
    implementation,
    timerFlags,
    logImpl,
    logLabel,
    traceLabel
)
    if logLabel == nil then
        logLabel = 'default'
    end

    logLabel = `{logLabel}`

    if traceLabel ~= nil then
        traceLabel = `{traceLabel}`
    else
        traceLabel = logLabel
    end

    if (timerFlags and kSkipLog) == 0 then
        timeLogImpl(timesStore, implementation, logImpl, logLabel)
    end
    
    timesStore.value:delete(logLabel)
end

function timeImpl.timeLog(
    timesStore: timesStore,
    traceCategory,
    implementation,
    timerFlags,
    logImpl,
    logLabel,
    traceLabel,
    args
)
    if logLabel == nil then
        logLabel = 'default'
    end

    logLabel = `{logLabel}`

    if traceLabel ~= nil then
        traceLabel = `{traceLabel}`
    else
        traceLabel = logLabel
    end

    if (timerFlags and kSkipLog) == 0 then
        timeLogImpl(timesStore, implementation, logImpl, logLabel, args)
    end
end

return timeImpl
