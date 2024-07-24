--!strict

local pathfs = require("pathfs")
local stdio = require("@lune/stdio")
local argparse = require("../submodules/argparse")
local context = require("context")
local WallyIndex = require("WallyIndex")
local kittyManifest = require("manifests/kitty")
-- local MANIFEST_PATH = luaupath.Path.from("kitty.toml")
-- local WALLY_MANIFEST_PATH = luaupath.Path.from("wally.toml")
-- local DEFAULT_PACKAGES_PATHS = { -- inspired by wally but 'core' added
-- 	core = "CorePackages",
-- 	shared = "Packages",
-- 	server = "ServerPackages",
-- 	dev = "DevPackages"
-- }

-- local function readManifest(path: pathfs.AsPath): Manifest
-- 	local exist = pathfs.isFile(path)
-- 	if exist then
-- 		return serde.decode("toml", pathfs.readFile(path))
-- 	end
-- 	return context.panic(`Not a Kitty project, Check if '{path}' exists.`)
-- end

-- local function writeManifest(path: pathfs.AsPath, manifest: Manifest)
-- 	local toml = MANIFEST_TOML_STRUCT:encode(manifest)
-- 	pathfs.writeFile(path, toml)
-- end

-- local function getManifestPackages(manifest: Manifest, packageType: PackageTypes?): { [string]: string }
-- 	local packages = manifest.packages :: any
-- 	if not packages then
-- 		packages = {}
-- 		manifest.packages = packages
-- 	end
-- 	if not packageType then
-- 		local answer = stdio.prompt("select", "Choose a package type: (Shared)", {
-- 			"Shared",
-- 			"Server",
-- 			"Core",
-- 			"Development"
-- 		})
-- 		if not answer then
-- 			answer = 1
-- 		end
-- 		packageType = if answer == 1 then "shared" elseif answer == 2 then "server" else "core"
-- 	end
-- 	local dependencies = packages[packageType]
-- 	if not dependencies then
-- 		dependencies = {}
-- 		packages[packageType] = dependencies
-- 	end
-- 	return dependencies
-- end

local cli = argparse("kitty")
local init = cli:command("init", "Initializes a kitty project")
init:option("--path", "Project path")
init:action(function(arg: { path: string? })
	kittyManifest:setProjectPath(arg.path)
	if pathfs.isFile(kittyManifest:getPath()) then
		context.panic(`There is already a Kitty project in this directory. Manifest file ({kittyManifest:getPath()}) already exists.`)
	end
	local name = stdio.prompt("text", "Project name: (untitled)\n")
	if name == "" then
		name = "untitled"
	end
	local version = stdio.prompt("text", "Inital version: (0.1.0)\n") or "0.1.0"
	if version == "" then
		version = "0.1.0"
	end
	kittyManifest:write({
		name = name,
		version = version,
		packages = {
			registry = "https://github.com/UpliftGames/wally-index"
		}
	})
end)
local add = cli:command("add", "Add a package")
add:argument("name", "Package name to add")
add:option("--path", "Project path")
add:option("--index", "Package index")
add:action(function(arg: { name: string, path: string?, index: string? })
	kittyManifest:setProjectPath(arg.path)
	local manifest = kittyManifest:read()
	local index = WallyIndex.new(manifest.packages.registry)
	local name, package = index:findPackage(arg.name)
	local packages = kittyManifest:getPackages(arg.index)
	packages[name] = package
	kittyManifest:write(manifest)
end)

local install = cli:command("install", "Fetch added packages and install them")
install:action(function()

end)

local wally = cli:command("wally", "Wally commands that depends on wally")
local wallyLogin = wally:command("login", "Login into a registry")
wallyLogin:action(function()
	print("hi")
end)

cli:parse()
