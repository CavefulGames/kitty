local TomlStruct = require("../../submodules/tomlstruct")

type Registry = {
	wally: string?
}

type Package = string | ({
	url: string?,
	path: string?,
	git: string?,
	package: string?,
} & Registry)

type PackagesField = {
	["$path"]: string?,
	["$place"]: string?,
	[string]: Package
}

export type Kitty = {
	name: string,
	roblox_production: {
		id: number?,
		owner: { group: number?, user: number? },
		version: string,
	}?,
	packages: {
		runtime: string,
		registry: Registry?,
		core: PackagesField?,
		shared: PackagesField?,
		server: PackagesField?,
		dev: PackagesField?
	}
}

local runtimes = {
	"roblox",
	"luau"
}

local toml = TomlStruct(
	{ "name", "string" },
	{ "roblox_production",
		{ "id", "number?" },
		{ "owner", "table" },
		{ "version", "string" },
		"?"
	},
	{ },
	{ "packages",
		{ "runtime", "string", function(value: string): string?
			if table.find(runtimes, value) then
				return
			end
			return "Runtime must be 'roblox' or 'luau'."
		end},
		{ "registry", "table?", function(value: {}?): string?
			if not value then
				return
			end
			local moreThanOne = false
			for _, _ in value do
				if moreThanOne then
					return "There must be only one registry."
				end
				moreThanOne = true
			end
			return
		end},
		{ "core" },
		{ },
		{ "shared" },
		{ },
		{ "server" },
		{ },
		{ "dev" }
	}
) :: TomlStruct.TomlStruct<Kitty>

return {
	runtimes = runtimes,
	toml = toml,
	fileName = "kitty.toml"
}
