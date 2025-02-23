--!strict

local pathfs = require("../submodules/pathfs")
local stdio = require("@lune/stdio")
local argparse = require("../submodules/argparse")
local logger = require("logger")
local kitty = require("manifests/kitty")
local wally = require("manifests/wally")
-- local types = require("types")
-- local parsePackage = require("parsePackage")

-- local registries: { [string]: types.RegistryImpl<any> } = {
-- 	wally = require("registries/wally")
-- }

-- local function getRegistries(registry: { [string]: string? })
-- 	local result = {}
-- 	for name, url in registry do
-- 		local reg = registries[name]
-- 		if reg and url then
-- 			table.insert(result, reg.new(url))
-- 		end
-- 	end
-- 	return result
-- end

local function wrapLogger(fn: (...any) -> ())
	return function(...)
		xpcall(fn, logger.fatal, ...)
	end
end

local cli = argparse("kitty")
local init = cli:command("init", "Initializes a kitty project")
init:option("--path", "Project path")
init:option("--name", "Project name")
init:option("--runtime", "Runtime name (roblox, luau)")
init:action(wrapLogger(function(args: { path: string?, runtime: string?, name: string? })
	error("bruh")
	local path = pathfs.Path.from(args.path or "")
	local manifestPath = path:join(kitty.fileName)
	if pathfs.isFile(manifestPath) then
		logger.fatal(`There is already a Kitty project in this directory. Manifest file ({manifestPath}) already exists.`)
	end
	local name = args.name or stdio.prompt("text", "Project name:")
	local runtime = args.runtime :: string
	if not runtime then
		local selected = stdio.prompt("select", "Choose a standard of package management:", kitty.runtimes)
		runtime = kitty.runtimes[selected]
	end
	local manifest: kitty.Kitty = {
		name = name,
		packages = {
			runtime = runtime
		}
	}
	if runtime == "roblox" then
		manifest.packages.registry = { wally = "https://github.com/UpliftGames/wally-index" }
		print("Initialized a project with wally registry!")
	end
	pathfs.writeFile(manifestPath, kitty.toml:encode(manifest, true))

	-- kittyManifest:setProjectPath(args.path)
	-- if pathfs.isFile(kittyManifest:getPath()) then
	-- 	context.panic(`There is already a Kitty project in this directory. Manifest file ({kittyManifest:getPath()}) already exists.`)
	-- end
	-- local selected = stdio.prompt("select", "Choose a standard of package management:", {
	-- 	"roblox",
	-- 	"luau"
	-- })
	-- if selected == 1 then
	-- 	kittyManifest:write({
	-- 		packages = {
	-- 			std = "roblox",
	-- 			registry = { wally = "https://github.com/UpliftGames/wally-index" }
	-- 		}
	-- 	})
	-- elseif selected == 2 then
	-- 	kittyManifest:write({
	-- 		packages = {
	-- 			std = "luau"
	-- 		}
	-- 	})
	-- end
end))
local add = cli:command("add", "Add a package but does not install them")
add:argument("name", "Package name to add")
add:option("--path", "Project path")
add:flag("--core", "Core packages")
add:flag("--dev", "Developer packages")
add:flag("--shared", "Shared packages")
add:action(function(args: { name: string, path: string?, core: boolean?, dev: boolean?, shared: boolean? })

	-- kittyManifest:setProjectPath(args.path)
	-- local manifest = kittyManifest:read()
	-- if not manifest.packages then
	-- 	error(context.panic(`Could not resolve 'packages' in {kittyManifest:getPath()}`))
	-- end
	-- if not manifest.packages.registry then
	-- 	error(context.panic(`Could not resolve 'registry' in {kittyManifest:getPath()}`))
	-- end
	-- for _, index in getRegistries(manifest.packages.registry) do
	-- 	local findResult = index:findPackage(args.name)
	-- 	local package = parsePackage(findResult.package)
	-- 	if not package then
	-- 		continue
	-- 	end
	-- 	if not package.name or not package.scope or not package.version then
	-- 		continue
	-- 	end -- 먼가 캐시된 인덱스를 써야할거같은 느낌 할때마다 api 요청하는게 아닌!
	-- 	local metadatas = index:getPackageMetadata(package.scope.text, package.name.text)
	-- 	local metadata = metadatas[]
	-- 	local indexName =  do
	-- 		if args.core then
	-- 			indexName = "core"
	-- 		end
	-- 		if args.dev then
	-- 			indexName = "dev"
	-- 		end
	-- 	end
	-- 	local packages = kittyManifest:getPackages(indexName)
	-- 	packages[findResult.name] = findResult.package
	-- 	kittyManifest:write(manifest)
	-- end
end)

local install = cli:command("install", "Fetch added packages and install them or install the target package if given")
install:argument("target", "Package name to install"):args("?")
install:option("--path", "Project path")
install:flag("-C --core", "Core packages")
install:flag("-D --dev", "Developer packages")
install:action(function()

end)

local wally = cli:command("wally", "Wally commands that depends on wally")
local wallyInit = wally:command("init", "Initialize a new Wally project")
wallyInit:argument("path", "The path to the project to initialize. Defaults to the current directory"):args("?")
wallyInit:action(function(args: { path: string })
	wallyManifest:setProjectPath(args.path)

end)
local wallyLogin = wally:command("login", "Log into a registry")
wallyLogin:action(function()
	print("hi")
end)

cli:parse()
