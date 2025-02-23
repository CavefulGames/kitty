local inext = require(script.Parent.Parent.inext)

export type All = typeof(setmetatable(
	{} :: {
		_props: { [string]: any },
		_group: { any }
	},
	{} :: AllImpl
))

type AllImpl = {
	__index: (self: All, key: string) -> any,
	__newindex: (self: All, key: string, value: any) -> (),
	new: (group: { any }) -> All
}

local All = {}

function All.__index(self, key)
	return self._props[key]
end

function All.__newindex(self, key, value)
	self._props[key] = value
	for _, element in inext, self._group, 0 do
		(element :: any)[key] = value
	end
end

function All.new(group)
	return setmetatable({
		_props = {},
		_group = group
	}, All)
end

return All
