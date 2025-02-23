-- heavily inspired by https://github.com/Sleitnick/RbxUtil/blob/main/modules/tree/init.luau

local observers = require(script.Parent.roblox_packages.observers)
local utils = require(script.utils)
local SEPARATOR = require(script.SEPARATOR)
local gt = require(script.Parent.roblox_packages.greentea)

local InstanceType = gt.build(gt.Instance())
local stringType = gt.build(gt.string())
local optionalStringType = gt.build(gt.opt(gt.string()))
local optionalNumberType = gt.build(gt.opt(gt.number()))

local function fetchedWrongError(fetchedClassName: string, expectedClassName: string): string
	return `The ClassName of the fetched instance is '{fetchedClassName}', but '{expectedClassName}' was expected.`
end

local inst = {}

inst.class = function(className: string): string
	return className
end :: ((string) -> string) & typeof(Instance.new)

function inst.fetch(
	parent: typeof(InstanceType:type()),
	path: typeof(stringType:type()),
	expectedClassName: typeof(optionalStringType:type())
): Instance
	InstanceType:assert(parent)
	stringType:assert(path)
	optionalStringType:assert(expectedClassName)

	local instance = parent
	local components = path:split(SEPARATOR)

	for _, comp in components do
		if comp == "" then
			error(`Invalid path '{path}'`, 2)
		end

		local found = instance:FindFirstChild(comp)
		if not found then
			error(`Failed to find '{path}' in '{utils.fullNameToPath(parent)}'`, 2)
		end
		instance = found
	end

	if expectedClassName and not instance:IsA(expectedClassName) then
		error(fetchedWrongError(instance.ClassName, expectedClassName), 2)
	end

	return instance
end

function inst.find(
	parent: typeof(InstanceType:type()),
	path: typeof(stringType:type()),
	expectedClassName: typeof(optionalStringType:type())
): Instance?
	InstanceType:assert(parent)
	stringType:assert(path)
	optionalStringType:assert(expectedClassName)

	local instance = parent
	local components = path:split(SEPARATOR)

	for _, comp in components do
		if comp == "" then
			error(`Invalid path '{path}'`, 2)
		end

		local found = instance:FindFirstChild(comp)
		if not found then
			return nil
		end
		instance = found
	end

	if expectedClassName and not instance:IsA(expectedClassName) then
		error(fetchedWrongError(instance.ClassName, expectedClassName), 2)
	end

	return instance
end

function inst.waitFor(
	parent: typeof(InstanceType:type()),
	path: typeof(stringType:type()),
	timeout: typeof(optionalNumberType:type()),
	expectedClassName: typeof(optionalStringType:type())
): Instance?
	InstanceType:assert(parent)
	stringType:assert(path)
	optionalNumberType:assert(timeout)
	optionalStringType:assert(expectedClassName)

	local instance = parent
	local components = path:split(SEPARATOR)

	for _, comp in components do
		if comp == "" then
			error(`Invalid path '{path}'`, 2)
		end

		if timeout then
			local found = instance:WaitForChild(comp, timeout)
			if not found then
				error(`Failed to find '{path}' in '{utils.fullNameToPath(parent)}'`, 2)
			end
			instance = found
		else
			instance = instance:WaitForChild(comp)
		end
	end

	if expectedClassName and not instance:IsA(expectedClassName) then
		error(fetchedWrongError(instance.ClassName, expectedClassName), 2)
	end

	return instance
end

inst.print = utils.print
inst.debug = utils.debug

inst.observeAttribute = observers.observeAttribute
inst.observeCharacter = observers.observeCharacter
inst.observePlayer = observers.observePlayer
inst.observeProperty = observers.observeProperty
inst.observeTag = observers.observeTag

return inst
