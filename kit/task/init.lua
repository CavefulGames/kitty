--!strict

--// dependencies
local Strict = require(script.Parent.strict)
local Task = {}

local sleeping = {}
local freeThreads: { thread } = {}

--// properties
local synchronized = Strict.Mutable(false)
Task.synchronized = synchronized

local function checkYieldSafe()
	if synchronized() then
		error("Not allowed to yield or wait while the current task is synchronized")
	end
end

local function runCallback(callback,thread,...)
	callback(...)
	table.insert(freeThreads,thread)
end

local function yielder()
	while true do
		runCallback(coroutine.yield())
	end
end

local AsyncMetatable = {}
AsyncMetatable.__index = AsyncMetatable

export type AsyncFunction<T...,U...> = (T...)->(U...)&{await:(self:AsyncFunction<T...,U...>,T...)->(U...)}

function AsyncMetatable:await(...)
	return self._fn(...)
end

function AsyncMetatable:__call(...)
	local fn = self._fn
	if fn then
		local thread
		if #freeThreads > 0 then
			thread = freeThreads[#freeThreads]
			freeThreads[#freeThreads] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end
		synchronized(false)
		task.spawn(thread,fn,thread,...)
	end
end

function Task.Async<T...,U...>(f:(T...)->(U...)):AsyncFunction<T...,U...>
	return setmetatable({_fn = f},AsyncMetatable)::AsyncFunction<T...,U...>
end

function Task.Sync<T...,U...>(f:(T...)->(U...)) --// to force synchronization and run the function, wrap it with the Sync
	return function(...)
		synchronized(true)
		f(...)
		synchronized(false)
	end
end

function Task.isAsync(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj) == AsyncMetatable
end

Task.getGameTime = time
Task.getLuaTime = os.clock
Task.getUTCTime = os.time

function Task.wakeUp(sleepId:any)
	sleeping[sleepId] = nil
end

function Task.sleep(sleepId:any,duration:number):(boolean,number) --// (didSleepWell,timePassed)
	checkYieldSafe()
	sleeping[sleepId] = true
	local t = os.clock()
	while sleeping[sleepId] and os.clock() - t < duration do
		task.wait()
	end
	local success = sleeping[sleepId] ~= nil
	if success then
		sleeping[sleepId] = nil
	end
	return success,os.clock()-t
end

function Task.yield(duration:number)
	checkYieldSafe()
	local t = os.clock()
	while os.clock()-t < duration do end
	return os.clock()-t
end

function Task.switch(value:any)
	return function(cases:{[any]:any,default:()->()?})
		return (cases[value] or cases.default)()
	end
end

--// extending task library
for k,v in task do
	Task[k] = v
end

--// hooking task.wait
function Task.wait(duration:number?):number --// since you are not allowed to use wait inside of Task.Sync
	checkYieldSafe()
	return task.wait(duration)
end

return Strict.Capsule(Task)::typeof(Task)&typeof(task)
