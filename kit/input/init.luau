local core = script.Parent.Parent
local Signal = require(core.wally.signal)
local Promise = require(core.wally.promise)
local UserInputService = game:GetService"UserInputService"
local Input = {}

local masterkey = require(core.libs.masterkey)
local connections:{
	[string]:{
		[any]:Signal.Connection<>
	}
} = {}
local pressEvents = {}
local releaseEvents = {}
local binds = {}
local downActions = {}
local currentCombination

local Console
function Input.__init(dependencies)
	Console = dependencies.Console
end

UserInputService.InputBegan:Connect(function(input,gameProcessedEvent)
	local actions = currentCombination or binds
	currentCombination = nil
	local actionName = actions[input.KeyCode] or actions[input.UserInputType]
	downActions[actionName] = true
	local event = pressEvents[actionName]
	if event then
		event:Fire(gameProcessedEvent)
	elseif type(event) == "table" then
		currentCombination = event
	end
end)

UserInputService.InputEnded:Connect(function(input,gameProcessedEvent)
	local actions = currentCombination or binds
	currentCombination = nil
	local action = actions[input.KeyCode] or actions[input.UserInputType]
	downActions[action] = nil
	local event = releaseEvents[action]
	if event then
		event:Fire(gameProcessedEvent)
	end
end)

local function getEvent(events,action)
	local signal = events[action]
	if not signal then
		signal = Signal.new()
		events[action] = signal
	end
	return signal
end

local function getHandles(actionName:string,identifier:any)
	local handles = connections[actionName]
	if handles then
		if handles[identifier] then
			Console.fatalf("Input action '%s' is already in use in the same identifier '%s' please disconnect before connect another",actionName,tostring(identifier))
		end
	else
		handles = {}
		connections[actionName] = handles
	end
	return handles
end

function Input.onPress(actionName:string,callback:(gameProcessedEvent:boolean)->()?,identifier:any?)
	local event = getEvent(pressEvents,actionName)
	if not callback then
		return event
	end
	identifier = identifier or masterkey
	local handles = getHandles(actionName,identifier)
	handles[identifier] = event:Connect(callback)
	return
end

function Input.oncePress(actionName:string,callback:(gameProcessedEvent:boolean)->(),identifier:any?)
	identifier = identifier or masterkey
	local handles = getHandles(actionName,identifier)
	handles[identifier] = getEvent(pressEvents,actionName):Once(function(...)
		handles[identifier] = nil
		callback(...)
	end)
end

function Input.waitForPress(actionName:string)
	return getEvent(pressEvents,actionName):Wait()
end

function Input.onRelease(actionName:string,callback:(gameProcessedEvent:boolean)->()?,identifier:any?)
	local event = getEvent(releaseEvents,actionName)
	if not callback then
		return event
	end
	identifier = identifier or masterkey
	local handles = getHandles(actionName,identifier)
	handles[identifier] = event:Connect(callback)
	return
end

function Input.onceRelease(actionName:string,callback:(gameProcessedEvent:boolean)->(),identifier:any?)
	identifier = identifier or masterkey
	local handles = getHandles(actionName,identifier)
	handles[identifier] = getEvent(releaseEvents,actionName):Once(function(...)
		handles[identifier] = nil
		callback(...)
	end)
end

function Input.waitForRelease(actionName:string)
	return getEvent(releaseEvents,actionName):Wait()
end

function Input.onHold(actionName:string,holdDurationInSeconds:number,callback:(gameProcessedEvent:boolean)->(),identifier:any?)
	Input.onPress(actionName,function(...)
		task.wait(holdDurationInSeconds)
		if Input.isDown(actionName) then
			callback(...)
		end
	end,identifier)
end

function Input.onceHold(actionName:string,holdDurationInSeconds:number,callback:(gameProcessedEvent:boolean)->(),identifier:any?)
	Input.onPress(actionName,function(...)
		task.wait(holdDurationInSeconds)
		if Input.isDown(actionName) then
			callback(...)
			Input.disconnect(actionName,identifier)
		end
	end,identifier)
end

function Input.waitForHold(actionName:string,holdDurationInSeconds:number)
	return getEvent(holdDurationInSeconds,actionName):Wait()
end

function Input.onPressMultiple(actionName:string,n:number,duration:number,timeout:number?,resetOnDisturbed:boolean?,callback:(gameProcessedEvent:boolean)->(),identifier:any?)

end

function Input.captureAsync()
	return Promise.new(function()

	end)
end

function Input.bind(key:Enum.KeyCode|Enum.UserInputType,actionName:string)
	binds[key] = actionName
end

function Input.bindCombination(key0:Enum.KeyCode|Enum.UserInputType,key1:Enum.KeyCode|Enum.UserInputType,actionName:string)
	binds[key0] = {[key1]=actionName}
end

function Input.unbind(key:Enum.KeyCode|Enum.UserInputType)
	local actionName = binds[key]
	local handles = connections[actionName]
	for identifier,connection in handles do
		connection:Disconnect()
		connection = nil
		handles[identifier] = nil
	end
end

function Input.unbindCombination(key0:Enum.KeyCode|Enum.UserInputType,key1:Enum.KeyCode|Enum.UserInputType)
	local combination = binds[key0]
	local actionName = combination[key1]
	local handles = connections[actionName]
	for identifier,connection in handles do
		connection:Disconnect()
		connection = nil
		handles[identifier] = nil
	end
end

function Input.disconnect(actionName:string,identifier:any?)
	identifier = identifier or masterkey
	local handles = connections[actionName]
	handles[identifier]:Disconnect()
end

function Input.isDown(actionName:string)
	return downActions[actionName] == true
end

function Input.isKeyDown(key:Enum.KeyCode)
	return UserInputService:IsKeyDown(key)
end

function Input.areKeysDown(key1:Enum.KeyCode,key2:Enum.KeyCode,isSequential:boolean)
	local isKeyDown = Input.isKeyDown
	if isSequential then
		return isKeyDown(key1) and isKeyDown(key2)
	else
		return (isKeyDown(key1) and isKeyDown(key2)) or (isKeyDown(key2) and isKeyDown(key1))
	end
end

function Input.areEitherKeysDown(key1:Enum.KeyCode,key2:Enum.KeyCode)
	local isKeyDown = Input.isKeyDown
	return isKeyDown(key1) or isKeyDown(key2)
end

return Input
