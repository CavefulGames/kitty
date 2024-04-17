--!optimize 2
--!nocheck
--!native

export type Connection<U...> = {
	Binded: boolean,
	Enabled: boolean,
	Unbind: (self: Connection<U...>) -> (),
	Rebind: (self: Connection<U...>) -> (),
}

export type Event<T...> = {
	RBXScriptConnection: RBXScriptConnection?,
	Enabled: boolean,
	Bind: (self: Hook<T...>, fn: (...any) -> ()) -> Connection,
	BindNamed: (self: Hook<T...>, name:string, fn: (...any) -> ()) -> Connection,
	BindOnce: (self: Hook<T...>, fn: (...any) -> ()) -> Connection,
	BindOnceNamed: (self: Hook<T...>, name:string, fn: (...any) -> ()) -> Connection,
	Await: (self: Hook<T...>) -> T...,
	Trigger: (self: Hook<T...>, ...any) -> (),
	UnbindAll: (self: Hook<T...>) -> (),
	UnbindNamed: (self: Hook<T...>, name:string) -> (),
	EnableNamed: (self: Hook<T...>, name:string) -> (),
	DisableNamed: (self: Hook<T...>, name:string) -> (),
	Destroy: (self: Hook<T...>) -> ()
}

local Connection = {}
Connection.__index = Connection

local function disconnect<U...>(self: Connection<U...>)
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

local function reconnect<U...>(self: Connection<U...>)
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

--\\ Signal //--
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

local function connect<T..., U...>(self: Event<T...>, fn: (...any) -> (), ...: U...): Connection<U...>
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

	return cn
end

local function once<T..., U...>(self: Event<T...>, fn: (...any) -> (), ...: U...)
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		fn(...)
	end, ...)
	return cn
end

local function wait<T...>(self: Event<T...>): ...any
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

local function fire<T...>(self: Event<T...>, ...: any)
	if not self.Enabled then
		return
	end
	local cn = self._head
	while cn do
		cn._fn(...)
		cn = cn._next
	end
end

local function disconnectAll<T...>(self: Event<T...>)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end

local function destroy<T...>(self: Event<T...>)
	disconnectAll(self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end

local function named(self,name:string,cn: Connection<>)
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

--\\ Methods
Signal.Bind = connect
Signal.BindNamed = function(self,name:string,fn:(...any) -> ())
	assert(type(name)=="string","Name for named binds must be a string")
	named(self,name,connect(self,fn))
end
Signal.BindOnce = once
Signal.BindOnceNamed = function(self,name:string,fn:(...any) -> ())
	assert(type(name)=="string","Name for named binds must be a string")
	named(self,name,once(self,fn))
end
Signal.Await = wait
Signal.Trigger = fire
Signal.UnbindAll = disconnectAll
Signal.UnbindNamed = function(self,name:string)
	assert(type(name)=="string","Name for named binds must be a string")
	disconnect(self.NamedConnections[name])
end
Signal.EnableNamed = function(self,name:string)
	assert(type(name)=="string","Name for named binds must be a string")
	self.NamedConnections[name].Enabled = true
end
Signal.DisableNamed = function(self,name:string)
	assert(type(name)=="string","Name for named binds must be a string")
	self.NamedConnections[name].Enabled = false
end
Signal.Destroy = destroy

return function(signal:RBXScriptSignal?):Event
	local event = setmetatable({ _head = false, Enabled = true }, Signal)
	if typeof(signal) == "RBXScriptSignal" then
		event.RBXScriptConnection = rbxConnect(signal, function(...)
			fire(event, ...)
		end)
	end
	return event
end
