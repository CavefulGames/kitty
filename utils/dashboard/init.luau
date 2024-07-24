--// kit
local React = require(script.Parent.react)

--// services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local isStudio = RunService:IsStudio()
local silentLog = false
local isServer = require(core.libs.isserver)
local dump = require(core.libs.dump)
local API
local commands = {}
local config = {
	logColor = Color3.new(1,1,1);
	errorColor = Color3.fromRGB(255, 79, 79);
	warnColor = Color3.fromRGB(255, 173, 80);
	commandNotFoundMessage = "Unknown command \"%s\"";
	debugInfoFormat = "[%s:%s] ";
	debugCodeFormat = "[code: %s-%08d]";
}
local dummySilentFunction = function() end
local currentTailMessage = ""

local module = {
	silent = {};
	config = config;
}

if not isServer then
	local ConsoleGui = require(core.Parent.game.client.koact.Console)
	local LocalPlayer = Players.LocalPlayer

	function module.init(deps)
		local Koact = deps.Koact
		local Util = deps.Util
		local Input = deps.Input

		API = Util.newSignal()

		Koact.render(Koact[ConsoleGui]{
			API=API;
			onSubmit=function(text)
				local args = text:split(" ")
				local cmdName = args[1]
				local cmd = commands[cmdName]
				if cmd then
					cmd()
				else
					API:Fire("log",{
						content = config.commandNotFoundMessage:format(cmdName);
						color = config.errorColor
					})
				end
			end
		},LocalPlayer.PlayerGui)

		Input.onPress("ConsoleOpen",function()
			API:Fire("toggle")
		end)

		Input.bind(Enum.KeyCode.Backquote,"ConsoleOpen")
	end
end

--// pre-index
local concatTable = table.concat

local function log(message:string)
	if API then
		if isStudio then
			print(message)
		end
		API:Fire("log",{
			content = message;
			color = config.logColor
		})
	else
		print(message)
	end
end

local function logWarn()

end

local function logFatal()

end

local function getDebugInfo()
	local info = debug.traceback(nil,3):split(":")
	return config.debugInfoFormat:format(info[1],info[2])
end

local function getTexts(...)
	local text = {}
	for i,v in ipairs({...}) do
		if type(v) == "table" and tostring(v) then
			table.insert(text,dump(v))
		else
			local s = tostring(v)
			table.insert(text,s or v)
		end
	end
	return text
end

function module.log(...:string)
	local texts = getTexts(...)
	log(getDebugInfo()..table.concat(texts," "))
end

function module.logf(message:string,...:string)
	log(getDebugInfo()..message:format(...)..currentTailMessage)
end

function module.fatal(...:string)

end

function module.fatalf(message:string,...:string)

end

function module.assert(condition:boolean,...:string)

end

function module.assertf(condition:boolean,message:string,...:string)

end

function module.warn(...:string)

end

function module.warnf(message:string,...:string)

end

function module.assertWarn(condition:boolean,...:string)

end

function module.assertWarnf(condition:boolean,message:string,...:string)

end

function module.table()

end

function module.count()

end

function module.resetCount()

end

function module.time()

end

function module.timeLog()

end

function module.timeEnd()

end

function module.addCommand(commandName:string,callback:(arguments:{})->())

end

function module.onSubmit(callback:(message:string)->(),identifier:any?)

end

function module.parseArguments(str:string)

end

function module.code(uniqueCodeNumber:number)
	local meta = {}
	function meta.__index(k)
		return function (...)
			currentTailMessage = config.debugCodeFormat:format(script.Name,uniqueCodeNumber)
			module[k](...)
			currentTailMessage = ""
		end
	end
	setmetatable({},meta)
end

for name,func in pairs(module) do
	module.silent[name] = isStudio and function(...)
		module[name](...)
	end or dummySilentFunction
end

return module
