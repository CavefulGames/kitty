local types = require(script.Parent.types)

return function<T>(self: types.Group<T>, arguments: { T }): number?
	for i, v in arguments do
		if typeof(v) ~= "Instance" or v:IsA(self.elementsClassName) then
			return i
		end
	end
end
