--!strict

local serde = require("@lune/serde")
local context = require("../../context")
local process = require("@lune/process")
local pathfs = require("../../pathfs")
local regex = require("@lune/regex")
local stdio = require("@lune/stdio")
local types = require("../../types")
local getCacheDirectory = require("../../getCacheDirectory")
local parsePackage = require("../../parsePackage")
local getUrlDomain = require("../../getUrlDomain")

local WallyRegistry = {} :: types.IndexImpl
WallyRegistry.__index = WallyRegistry

function WallyRegistry.new(registryUrl)
	local self = setmetatable({
		url = registryUrl
	}, WallyRegistry)
	local path = self:fetchIndex()
	local config = serde.decode("json", pathfs.readFile(path:join("config.json"))) :: {
		api: string,
		github_oauth_id: string
	}
	if not config.api or not config.github_oauth_id then
		context.panic("Corrupted config file")
	end
	self.config = {
		api = config.api,
		githubOauthId = config.github_oauth_id
	}
	return self
end

function WallyRegistry.fetchIndex(self)
	local index = getCacheDirectory()
	if not index then
		error(context.panic("Could not find cache directory"))
	end
	index:push("kitty")
	index:push("index")
	if not pathfs.isDir(index) then
		pathfs.writeDir(index)
	end
	local gitRemoteUrl = self.url
	local domain = getUrlDomain(gitRemoteUrl)
	if not domain then
		error(context.panic("Could not parse the domain from index url"))
	end
	local path = index:join(domain .. "-" .. serde.hash("blake3", gitRemoteUrl))
	if pathfs.isDir(path) then
		process.spawn("git", { "-C", path:toString(), "fetch" })
		process.spawn("git", { "-C", path:toString(), "reset", "--hard" })
	else
		process.spawn("git", { "clone", gitRemoteUrl, path:toString() })
	end
	return path
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
