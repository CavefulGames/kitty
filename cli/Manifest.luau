--!strict

local tomlstruct = require("../submodules/tomlstruct")
local pathfs = require("pathfs")
local context = require("context")
local stdio = require("@lune/stdio")

export type Manifest<T> = {
	name: string,
	fileName: string,
	toml: tomlstruct.TomlStruct<T>,
	cache: T?,
	packageIndexPathModifierRoute: { string }?,
	_projectPath: pathfs.AsPath?,
	_cachedPath: pathfs.AsPath?,
	_packageIndexes: {
		{
			defaultPath: string,
			route: { string },
			name: string
		}
	}?,

	new: (name: string, ...tomlstruct.KVItem) -> (Manifest<T>),
	read: (self: Manifest<T>) -> (T),
	write: (self: Manifest<T>, manifest: T) -> (),
	getPackages: (self: Manifest<T>, packageIndexName: string?) -> ({ [string]: string }),
	getPath: (self: Manifest<T>) -> (pathfs.AsPath),
	setProjectPath: (self: Manifest<T>, projectPath: pathfs.AsPath?) -> (),
	addPackageIndex: (self: Manifest<T>, name: string, route: { string }, defaultPath: string) -> (),
	require: (self: Manifest<T>) -> (),
	notFound: (self: Manifest<T>) -> (never),
}

local Manifest = {} :: Manifest<any>
(Manifest :: any).__index = Manifest

function Manifest.new(name, ...)
	return setmetatable({
		name = name,
		fileName = name:lower() .. ".toml",
		toml = tomlstruct(...),
	}, Manifest) :: any
end

function Manifest.getPath(self)
	if self._cachedPath then
		return self._cachedPath
	end
	local path = self.fileName
	if self._projectPath then
		path = pathfs.Path.from(self._projectPath):join(path)
	end
	self._cachedPath = path
	return path
end

function Manifest.setProjectPath(self, projectPath)
	self._cachedPath = nil
	self._projectPath = projectPath
end

function Manifest.read(self)
	local path = self:getPath()
	local exist = pathfs.isFile(path)
	if exist then
		local manifest = self.toml:decode(pathfs.readFile(path)) :: any
		self.cache = manifest
		return manifest
	end
	return self:notFound()
end

function Manifest.write(self, manifest)
	local path = self:getPath()
	pathfs.writeFile(path, self.toml:encode(manifest :: any))
end

function Manifest.addPackageIndex(self, name, route, defaultPath)
	local packageIndexes = self._packageIndexes
	if packageIndexes then
		packageIndexes = {}
		self._packageIndexes = packageIndexes
	end
	table.insert(packageIndexes :: any, {
		name = name,
		route = route,
		defaultPath = defaultPath
	})
end

function Manifest.getPackages(self, packageIndexName)
	local packageIndexes = self._packageIndexes
	if not packageIndexes then
		error("Package indexes are required to get packages")
	end
	local packageIndex
	if packageIndexName then
		for _, v in packageIndexes do
			if v.name == packageIndexName then
				packageIndex = v
				break
			end
		end
	else
		local options = {}
		for _, v in packageIndexes do
			table.insert(options, v.name)
		end
		local answer = stdio.prompt("select", `Choose a package index: ({options[1]})`, options)
		if not answer then
			answer = 1
		end
		packageIndex = packageIndexes[answer]
	end
	if not packageIndex then
		error("Could not find package index")
	end
	local manifest = self.cache :: any
	if not manifest then
		manifest = self:read()
	end
	local packages
	for _, strip in packageIndex.route do
		local head = manifest[strip]
		if not head then
			head = {}
			manifest[strip] = head
		end
		packages = head
	end
	return packages
end

function Manifest.require(self)
	local exist = pathfs.isFile(self:getPath())
	if not exist then
		self:notFound()
	end
end

function Manifest.notFound(self)
	return context.panic(`Not a {self.name} project, Check if '{self:getPath()}' exists.`)
end

return Manifest
