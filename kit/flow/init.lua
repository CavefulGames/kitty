--!strict

--// dependencies
local Strict = require(script.Parent.strict)
local Context = {}

local sleeping = {}
local freeThreads: { thread } = {}

--// properties
local synchronized = Strict.Mutable(false)
Context.synchronized = synchronized

local function checkYieldSafe()
	if synchronized() then
		error("Not allowed to yield or wait while the current context is synchronized")
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

function Context.Async<T...,U...>(f:(T...)->(U...)):AsyncFunction<T...,U...>
	return setmetatable({_fn = f},AsyncMetatable)::AsyncFunction<T...,U...>
end

function Context.Sync<T...,U...>(f:(T...)->(U...)) --// to force synchronization and run the function, wrap it with the Sync
	return function(...)
		synchronized(true)
		f(...)
		synchronized(false)
	end
end

function Context.isAsync(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj) == AsyncMetatable
end

-- function Context.getGameTime()
-- 	return time()
-- end

-- function Context.getLuaTime()
-- 	return os.clock()
-- end

-- function Context.getUTCTime()
-- 	return os.time()
-- end

function Context.wakeUp(sleepId:any)
	sleeping[sleepId] = nil
end

function Context.sleep(sleepId:any,duration:number):(boolean,number) --// (didSleepWell,timePassed)
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

function Context.yield(duration:number)
	checkYieldSafe()
	local t = os.clock()
	while os.clock()-t < duration do end
	return os.clock()-t
end

function Context.switch(value:any)
	return function(cases:{[any]:any,default:()->()?})
		return (cases[value] or cases.default)()
	end
end

--// extending task library
for k,v in task do
	Context[k] = v
end

--// hooking task.wait
function Context.wait(duration:number?):number --// since you are not allowed to use wait inside of Context.Sync
	checkYieldSafe()
	return task.wait(duration)
end

return Strict.Capsule(Context)::typeof(Context)&typeof(task)
