--!strict

--// dependencies
local Strict = require(script.Parent.strict)
local Debugger = require(script.Parent.debugger)
local Flow = {}

local sleeping: { [any]: boolean } = {}

Flow.getGameTime = time
Flow.getLuaTime = os.clock
Flow.getUTCTime = os.time

function Flow.wakeUp(sleepId: any)
	sleeping[sleepId] = nil
end

function Flow.sleep(sleepId: any,duration: number): (boolean, number) --// (didSleepWell,timePassed)
	sleeping[sleepId] = true
	local t = os.clock()
	while sleeping[sleepId] and os.clock() - t < duration do
		task.wait()
	end
	local success = sleeping[sleepId] ~= nil
	if success then
		sleeping[sleepId] = nil
	end
	return success,os.clock() - t
end

function Flow.yield(duration: number)
	local t = os.clock()
	while os.clock() - t < duration do end
	return os.clock() - t
end

function Flow.switch(value: any)
	return function(cases:{ [any]: any, default: () -> ()? })
		return (cases[value] or cases.default)()
	end
end

return Strict.Capsule(Flow)
