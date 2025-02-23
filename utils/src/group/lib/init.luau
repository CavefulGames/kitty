local All = require(script.All)
local types = require(script.types)
local magicGroups = require(script.magicGroups)
local groupMethodsImpl = require(script.Parent.groupMethodsImpl)
local checkElement = require(script.Parent.checkElement)
local emitter = require(script.Parent.emitter)

local Group = {} :: types.GroupImpl
Group.__index = Group

function Group.__tostring<T>(self: types.Group<T>)
	return `Group::{self.name}<{self.elementsClassName}>` -- ex. Group::abcd<Part>
end

Group.new = function<T>(className: string, name: string): types.Group<T>
	local MagicGroup = magicGroups[className]
	if MagicGroup then
		return setmetatable(MagicGroup.new(name), Group)
	end
	local elements = {}
	return setmetatable({
		_elements = elements,
		all = All.new(elements) :: any,
		name = name
	}, Group)
end :: any

function Group.namespace(namespace)
	local groups = namespace(Group.new :: any)
	for name, group in (groups :: any) :: { [string]: types.Group<any> } do
		group.name = name
	end
	return groups
end

local function getInvalidArgumentError<T>(self: types.Group<T>, verb: string, index: number, arguments: T): string
	local v = arguments[index]
	-- todo: replace instance pretty priting with `inst.print`
	return `Invalid argument #{i} to '{verb}' (Attempt to {verb} '{v}{typeof(v) == "Instance" and `({v:GetFullName()})` or ""}' into a group '{self}')`
end

function Group.push<T>(self: types.Group<T>, ...: T)
	do
		local args = {...}
		local wrongArgument = checkElement(self, args)
		if wrongArgument then
			error(getInvalidArgumentError(self, "push", wrongArgument + 1, args))
		end
	end
	local src = table.pack(...)
	local srcLength = src.n
	if srcLength == 0 then
		return
	elseif srcLength == 1 then
		local length = self.n + 1
		self[length] = ...
		self.n = length
		return
	end
	local length = self.n
	self.n = length + srcLength
	table.move(src, 1, srcLength, length + 1, self)
end

function Group.remove<T>(self: types.Group<T>, ...: T)
	local args = {...}
	do
		local wrongArgument = checkElement(self, args)
		if wrongArgument then
			error(getInvalidArgumentError(self, "remove", wrongArgument + 1, args))
		end
	end
	for _, v in args do
		local indexToRemove = table.find(self, v)
		if indexToRemove then
			table.remove(self, indexToRemove)
			self.n -= 1
		end
	end
end

function Group.clear<T>(self: types.Group<T>)
	table.clear(self)
	self.n = 0
end

return Group
