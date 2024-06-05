--!optimize 2
--!strict
--!native

--- modified from LemonSignal

--// kit
local Flow = require(script.Parent.flow)
local Debugger = require(script.Parent.debugger)

export type Connection = {
	Binded: boolean,
	Enabled: boolean,
	Unbind: (self: Connection) -> (),
	Rebind: (self: Connection) -> (),
	[string]: any,
}

export type HookedEvent<T...> = {
	RBXScriptConnection: RBXScriptConnection?,
	RBXScriptSignal: RBXScriptSignal?,
	Enabled: boolean,
	Bind: (self: HookedEvent<T...>, fn: (T...) -> ()) -> Connection,
	BindNamed: (self: HookedEvent<T...>, name: string, fn: (T...) -> ()) -> Connection,
	BindOnce: (self: HookedEvent<T...>, fn: (T...) -> ()) -> Connection,
	BindOnceNamed: (self: HookedEvent<T...>, name: string, fn: (...any) -> ()) -> Connection,
	Wait: (self: HookedEvent<T...>) -> T...,
	Fire: (self: HookedEvent<T...>, T...) -> (),
	UnbindAll: (self: HookedEvent<T...>) -> (),
	UnbindNamed: (self: HookedEvent<T...>, name: string) -> (),
	EnableNamed: (self: HookedEvent<T...>, name: string) -> (),
	DisableNamed: (self: HookedEvent<T...>, name: string) -> (),
	Destroy: (self: HookedEvent<T...>) -> (),
	[string]: any,
}

local Connection = {}
Connection.__index = Connection

local function disconnect(self: Connection)
	if not self.Binded then
		return
	end
	self.Binded = false

	local next = self._next
	local prev = self._prev

	if next then
		next._prev = prev
	end
	if prev then
		prev._next = next
	end

	local signal = self._signal
	if signal._head == self then
		signal._head = next
	end
end

local function reconnect(self: Connection)
	if self.Binded then
		return
	end
	self.Binded = true

	local signal = self._signal
	local head = signal._head
	if head then
		head._prev = self
	end
	signal._head = self

	self._next = head
	self._prev = false
end

Connection.Unbind = disconnect
Connection.Rebind = reconnect

--// signal
local Signal = {}
Signal.__index = Signal

-- stylua: ignore
local rbxConnect, rbxDisconnect do
	if task then
		local bindable = Instance.new("BindableEvent")
		rbxConnect = bindable.Event.Connect
		rbxDisconnect = bindable.Event:Connect(function() end).Disconnect
		bindable:Destroy()
	end
end

local function connect<T...>(self: HookedEvent<T...>, fn: (T...) -> ()): Connection
	local head = self._head
	local cn = setmetatable({
		Binded = true,
		Enabled = true,
		_signal = self,
		_fn = fn,
		--_varargs = if not ... then false else { ... },
		_next = head,
		_prev = false,
	}, Connection)

	if head then
		head._prev = cn
	end
	self._head = cn

	return cn :: any
end

local function once<T...>(self: HookedEvent<T...>, fn: (T...) -> ())
	local cn
	cn = connect(self, function(...: T...)
		disconnect(cn);
		(fn :: (T...) -> ())(...)
	end)
	return cn
end

local function wait<T...>(self: HookedEvent<T...>): ...any
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

local function fire<T...>(self: HookedEvent<T...>, ...: T...)
	if not self.Enabled then
		return
	end
	local cn = self._head
	while cn do
		cn._fn(...)
		cn = cn._next
	end
end

local function disconnectAll<T...>(self: HookedEvent<T...>)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end

local function destroy<T...>(self: HookedEvent<T...>)
	disconnectAll(self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end

local function named(self, name: string, cn: Connection<>)
	local cns = self.NamedConnections
	if not cns then
		cns = {}
		self.NamedConnections = cns
	end
	if cns[name] then
		error(`Already exist named connection '{name}'`)
	end
	cns[name] = cn
end

--\\ methods
Signal.Bind = connect
Signal.BindNamed = function(self, name: string, fn: (...any) -> ())
	assert(type(name) == "string", "Name for named binds must be a string")
	named(self, name, connect(self, fn))
end
Signal.BindOnce = once
Signal.BindOnceNamed = function(self, name: string, fn: (...any) -> ())
	assert(type(name) == "string", "Name for named binds must be a string")
	named(self, name, once(self, fn))
end
Signal.Wait = wait
Signal.Fire = fire
Signal.UnbindAll = disconnectAll
Signal.UnbindNamed = function(self, name: string)
	assert(type(name) == "string", "Name for named binds must be a string")
	disconnect(self.NamedConnections[name])
end
Signal.EnableNamed = function(self, name: string)
	assert(type(name) == "string", "Name for named binds must be a string")
	self.NamedConnections[name].Enabled = true
end
Signal.DisableNamed = function(self, name: string)
	assert(type(name) == "string", "Name for named binds must be a string")
	self.NamedConnections[name].Enabled = false
end
Signal.Destroy = destroy

return function(signal: RBXScriptSignal?): HookedEvent<...any>
	local event = (setmetatable({ _head = false, Enabled = true }, Signal) :: any) :: HookedEvent<...any>
	if signal ~= nil then
		event.RBXScriptSignal = signal
		if typeof(signal) == "RBXScriptSignal" then
			event.RBXScriptConnection = rbxConnect(signal, function(...)
				fire(event, ...)
			end)
		else
			event.RBXScriptConnection = signal:Connect(function(...)
				fire(event, ...)
			end)
		end
	end
	return event :: HookedEvent<...any>
end
