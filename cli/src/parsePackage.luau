local regex = require("@lune/regex")

local scopeAndName = regex.new("^([^/]+)/([^@]+)$")
local fullName = regex.new("^([^/]+)/([^@]+)@(.+)$")

local function pack(captures: regex.RegexCaptures)
	local scope = captures:get(1)
	local name = captures:get(2)
	local version = captures:get(3)
	return {
		scope = scope,
		name = name,
		version = version
	}
end

return function(str)
	local captures = fullName:captures(str)
	if captures then
		return pack(captures)
	end
	captures = scopeAndName:captures(str)
	if captures then
		return pack(captures)
	end
	return nil
end
