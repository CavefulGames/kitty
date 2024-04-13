local core = script.Parent.Parent
local Signal = require(core.wally.signal)
local Players = game:GetService"Players"
local UserInputService = game:GetService"UserInputService"

local constants = require(core.common.constants)
local isServer = require(core.libs.isserver)
local masterkey = require(core.libs.masterkey)
local events = {}
local connections = {}

local module = {}

--// dependencies
local Imports
local Net
local Console
local Thread
function module.init(deps)
	Imports = deps.Imports
	Net = deps.Net
	Console = deps.Console
	Thread = deps.Thread
end

local function getEvent(eventName:string)
	local event = events[eventName]
	if not event then
		event = Signal.new()
		events[eventName] = event
	end
	return event
end

local function getHandles(eventName:string,identifier:any)
	local handles = connections[eventName]
	if handles then
		if handles[identifier] then
			Console.fatalf("Hook event '%s' is already in use in the same identifier '%s' please unbind before connect another",eventName,tostring(identifier))
		end
	else
		handles = {}
		connections[eventName] = handles
	end
	return handles
end

function module.add(eventName:string,func:()->()?,identifier:any?)
	identifier = identifier or masterkey
	local event = getEvent(eventName)
	if not func then
		return event
	end
	local handles = getHandles(eventName,identifier)
	handles[identifier] = event:Connect(func)
end

function module.addOnce(eventName:string,func:()->(),identifier:any?)
	local handles = getHandles(eventName,identifier)
	handles[identifier] = getEvent(eventName):Once(func)
end

function module.waitFor(eventName:string)
	return getEvent(eventName):Wait()
end

function module.remove(eventName:string,identifier:any?)
	identifier = identifier or masterkey
	local handles = connections[eventName]
	if handles then
		handles[identifier]:Disconnect()
		handles[identifier] = nil
	end
end

function module.register(eventName:string,signal:Signal.Signal|RBXScriptSignal)
	local event = events[eventName]
	if event then
		if Signal.Is(signal) then
			event:Destroy()
		end
		event = nil
		events[eventName] = nil
	end
	events[eventName] = signal
end

if isServer then
	local SomeoneConnect = Signal.new()
	module.register("SomeoneConnect",SomeoneConnect)
	Players.PlayerAdded:Connect(function(player)
		SomeoneConnect:Fire(player)
		Net.start(constants.coreNetworkString)
		Net.writeUInt8(constants.coreNetworkMessageMethodIdentifiers.clientSharedHookReceive)
		Net.writeInstance(player)
	end)
else
	local LocalPlayer = Players.LocalPlayer

	Net.onReceive(constants.coreNetworkString,function()
		if Net.readUInt8() == constants.coreNetworkMessageMethodIdentifiers.clientSharedHookReceive then
			local event = events[Net.readString()]
			if event then
				local instances = Net.readAllInstances()
				event:Fire(instances and table.unpack(instances) or table.unpack(Net.readTable()))
			end
		end
	end)

	module.register("PlayerSpawn",LocalPlayer.CharacterAdded)
	LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		module.register("PlayerDie",humanoid.Died)
		module.register("PlayerJump",humanoid.Jumping)
		module.register("PlayerMove",humanoid.Running)
		module.register("PlayerHealthChange",humanoid.HealthChanged)
		module.register("PlayerStateChange",humanoid.StateChanged)
		local PlayerDamage = Signal.new()
		module.register("PlayerDamage",PlayerDamage)
		local oldHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(health:number)
			if health < oldHealth then
				PlayerDamage:Fire(oldHealth-health)
			end
			oldHealth = health
		end)
	end)
end

return module
