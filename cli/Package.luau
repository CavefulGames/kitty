--!strict

local regex = require("@lune/regex")

local scopeAndName = regex.new("^([^/]+)/([^@]+)$")
local fullName = regex.new("^([^/]+)/([^@]+)@(.+)$")

type RegexMatch = {
    finish: number,
    len: number,
    start: number,
    text: string
}

export type Package = typeof(setmetatable(
	{} :: {
		scope: string,
		name: string,
		version: string,
		metadata: {
			[string]: any,
			description: string
		}?
	},
	{} :: PackageImpl
))

type PackageImpl = {
	__index: PackageImpl,
	__tostring: (self: Package) -> (string),
	new: (scope: string, name: string, version: string) -> (),
	from: (str: string) -> (Package),
	toString: (self: Package) -> (string),
	parse: (str: string) -> ({
		scope: RegexMatch?,
		name: RegexMatch?,
		version: RegexMatch?
	}?)
}

local Package = {} :: PackageImpl
Package.__index = Package

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

function Package.__tostring(self)
	return self.scope .. "/" .. self.name .. "@" .. self.version
end

Package.toString = Package.__tostring

function Package.new(name, scope, version)
	return setmetatable({
		scope = scope,
		name = name,
		version = version
	}, Package)
end

function Package.from(str)
	local parsed = Package.parse(str)
	if parsed and parsed.scope and parsed.name and parsed.version then
		return setmetatable({
			scope = parsed.scope.text,
			name = parsed.name.text,
			version = parsed.version.text
		}, Package)
	end
	error(`Invalid package string '{str}'`)
end

function Package.parse(str)
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

return Package
