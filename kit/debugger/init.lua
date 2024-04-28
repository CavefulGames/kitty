--!strict
--- inspired by JavaScript console and C# Debug

--// dependencies
local Strict = require(script.Parent.strict)
local Hook = require(script.Parent.hook)
local Debugger = {}

--// services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// instances
local LocalPlayer = Players.LocalPlayer

local isStudio = RunService:IsStudio()
local dummySilentFunction = function()end
local tagFormat = "[ %s ]"

Debugger.silent = setmetatable({},{
	__index=function(k)
		return if isStudio then Debugger[k] else dummySilentFunction
	end
})
Debugger.onMessage = Hook()::Hook.HookedEvent<...any>
Debugger.enabled = Strict.Mutable(false)
Debugger.visible = Strict.Mutable(true)

local function getTag():string
	local scriptName = debug.traceback(nil,3):gsub("\n",""):match("[^.]+%.(.-):%d+$")
	return tagFormat:format(scriptName)
end

function Debugger.log(...:any)
	if not Debugger.enabled() then
		return
	end
	Debugger.onMessage:Fire(...)
	if Debugger.visible() then
		print(getTag(),...)
	end
end

function Debugger.logf(message:string,...:string)

end

function Debugger.warn(...:any)

end

function Debugger.warnf(message:string,...:string)

end

function Debugger.assert(assertion:boolean,...:any)
	if assertion then
		warn(...)
	end
end

function Debugger.assertf(assertion:boolean,message:string,...:string)

end

function Debugger.fatality(fatalityCode:number)
	LocalPlayer:Kick()
end

return Strict.Capsule(Debugger)
