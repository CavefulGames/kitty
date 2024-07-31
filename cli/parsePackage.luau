local regex = require("@lune/regex")

type RegexMatch = {
    finish: number,
    len: number,
    start: number,
    text: string
}

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

return function(str: string): {
	name: RegexMatch?,
	scope: RegexMatch?,
	version: RegexMatch?
}?
	local scopeAndName = regex.new("^([^/]+)/([^@]+)$")
	local fullName = regex.new("^([^/]+)/([^@]+)@(.+)$")
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
