local tableUtil = require(script.Parent.roblox_packages["table-util"])
local Store = require(script.Store)

export type Store<T, K> = Store.Store<T, K>

local tableHelper = {}

function tableHelper.createKeyMap<T, K, V>(builder: (key: K) -> T & { [K]: V }): T
	local t = builder(true :: any)
	for key, _ in t :: any do
		(t :: any)[key] = key
	end

	return t
end

function tableHelper.createNameMap<T>(builder: (name: string) -> T & { [string]: string }): T
	local t = builder(true :: any)
	for key, _ in t :: any do
		(t :: any)[key] = key
	end

	return t
end

function tableHelper.setToArray<K>(set: { [K]: boolean }): { K }
	local arr = {}
	for k, v in set do
		if v then
			table.insert(arr, k)
		end
	end
	return arr
end

function tableHelper.arrayToSet<K>(arr: { K }): { [K]: boolean }
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end

function tableHelper.set(t: {}, path: { any }, value: any)
	local current = t
	for i = 1, #path - 1 do
		local key = path[i]
		if not current[key] then
			current[key] = {}
		end
		current = current[key]
	end
	current[path[#path]] = value
end

tableHelper.Store = Store

tableHelper.assign = tableUtil.Assign
tableHelper.copy = tableUtil.Copy
tableHelper.decodeJSON = tableUtil.DecodeJSON
tableHelper.encodeJSON = tableUtil.EncodeJSON
tableHelper.every = tableUtil.Every
tableHelper.extend = tableUtil.Extend
tableHelper.filter = tableUtil.Filter
tableHelper.find = tableUtil.Find
tableHelper.flat = tableUtil.Flat
tableHelper.flatMap = tableUtil.FlatMap
tableHelper.isEmpty = tableUtil.IsEmpty
tableHelper.keys = tableUtil.Keys
tableHelper.lock = tableUtil.Lock
tableHelper.map = tableUtil.Map
tableHelper.reconcile = tableUtil.Reconcile
tableHelper.reduce = tableUtil.Reduce
tableHelper.reverse = tableUtil.Reverse
tableHelper.sample = tableUtil.Sample
tableHelper.shuffle = tableUtil.Shuffle
tableHelper.some = tableUtil.Some
tableHelper.swapRemove = tableUtil.SwapRemove
tableHelper.swapRemoveFirstValue = tableUtil.SwapRemoveFirstValue
tableHelper.sync = tableUtil.Sync
tableHelper.truncate = tableUtil.Truncate
tableHelper.values = tableUtil.Values
tableHelper.zip = tableUtil.Zip

return tableHelper
