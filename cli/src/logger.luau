--!strict
-- this replaces 'context.luau' inspired by 'https://github.com/RealEthanPlayzDev/Loggy'

local datetime = require("@lune/datetime")
local stdio = require("@lune/stdio")
local process = require("@lune/process")
local pathfs = require("../submodules/pathfs")
local logger = {}

local messages = {} :: { { any } }
local LogType = {
	Debug = function() end,
	Info = function() end,
	Warn = function() end,
	Fatal = function() end
}
local LogTypeTag = {
	[LogType.Debug] = "[DBG]",
	[LogType.Info] = "[INF]",
	[LogType.Warn] = "[WRN]",
	[LogType.Fatal] = "[FTL]"
}
local LogTypeColor = {
	[LogType.Debug] = "cyan",
	[LogType.Info] = "blue",
	[LogType.Warn] = "yellow",
	[LogType.Fatal] = "red"
}

logger.verbose = false

local function fmt(message: any): string
	local typeId = message[1]
	return `{stdio.color(LogTypeColor[typeId] :: any)}{LogTypeTag[typeId]}{stdio.color("reset")}::{message[2]} {message[3]}`
end

local function log(message)
	table.insert(messages, message)
	if logger.verbose then
		stdio.write(fmt(message) .. "\n")
	end
end

function logger.debug(...: any)
	log({
		LogType.Debug,
		datetime.now() :: any,
		stdio.format(...) :: any
	})
end

function logger.info(...: any)
	log({
		LogType.Info,
		datetime.now() :: any,
		stdio.format(...) :: any
	})
end

function logger.warn(...: any)
	log({
		LogType.Warn,
		datetime.now() :: any,
		stdio.format(...) :: any
	})
end

function logger.fatal(...: any)
	-- log({
	-- 	LogType.Fatal,
	-- 	datetime.now() :: any,
	-- 	`{stdio.format(...)}\ntraceback: {debug.traceback()}` :: any
	-- })
	-- stdio.write(stdio.color(LogTypeColor[LogType.Fatal] :: any))
	-- print(stdio.format(...))
	-- stdio.write(stdio.color("reset"))
	--stdio.write(stdio.color("red"))
	print("This text will be red")
	--stdio.write(stdio.color("reset"))
	print("This text will be normal")
	process.exit(1)
end

function logger.export(exportPath: pathfs.AsPath)
	local fmts = table.clone(messages)
	for i, v in fmts do
		fmts[i] = fmt(v) :: any
	end
	pathfs.writeFile(exportPath, table.concat(fmts, "\n"))
end

return logger
