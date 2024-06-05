--!strict

--// dependencies
local Strict = require(script.Parent.strict)
local Debugger = require(script.Parent.debugger)
local Flow = {}

local sleeping: { [any]: boolean } = {}
local freeThreads: { thread } = {}

local function runCallback(callback,thread,...)
	callback(...)
	table.insert(freeThreads,thread)
end

local function yielder()
	while true do
		runCallback(coroutine.yield())
	end
end

local function resultHandler(co: thread, ok: boolean, ...)
	if not ok then
		local err = (...)
		if typeof(err) == "string" then
			error(debug.traceback(co, err), 2)
		else
			-- If the error is not of type string, just assume it has some
			-- meaningful information and rethrow it with a `tostring` so that
			-- top-level error handlers can process it
			error(tostring(err), 2)
		end
	end

	if coroutine.status(co) ~= "dead" then
		error(debug.traceback(co, "Attempted to yield inside changed event!"), 2)
	end

	return ...
end

local AsyncMetatable = {}
AsyncMetatable.__index = AsyncMetatable

function Flow.Async<T..., U...>(f: (T...) -> (U...)): (T...) -> ()
	return function(...: T...)
		local thread
		if #freeThreads > 0 then
			thread = freeThreads[#freeThreads]
			freeThreads[#freeThreads] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end
		task.spawn(thread, f, thread, ...)
	end
end

function Flow.NoYield<T..., U...>(callback: (T...) -> (U...)): (T...) -> (U...)
	if Debugger.enabled() then
		return function(...: T...): U...
			local co = coroutine.create(callback)
			return resultHandler(co, coroutine.resume(co, ...))
		end :: any
	else
		return callback :: any
	end
end

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
