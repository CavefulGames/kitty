type Props = { [string]: any }

export type All<T> = typeof(setmetatable(
	{} :: {
		_elements: { T },
		_props: Props
	},
	{} :: AllImpl
))

type AllImpl = {
	__index: Props, -- __index: <T>(self: All<T>, key: string) -> any,
	__newindex: <T>(self: All<T>, key: string, value: any) -> (),
	new: <T>(elements: { T }) -> All<T>
}

local All = {} :: AllImpl

-- function All.__index(self, key)

-- end

function All.__newindex<T>(self: All<T>, key, value)
	self._props[key] = value
	for _, element in self._elements do
		(element :: any)[key] = value
	end
end

function All.new(elements)
	local props = {}
	return setmetatable({
		_elements = elements,
		_props = props
	}, {
		__index = props,
		__newindex = All.__newindex,
		new = All.new
	})
end

return All
