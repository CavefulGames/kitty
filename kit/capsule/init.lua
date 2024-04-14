local Capsule = {}

function Capsule.Source(initialValue:any)
	local value = initialValue
	local t = typeof(initialValue)
	return function(newValue:any)
		if newValue then
			if typeof(newValue) ~= t then
				error(`{t} expected, got {typeof(newValue)}`)
			end
			value = newValue
		end
		return value
	end
end

return setmetatable(Capsule,{
	__call=function(self,module)
		return table.freeze(module)
	end
})
