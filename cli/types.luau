--!strict

local pathfs = require("pathfs")
local Package = require("Package")
local roblox = require("@lune/roblox")

export type StandardPackageRealm = "core" | "shared" | "server" | "dev"

export type Index = typeof(setmetatable(
	{} :: {
		url: string,
		path: pathfs.Path,
		configCache: {}?
	},
	{} :: IndexImpl
))

export type IndexImpl = {
	__index: IndexImpl,
	new: (registryUrl: string) -> (Index),
	update: (self: Index) -> (),
	searchPackage: (self: Index, query: string) -> ({ Package.Package }),
	getConfig: (self: Index) -> ({
		api: string,
		githubOauthId: string
	}),
	getPackageMetadata: (self: Index, scope: string, name: string) -> ({
		[string]: {
			realm: StandardPackageRealm,
			dependencies: {
				core: {
					[string]: string
				}?,
				shared: {
					[string]: string
				}?,
				server: {
					[string]: string
				}?,
				dev: {
					[string]: string
				}?
			}
		}
	}),
	getScopeOwners: (self: Index, scope: string) -> (),
	downloadPackage: (self: Index, package: Package.Package) -> (string),
	--findPackage: (self: Registry<API>, query: string) -> { name: string, package: string }

	-- getIndex: (self: Index) -> ({
	-- 	[string]: { -- scope (idea: scope를 또 class로?)
	-- 		[string]: { -- name
	-- 			[string]: { -- version
	-- 				realm: StandardPackageRealm,
	-- 				version: string,
	-- 				description: string,
	-- 				dependencies: {
	-- 					core: {
	-- 						[string]: string
	-- 					}?,
	-- 					shared: {
	-- 						[string]: string
	-- 					}?,
	-- 					server: {
	-- 						[string]: string
	-- 					}?,
	-- 					dev: {
	-- 						[string]: string
	-- 					}?
	-- 				}
	-- 			}
	-- 		}
	-- 	}
	-- })
}

export type Snapshot = () -> ()

export type InstanceSnapshot = {
	name: string,
	className: string,
	properties: { [string]: any },
	children: { roblox.Instance }
}

return nil
