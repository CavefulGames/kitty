--!strict
--- inspired by JavaScript console and C# Debug

--// dependencies
local Strict = require(script.Parent.strict)
local Debugger = {}

--// services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local isStudio = RunService:IsStudio()
local isServer = RunService:IsServer()
local dummySilentFunction = function() end
local tagFormat = "[ %s ]"
local messageCallbacks: { (...any) -> (...any) } = {}

Debugger.silent = setmetatable({}, {
	__index=function(k)
		return if isStudio then Debugger[k] else dummySilentFunction
	end
})
Debugger.enabled = Strict.createValue(isStudio)
Debugger.visible = Strict.createValue(true)
Debugger.fatalErrorMessage = Strict.createValue("\nA fatal error has occurred: [%s] %s\nWe're sorry for the inconvenience, but you have been kicked out to protect your data safety. An error report has been successfully submitted.")

local function getTag(): string
	local scriptName = debug.traceback(nil, 3):gsub("\n", ""):match("[^.]+%.(.-):%d+$")
	return tagFormat:format(scriptName)
end

local function callMessageCallbacks()
	for _ ,callback in messageCallbacks do
		callback()
	end
end

function Debugger.addMessageCallback(callback: () -> ()): () -> ()
	local index = #messageCallbacks + 1
	messageCallbacks[index] = callback
	return function() --// closure that removes callback
		messageCallbacks[index] = nil
	end
end

function Debugger.log(...: any)
	if not Debugger.enabled() then
		return
	end

	if Debugger.visible() then
		print(getTag(), ...)
	end
end

function Debugger.logf(message: string, ...: string)

end

function Debugger.warn(...: any)

end

function Debugger.warnf(message: string, ...: string)

end

function Debugger.assert(assertion: boolean, ...: any)
	if assertion then
		warn(...)
	end
end

function Debugger.assertf(assertion: boolean, message: string, ...: string)

end

function Debugger.fatal(message: string)
	local traceback = debug.traceback(nil, 2):gsub("\n", ""):split(":")[1]:split(".")
	local info = traceback[#traceback - 1] .. traceback[#traceback]
	if isServer then
		for _, player in Players:GetPlayers() do
			player:Kick(Debugger.fatalErrorMessage():format(info, message))
		end
	else
		Players.LocalPlayer:Kick(Debugger.fatalErrorMessage():format(info, message))
	end
end

return Strict.Capsule(Debugger)
