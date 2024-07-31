--!strict

local serde = require("@lune/serde")
local context = require("../../context")
local process = require("@lune/process")
local pathfs = require("../../pathfs")
local regex = require("@lune/regex")
local wallyapi = require("api")
local stdio = require("@lune/stdio")
local types = require("../../types")
local getCacheDirectory = require("../../getCacheDirectory")
local parsePackage = require("../../parsePackage")

local WallyRegistry = {} :: types.RegistryImpl<typeof(wallyapi())>
WallyRegistry.__index = WallyRegistry

function WallyRegistry.new(registryUrl)
	local index = getCacheDirectory()
	if not index then
		error(context.panic("Could not find cache directory"))
	end
	index:push("kitty")
	index:push("index")
	if not pathfs.isDir(index) then
		pathfs.writeDir(index)
	end
	local urlParser = regex.new("^(?:https?://)?(?:www\\.)?([^/]+)")
	local domainCapture = urlParser:captures(registryUrl)
	if not domainCapture then
		error(context.panic("Could not parse the domain from index url"))
	end
	local domain = domainCapture:get(1)
	if not domain then
		error(context.panic("Could not parse the domain from index url"))
	end
	local path = index:join(domain.text .. "-" .. serde.hash("blake3", registryUrl))
	if pathfs.isDir(path) then
		process.spawn("git", { "-C", path:toString(), "fetch" })
		process.spawn("git", { "-C", path:toString(), "reset", "--hard" })
	else
		process.spawn("git", { "clone", registryUrl, path:toString() })
	end
	local config = serde.decode("json", pathfs.readFile(path:join("config.json"))) :: {
		api: string,
		github_oauth_id: string
	}
	if not config.api or not config.github_oauth_id then
		context.panic("Corrupted config file")
	end
	return setmetatable({
		api = wallyapi(config.api),
		config = {
			api = config.api,
			githubOauthId = config.github_oauth_id
		}
	}, WallyRegistry)
end

function WallyRegistry.searchPackage(self, query)
	local res = self.api.package_search(query)
	context.assert(res.ok == true, "Could not fetch wally package_search API")
	return res.decoded --serde.decode("json", res.body)
end

function WallyRegistry.getPackageMetadata(self, scope, name)
	local res = self.api.package_metadata(scope, name)
	context.assert(res.ok == true, "Could not fetch wally package_metadata API")
	local metadata = {}
	for _, v in res.decoded.versions do
		metadata[v.package.version] = {
			index = v.package.realm,
			dependencies = {
				shared = v.dependencies,
				server = v.server_dependencies,
				dev = v.dev_dependencies
			}
		}
	end
	return metadata :: any
end

function WallyRegistry.findPackage(self, query)
	local package = parsePackage(query)
	if package then
		local scope = package.scope
		local name = package.name
		local version = package.version
		if scope and name and version then
			return {
				name = name.text,
				package = query
			}
		elseif scope and name then
			local result = self:searchPackage(scope.text .. "/" .. name.text)[1]
			if result and result.scope == scope.text and result.name == name.text then
				local ver = result.versions[1]
				if ver then
					return {
						name = name.text,
						package = query .. "@" .. ver
					}
				end
			end
		end
	else
		local results = self:searchPackage(query)
		if #results > 0 then
			local closestPackages = {}
			local closestPackagesNames = {}
			for _, result in results do
				if result.name == query then
					table.insert(closestPackages, result.scope .. "/" .. result.name .. "@" .. result.versions[1])
					table.insert(closestPackagesNames, result.name)
				end
			end
			if #closestPackages > 1 then
				local selectedIndex = stdio.prompt("select", `Found 2 or more packages related to '{query}'`, closestPackages)
				if selectedIndex then
					return {
						name = closestPackagesNames[selectedIndex],
						package = closestPackages[selectedIndex]
					}
				end
			elseif #closestPackages == 1 then
				return {
					name = closestPackagesNames[1],
					package = closestPackages[1]
				}
			end
		end
	end
	error(context.panic("Could not found package. nothing was added."))
end

return WallyRegistry
