--!strict

local primordials = require(script.Parent:WaitForChild('primordials'))
local safeWeakMap = require(script.Parent:WaitForChild('safeMap'))

type timesStore = {
    kBindStreamsEager: any,
    enumerable: any,
    writable: any,
    value: safeWeakMap.SafeMap,
}

local kSecond = 1000
local kMinute = 60 * kSecond
local kHour = 60 * kMinute

local function pad(value)
    return primordials.stringPrototypePadStart(`{value}`, 2, '0')
end

local function formatTime(ms)
    local hours = 0
    local minutes = 0
    local seconds = 0

    if ms >= kSecond then
        if ms >= kMinute then
            if ms >= kHour then
                hours = math.floor(ms / kHour)
                ms = ms % kHour
            end
            minutes = math.floor(ms / kMinute)
            ms = ms % kMinute
        end
        seconds = ms / kSecond
    end
    
    if hours ~= 0 or minutes ~= 0 then
        local splitSecondFix3 = string.split(tostring(primordials.numberPrototypeToFixed(seconds, 3)), '.')
        seconds, ms = tonumber(splitSecondFix3[1]) :: number, tonumber(splitSecondFix3[2]) :: number
        
        local res = if hours ~= 0 then `{hours}:{pad(minutes)}` else minutes
        return `{res}:{pad(seconds)}.{ms} ({if hours ~= 0 then 'h:m' else ''}m:ss.mmm`
    end

    if seconds ~= 0 then
        return `{primordials.numberPrototypeToFixed(seconds, 3)}s`
    end
    
    return `{primordials.numberPrototypeToFixed(ms, 3)}ms`
end

local function timeLogImpl(timesStore: timesStore, implementation, logImp: any, label, args)
    local getTime = timesStore.value:get(label)
    if getTime == nil then
        print(`No such label '{label}" for {implementation}`)
        return
    end

    local splitClockTime = string.split(tostring(os.clock()), '.')
    local duration = { tonumber(splitClockTime[1]) - getTime[1], tonumber(splitClockTime[2]) - getTime[2] }
    local ms = duration[1] * 1000 + duration[2] / 1e6

    local formatted = formatTime(ms)

    if args == nil then
        logImp(label, formatted)
    else
        logImp(label, formatted, args)
    end
end

local timeImpl = {}

function timeImpl.time(timesStore: timesStore, traceCategory, implementation, timerFlags, logLabel, traceLabel)
    if logLabel == nil then
        logLabel = 'default'
    end

    logLabel = `{logLabel}`

    if traceLabel ~= nil then
        traceLabel = `{traceLabel}`
    else
        traceLabel = logLabel
    end

    if timesStore.value:has(logLabel) then
        print(`Label "{logLabel}" already exists for {implementation}`)
        return
    end

    local splitClockTime = string.split(tostring(os.clock()), '.')
    timesStore.value:set(logLabel, { tonumber(splitClockTime[1]), tonumber(splitClockTime[2]) })
end

function timeImpl.timeEnd(timesStore: timesStore, traceCategory, implementation, timerFlags, logImpl, logLabel, traceLabel)
    if logLabel == nil then
        logLabel = 'default'
    end

    logLabel = `{logLabel}`

    traceLabel = if traceLabel ~= nil then `{traceLabel}` else logLabel

    if timerFlags == 0 then
        timeLogImpl(timesStore, implementation, logImpl, logLabel)
    end

    timesStore.value:delete(logLabel)
end

function timeImpl.timeLog(timesStore: timesStore, traceCategory, implementation, timerFlags, logImpl, logLabel, traceLabel, args)
    if logLabel == nil then
        logLabel = 'default'
    end

    logLabel = `{logLabel}`

    traceLabel = if traceLabel ~= nil then `{traceLabel}` else logLabel

    if timerFlags == 0 then
        timeLogImpl(timesStore, implementation, logImpl, logLabel, args)
    end
end

return timeImpl