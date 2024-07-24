--!strict
-- inspired by nodejs console and C# Debug

--$Packages
local LimeSignal = require(script.Parent.limesignal)
local Debugger = {}

--$Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--$PrivateVariables
local isStudio = RunService:IsStudio()
local isServer = RunService:IsServer()
local dummySilentFunction = function() end
local tagFormat = "[ %s ]"

Debugger.silent = setmetatable({}, {
	__index = function(k)
		return if isStudio then Debugger[k] else dummySilentFunction
	end
})
Debugger.enabled = isStudio
Debugger.visible = true
Debugger.fatalErrorMessage = "\nA fatal error has occurred: [%s] %s\nWe're sorry for the inconvenience, but you have been kicked out to protect your data safety. An error report has been successfully submitted."

local function getTag(): string
	local scriptName = debug.traceback(nil, 3):gsub("\n", ""):match("[^.]+%.(.-):%d+$")
	return tagFormat:format(scriptName)
end

local function isEnabled(): boolean
	-- selene: allow(global_usage)
	return Debugger.enabled or _G.__DEV__
end

function Debugger.log(...: any)
	if not isEnabled() then
		return
	end
	if Debugger.visible then
		print(getTag(), ...)
	end
end

function Debugger.logf(message: string, ...: string)
	Debugger.log(message:format(...))
end

function Debugger.warn(...: any)
	if not isEnabled() then
		return
	end
	if Debugger.visible then
		warn(getTag(), ...)
	end
end

function Debugger.warnf(message: string, ...: string)
	Debugger.warn(message:format(...))
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
			player:Kick(Debugger.fatalErrorMessage:format(info, message))
		end
	else
		Players.LocalPlayer:Kick(Debugger.fatalErrorMessage:format(info, message))
	end
end

--[=[
	`Strict.Capsule`에서 파생된 함수이며 주어진 테이블을 디버깅에 유용한 모듈로 만듭니다.

	모듈의 속성은 `Debugger.Mutable` 제외 읽기 전용이며 키값은 문자열만 허용됩니다.

	성능에 지장을 줄 수 있으므로 디버그 모드가 활성화된 상태에서만 메타테이블을 사용하여 런타임 타입 체킹을 수행합니다.

	```lua
	local module = Debugger.Module({
		something = 123,
		[123] = "foo", -- not ok
		some = 1
	})
	module.something = nil -- not ok
	module.some = "a" -- not ok
	```
]=]
function Debugger.Module<T>(module: T): T
	if type(module) ~= "table" then
		error("Module must be a table!")
	end
	for k: string, v: any in module do
		if type(k) ~= "string" then
			error(`Only string is allowed as a module's field in strict mode, got {k}({typeof(k)})`, 2)
		end
	end
	if Debugger.enabled then
		setmetatable(module :: any, {
			__index = function(self, k)
				local v = rawget(module, k)
				if v == nil then

				end
				return v
			end
		})
	end
	return module
end

--[=[
	`Debugger.Module`에 가변 속성을 정의합니다.

	타입은 정적이며 빈 속성은 `Debugger.Mutable(nil, "type name")`으로 정의 가능합니다.

	```lua
	local module = Debugger.Module({
		property = Debugger.Mutable(123),
		emptyThing = Debugger.Mutable(nil, "string")
	})
	module.property = 1000 -- ok
	module.property = "a" -- not ok
	module.emptyThing = 123 -- not ok
	```
]=]
function Debugger.Mutable<T>(value: T, typeName: string?)

end

return Debugger.Module(Debugger)
