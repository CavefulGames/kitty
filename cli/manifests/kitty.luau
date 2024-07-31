--!strict

local Manifest = require("../Manifest")

type Package = string | {
	url: string?,
	path: string?
}

export type Kitty = {
	game: {
		name: string,
		production_id: number?,
		version: string,
		owner: { group: number?, user: number? },
	}?,
	packages: {
		std: "roblox" | "luau",
		registry: { wally: string? }?,
		paths: {
			[string]: string
		}?,
		core: {
			[string]: Package
		}?,
		shared: {
			[string]: Package
		}?,
		server: {
			[string]: Package
		}?,
		dev: {
			[string]: Package
		}?
	}
}

local kitty = Manifest.new("Kitty",
	{ "game",
		{ "name", "string" },
		{ "production_id", "number?" },
		{ "version", "string" },
		{ "owner", "table" },
		"?"
	},
	{},
	{ "packages",
		{ "std", "string" },
		{ "registry", "table?" },
		{ "paths", "table?" },
		{ "core" },
		{},
		{ "shared" },
		{},
		{ "server" },
		{},
		{ "dev" }
	}
) :: Manifest.Manifest<Kitty>

kitty:addPackageIndex("core", { "packages", "core" }, "CorePackages")
kitty:addPackageIndex("shared", { "packages", "shared" }, "Packages")
kitty:addPackageIndex("server", { "packages", "server" }, "ServerPackages")
kitty:addPackageIndex("dev", { "packages", "dev" }, "DevPackages")
kitty.packageIndexPathModifiersRoute = { "packages", "paths" }

return kitty
