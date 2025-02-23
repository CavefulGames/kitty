local gt = require(script.Parent.roblox_packages.greentea)

local CONSTRUCTOR_KEY = function() end

type Bank<T, K=any> = ((key: K) -> T) & {
	[K]: T,
	keyType: K?
} & {
	[() -> ()]: () -> T
}

type BankStatic = {
	__index: BankStatic,
	__call: <T, K>(self: Bank<T, K>, key: K) -> T,
	new: <T, K>(constructor: () -> T, keyType: K?) -> Bank<T, K>,
}

local Bank = {} :: BankStatic

local constructorTypeChecker = gt.build(gt.anyfn())
function Bank.new(constructor, keyType)
	constructorTypeChecker:assert(constructor)

	return setmetatable({
		[CONSTRUCTOR_KEY] = constructor,
		keyType = keyType,
	}, Bank) :: any
end

function Bank.__call(self, key)
	local value = (self :: any)[key]
	if value then
		return value
	end
	value = (self :: any)[CONSTRUCTOR_KEY]()
	;(self :: any)[key] = value
	return value
end

return Bank
