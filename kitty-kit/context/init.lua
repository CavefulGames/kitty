local core = script.Parent.Parent
local Promise = require(core.wally.promise)
local TaskQueue = require(core.wally.taskqueue)
local Signal = require(core.wally.signal)
local RunService = game:GetService"RunService"

local module = {}
local masterkey = require(core.libs.masterkey)
local events = {}
local connections = {}
local sleepingThreads = {}
local debugTicks = {}
local runServiceConnections = {}
local when = {
	beforeRender = RunService.PreRender;
	afterSimulation = RunService.PostSimulation;
	beforeSimulation = RunService.PreSimulation;
	afterRender = RunService.PreAnimation;
}

--// dependencies
local Console
function module.init(deps)
	Console = deps.Console
end

function module.getLocalTime()
	return tick()
end

function module.getGameTime()
	return time()
end

function module.getLuaTime()
	return os.clock()
end

function module.getUTCTime()
	return os.time()
end

local function getEvent(eventName,identifier)
	local event = events[eventName]
	Console.fatalfAssert(event~=nil,"event %s is not exist or not created yet, please call 'Thread.createEvent(\"%s\")' before connect",eventName,eventName)
	return event
end

local function getHandles(eventName,identifier)
	local handles = connections[eventName]
	if handles then
		if handles[identifier] then
			Console.fatalf("Thread event '%s' is already in use in the same identifier '%s' please unbind before connect another",eventName,tostring(identifier))
		end
	else
		handles = {}
		connections[eventName] = handles
	end
	return handles
end

function module.fireEvent(eventName:string)
	events[eventName]:Fire()
end

function module.createEvent(eventName:string)
	events[eventName] = Signal.new()
end

function module.removeEvent(eventName:string)
	events[eventName]:Destroy()
	events[eventName] = nil
end

function module.on(eventName:string,callback:()->(),identifier:any?)
	identifier = identifier or masterkey
	local event = getEvent(eventName)
	if not callback then
		return event
	end
	local handles = getHandles(eventName,identifier)
	handles[identifier] = event:Connect(callback)
end

function module.deactivate()

end

function module.activate()

end

function module.once(eventName:string,callback:()->())
	return getEvent(eventName):Once(callback)
end

function module.waitFor(eventName:string,callback:()->())
	return getEvent(eventName):Wait()
end

function module.unbind(eventName:string,identifier:any?)
	local callbacks = events[eventName]
	if callbacks then
		identifier = identifier or masterkey
		connections[identifier]:Disconnect()
		connections[identifier] = nil
	end
end

function module.wakeUp(sleepId:any)
	sleepingThreads[sleepId] = nil
end

function module.sleep(duration:number,sleepId:any)
	sleepingThreads[sleepId] = true
	local t = tick()
	while sleepingThreads[sleepId] and tick() - t < duration do
		taskWait()
	end
	local success = sleepingThreads[sleepId] ~= nil
	if success then
		sleepingThreads[sleepId] = nil
	end
	return success
end

function module.yield(duration:number)
	local t = tick()
	while tick()-t < duration do

	end
	return tick()-t
end

function module.switch(value:any)
	return function(cases:{[any]:any,default:()->()?})
		return (cases[value] or cases.default)()
	end
end

function module.run(f:()->()):thread
	local thread = createCoroutine(f)
	resumeCoroutine(thread)
	return thread
end

function module.sleepAsync(duration:number,sleepId:any,callback):thread
	return module.spawn(function()
		local success = module.sleep(duration,sleepId)
		if success then
			callback()
		end
	end)
end

function module.tickDebugStart(debugTickName:string)
	debugTicks[debugTickName] = tick()
end

function module.tickDebugLog(debugTickName:string)
	Console.logf("[Thread.tickDebugLog] %s: %s",debugTickName,tick()-debugTicks[debugTickName])
end

module.async = Promise.promisify
module.when = when
module.newBatcher = TaskQueue.new
module.newEvent = Signal.new

return module
