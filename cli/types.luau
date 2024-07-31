--!strict

local pathfs = require("pathfs")

export type StandardPackageIndex = "core" | "shared" | "server" | "dev"

export type Registry<API> = typeof(setmetatable(
	{} :: {
		api: API,
		config: {
			[string]: any?,
			api: string,
			githubOauthId: string
		}
	},
	{} :: RegistryImpl<API>
))

export type RegistryImpl<API> = {
	__index: RegistryImpl<API>,
	new: (registryUrl: string) -> (Registry<API>),
	update: (self: Registry<API>) -> (),
	searchPackage: (self: Registry<API>, query: string) -> ({
		{
			description: string,
			name: string,
			scope: string,
			versions: { string }
		}
	}),
	getPackageMetadata: (self: Registry<API>, scope: string, name: string) -> ({
		[string]: {
			index: StandardPackageIndex,
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
	findPackage: (self: Registry<API>, query: string) -> { name: string, package: string }
}

return nil
