local limesignal = require(script.Parent.Parent.roblox_packages.limesignal)
local RunService = game:GetService("RunService")

type CallbackFn = () -> nil
type TimeFn = () -> number

export type Timer = typeof(setmetatable(
	{} :: {
		_runHandle: RBXScriptConnection?,
		interval: number,
		updateSignal: RBXScriptSignal,
		timeFunction: TimeFn,
		allowDrift: boolean,
		tick: limesignal.Event<()>
	},
	{} :: TimerImpl
))

type TimerImpl = {
	__index: TimerImpl,
	new: (interval: number) -> Timer,
	simple: (
		interval: number,
		callback: CallbackFn,
		startNow: boolean?,
		updateSignal: RBXScriptSignal?,
		timeFn: TimeFn?
	) -> RBXScriptConnection,
	is: (self: Timer, obj: unknown) -> boolean,
	start: (self: Timer) -> (),
	startNow: (self: Timer) -> (),
	stop: (self: Timer) -> (),
	isRunning: (self: Timer) -> boolean,
	destroy: (self: Timer) -> ()
}

local Timer = {} :: TimerImpl
Timer.__index = Timer

local emit = limesignal.createEmitter()

function Timer.new(interval)
	if interval < 0 then
		error(`Argument #1 to Timer.new must be greater or equal to 0; got {interval}`)
	end
	return setmetatable({
		_runHandle = nil,
		interval = interval,
		updateSignal = RunService.Heartbeat,
		timeFunction = time,
		allowDrift = true,
		tick = limesignal.Event.from(emit)
	}, Timer)
end

function Timer.simple(
	interval,
	callback,
	startNow,
	updateSignal,
	timeFn
)
	local update = (updateSignal or RunService.Heartbeat) :: RBXScriptSignal
	local t = timeFn or time
	local nextTick = t() + interval
	if startNow then
		task.defer(callback)
	end
	return update:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + interval
			task.defer(callback)
		end
	end)
end

function Timer.is(obj): boolean
	return type(obj) == "table" and getmetatable(obj) == Timer
end

local function startTimer(self: Timer)
	local t = self.timeFunction
	local nextTick = t() + self.interval
	self._runHandle = self.updateSignal:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + self.interval
			emit(self.tick)
		end
	end)
end

local function startTimerNoDrift(self: Timer)
	if self.interval <= 0 then
		error("interval must be greater than 0 when allowDrift is set to false")
	end
	local t = self.timeFunction
	local n = 1
	local start = t()
	local nextTick = start + self.interval
	self._runHandle = self.updateSignal:Connect(function()
		local now = t()
		while now >= nextTick do
			n += 1
			nextTick = start + (self.interval * n)
			emit(self.tick)
		end
	end)
end

function Timer.start(self)
	if self._runHandle then
		return
	end
	if self.allowDrift then
		startTimer(self)
	else
		startTimerNoDrift(self)
	end
end

function Timer.startNow(self: Timer)
	if self._runHandle then
		return
	end
	emit(self.tick)
	self:start()
end

function Timer.stop(self: Timer)
	if not self._runHandle then
		return
	end
	self._runHandle:Disconnect()
	self._runHandle = nil
end

function Timer.isRunning(self: Timer): boolean
	return self._runHandle ~= nil
end

function Timer.destroy(self: Timer)
	self.tick:disconnectAll()
	self:stop()
end

return Timer
