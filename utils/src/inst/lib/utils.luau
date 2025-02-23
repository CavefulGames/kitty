local SEPARATOR = require(script.Parent.SEPARATOR)

local utils = {}

function utils.fullNameToPath(instance: Instance): string
	return instance:GetFullName():gsub("%.", SEPARATOR)
end

function utils.print(object: any): string
	if typeof(object) == "Instance" then
		return utils.debug(object)
	end
	return tostring(object)
end

function utils.debug(instance: Instance): string
	-- rust's enum-like print?
	return `Instance::{instance.ClassName}({utils.fullNameToPath(instance)})`
end

return utils
