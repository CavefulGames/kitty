--!strict

local Manifest = require("../Manifest")

type Package = string | {
	url: string?,
	path: string?
}

export type Struct = {
	name: string,
	production_id: number?,
	version: string,
	authors: { string }?,
	packages: {
		registry: string,
		paths: {
			[string]: string
		}?,
		shared: {
			[string]: Package
		}?,
		core: {
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
	{ "name", "string" },
	{ "production_id", "number?" },
	{ "version", "string" },
	{ "authors", "table?" },
	{ },
	{ "packages",
		{ "registry", "string" },
		{ "paths", "table?" },
		{ "core" },
		{ "shared" },
		{ "server" },
		{ "dev" }
	},
	{ }
) :: Manifest.Manifest<Struct>

kitty:addPackageIndex("core", { "packages", "core" }, "CorePackages")
kitty:addPackageIndex("shared", { "packages", "shared" }, "Packages")
kitty:addPackageIndex("server", { "packages", "server" }, "ServerPackages")
kitty:addPackageIndex("dev", { "packages", "dev" }, "DevPackages")
kitty.packageIndexPathModifierRoute = { "packages", "paths" }

return kitty
