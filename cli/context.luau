local stdio = require("@lune/stdio")
local process = require("@lune/process")
local context = {}

local debugMode = table.find(process.args, "debug") ~= nil

function context.panic(message: string?): never
	if debugMode then
		error(message)
	else
		stdio.write(stdio.color("red"))
		stdio.write(tostring(message))
		stdio.write(stdio.color("reset"))
	end
	return process.exit(1)
end

context.assert = function(condition, message)
	if not condition then
		context.panic(message)
	end
end :: typeof(assert)

return context
