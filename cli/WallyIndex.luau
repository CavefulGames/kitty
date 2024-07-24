--!strict

local serde = require("@lune/serde")
local net = require("@lune/net")
local context = require("context")
local process = require("@lune/process")
local pathfs = require("pathfs")
local regex = require("@lune/regex")
local wallyapi = require("wallyapi")
local stdio = require("@lune/stdio")

type Config = {
	api: string,
	github_oauth_id: string
}

export type WallyIndex = typeof(setmetatable(
	{} :: {
		apiUrlPath: pathfs.Path
	},
	{} :: WallyIndexImpl
))

type WallyIndexImpl = {
	__index: WallyIndexImpl,
	new: (registryUrl: string) -> (WallyIndex),
	searchPackage: (self: WallyIndex, query: string) -> ({
		{
			description: string,
			name: string,
			scope: string,
			versions: { string }
		}
	}),
	getPackageMetadata: (self: WallyIndex, scope: string, name: string) -> ({
		versions: {
			{
				dependencies: {
					[string]: string
				},
				["dev-dependencies"]: {
					[string]: string
				}
			}
		}
	}),
	--[=[
		returns (name: string, package: string)
	]=]
	findPackage: (self: WallyIndex, query: string) -> (string, string)
}

local WallyIndex = {} :: WallyIndexImpl
WallyIndex.__index = WallyIndex

local function parsePackage(str: string): regex.RegexCaptures?
	local scopeAndName = regex.new("^([^/]+)/([^@]+)$")
	local fullName = regex.new("^([^/]+)/([^@]+)@(.+)$")
	local captures = fullName:captures(str)
	if captures then
		return captures
	end
	captures = scopeAndName:captures(str)
	if captures then
		return captures
	end
	return
end

function WallyIndex.new(registryUrl)
	local index = pathfs.Path.from(process.env.LOCALAPPDATA)
	index:push("kitty")
	index:push("index")
	if not pathfs.isDir(index) then
		pathfs.writeDir(index)
	end
	local urlParser = regex.new("^(?:https?://)?(?:www\.)?([^/]+)")
	local domainCapture = urlParser:captures(registryUrl)
	if not domainCapture then
		context.panic("Could not parse the domain from index url")
		error("")
	end
	local domain = domainCapture:get(1)
	if not domain then
		context.panic("Could not parse the domain from index url")
		error("")
	end
	local path = index:join(domain.text .. "-" .. serde.hash("blake3", registryUrl))
	if pathfs.isDir(path) then
		process.spawn("git", { "-C", path:toString(), "fetch" })
		process.spawn("git", { "-C", path:toString(), "reset", "--hard" })
	else
		process.spawn("git", { "clone", registryUrl, path:toString() })
	end
	local config = serde.decode("json", pathfs.readFile(path:join("config.json"))) :: Config
	if not config.api or not config.github_oauth_id then
		context.panic("Corrupted config file")
	end
	return setmetatable({
		apiUrlPath = pathfs.Path.from(config.api):join("")
	}, WallyIndex)
end

function WallyIndex.searchPackage(self, query)
	local res = net.request(self.apiUrlPath:join(wallyapi.GET.package_search(query)):toString())
	context.assert(res.ok == true, "Could not fetch wally search api")
	return serde.decode("json", res.body)
end

function WallyIndex.getPackageMetadata(self, scope, name)

end

function WallyIndex.findPackage(self, query)
	local captures = parsePackage(query)
	if captures then
		local scope = captures:get(1)
		local name = captures:get(2)
		local version = captures:get(3)
		if scope and name and version then
			return name.text, query
		elseif scope and name then
			local result = self:searchPackage(scope.text .. "/" .. name.text)[1]
			if result and result.scope == scope.text and result.name == name.text then
				local ver = result.versions[1]
				if ver then
					return name.text, query .. "@" .. ver
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
					return closestPackagesNames[selectedIndex], closestPackages[selectedIndex]
				end
			elseif #closestPackages == 1 then
				return closestPackagesNames[1], closestPackages[1]
			end
		end
	end
	context.panic("Could not found package. nothing was added.")
	error("")
end

return WallyIndex
