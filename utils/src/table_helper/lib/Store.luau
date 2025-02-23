local gt = require(script.Parent.Parent.roblox_packages.greentea)

export type Store<T, K=any> = ((key: K) -> T) & {
	[K]: T,
	constructor: () -> T,
	keyType: K?
}

type BankStatic = {
	__index: BankStatic,
	__call: <T, K>(self: Store<T, K>, key: K) -> T,
	new: <T, K>(constructor: () -> T, keyType: K?) -> Store<T, K>,
}

local Store = {} :: BankStatic

local constructorTypeChecker = gt.build(gt.anyfn())
function Store.new(constructor, keyType)
	constructorTypeChecker:assert(constructor)

	return table.freeze(setmetatable({
		constructor = constructor,
		keyType = keyType,
	}, Store)) :: any
end

function Store.__call(self, key)
	local value = (self :: any)[key]
	if value then
		return value
	end
	value = self.constructor()
	;(self :: any)[key] = value
	return value
end

return Store
