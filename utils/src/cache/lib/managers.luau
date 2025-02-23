local types = require(script.Parent.types)
local gt = require(script.Parent.Parent.roblox_packages.greentea)

local EXPAND_BY_AMOUNT = 50

local circularConfigType = gt.build(gt.table({
	index = gt.number(),
}))
local circular = {} :: types.BaseCacheManager<
	Instance,
	typeof(circularConfigType:type())
>

local optionalCircularConfigType = gt.build(gt.opt(circularConfigType:type()))
function circular.init(self, config)
	optionalCircularConfigType:assert(config)

	self.index = config and config.index or 1
end

function circular.get(self)
	local newIndex = self.index % self.size + 1
	self.index = newIndex
	return self[newIndex]
end

local fixed = {} :: types.BaseCacheManager<Instance>

function fixed.get(self)
	local object = table.remove(self :: { Instance })
	if not object then
		error("Cache is out of objects", 3)
	end
	return object
end

-- function fixed.free(self, object)
-- 	table.insert(self, object)
-- end
fixed.free = table.insert

local dynamicConfigType = gt.build(gt.table({
	expandAmount = gt.opt(gt.number()),
	warnIfExceeds = gt.opt(gt.union(gt.number(), gt.boolean())),
}))
local dynamic = {} :: types.BaseCacheManager<
	Instance,
	typeof(dynamicConfigType:type())
>

local optionalDynamicConfigType = gt.build(gt.opt(dynamicConfigType:type()))
function dynamic.init(_self, config)
	optionalDynamicConfigType:assert(config)
end

function dynamic.get(self)
	local object = table.remove(self :: { Instance })
	if not object then
		self:expand(self.expandAmount or EXPAND_BY_AMOUNT)
		-- selene: allow(shadowing)
		local object = table.remove(self :: { Instance })
		if not object then
			error("unreachable")
		end
		return object
	end
	return object
end

dynamic.free = table.insert

return {
	circular = circular,
	fixed = fixed,
	dynamic = dynamic,
}
