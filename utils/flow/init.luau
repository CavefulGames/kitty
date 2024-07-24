--!strict

--$Packages
local Debugger = require(script.Parent.debugger)
local ThreadPool = require(script.Parent.threadpool)
local LimeSignal = require(script.Parent.limesignal)
local Flow = {}

local sleeping: { [any]: boolean } = {}

Flow.getGameTime = time
Flow.getLuaTime = os.clock
Flow.getUTCTime = os.time

function Flow.wakeUp(sleepId: any)
	sleeping[sleepId] = nil
end

function Flow.sleep(sleepId: any, duration: number): (boolean, number) -- (didSleepWell, timePassed)
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

function Flow.switch(value: any)
	return function(cases:{ [any]: any, default: () -> ()? })
		return (cases[value] or cases.default)()
	end
end

Flow.spawn = ThreadPool.spawn
Flow.Signal = LimeSignal.Signal
Flow.Bindable = LimeSignal.Bindable

return Debugger.Module(Flow)
