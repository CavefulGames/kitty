--!strict

local Manifest = require("../Manifest")

export type Package = {
	name: string,
	version: string,
	registry: string,
	realm: "shared" | "server" | "dev",
	description: string?,
	license: string?,
	authors: { string }?,
	include: { string }?,
	exclude: { string }?,
	private: boolean?
}

export type Place = {
	shared_packages: string?,
	server_packages: string?
}

export type Wally = {
	package: Package,
	place: Place?,
	dependencies: { [string]: string },
	server_dependencies: { [string]: string },
	dev_dependencies: { [string]: string }
}

local wally = Manifest.new("wally",
	{ "package",
		{ "name", "string" },
		{ "version", "string" },
		{ "registry", "string" },
		{ "realm", "string" },
		{ "description", "string?" },
		{ "license", "string?" },
		{ "authors", "table?" },
		{ "include", "table?" },
		{ "exclude", "table?" },
		{ "private", "boolean" }
	},
	{},
	{ "place",
		{ "shared_packages", "string?" },
		{ "server_packages", "string?" }
	},
	{},
	{ "dependencies" },
	{ "server_dependencies" },
	{ "dev_dependencies" }
) :: Manifest.Manifest<Wally>

wally:addPackageIndex("shared", { "dependencies" }, "Packages")
wally:addPackageIndex("server", { "server_dependencies" }, "ServerPackages")
wally:addPackageIndex("dev", { "dev_dependencies" }, "DevPackages")

return wally
