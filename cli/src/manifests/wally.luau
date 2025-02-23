local TomlStruct = require("../../submodules/tomlstruct")

type Package = {
	name: string,
	version: string,
	registry: string,
	realm: string,
	description: string?,
	license: string?,
	authors: { string }?,
	include: { string }?,
	exclude: { string }?,
	private: boolean?
}

export type Wally = {
	package: Package,
	place: {
		shared_packages: string?,
		server_packages: string?
	}?,
	dependencies: { [string]: string },
	server_dependencies: { [string]: string },
	dev_dependencies: { [string]: string }
}

local realms = {
	"shared",
	"server",
	"dev"
}

local toml = TomlStruct(
	{ "package",
		{ "name", "string" },
		{ "version", "string" },
		{ "registry", "string" },
		{ "realm", "string", function(value: string): string?
			if table.find(realms, value) then
				return
			end
			return `Realm must be {table.concat(realms, " or ")}`
		end},
		{ "description", "string?" },
		{ "license", "string?" },
		{ "authors", "table?" },
		{ "include", "table?" },
		{ "exclude", "table?" },
		{ "private", "boolean" }
	},
	{ },
	{ "place",
		{ "shared_packages", "string?" },
		{ "server_packages", "string?" }
	},
	{ },
	{ "dependencies" },
	{ "server_dependencies" },
	{ "dev_dependencies" }
) :: TomlStruct.TomlStruct<Wally>

return {
	toml = toml,
	realms = realms,
	fileName = "wally.toml"
}
