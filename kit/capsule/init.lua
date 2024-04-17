local Capsule = {}

function Capsule.Property<T>(initialValue:T):(newValue:T?)->(T)
	local value = initialValue
	local t = typeof(initialValue)
	return function(newValue:T?):T
		if newValue then
			if typeof(newValue) ~= t then
				error(`{t} expected, got {typeof(newValue)}`,2)
			end
			value = newValue
		end
		return value
	end
end

Capsule.strictMode = Capsule.Property(true)

return table.freeze(setmetatable(Capsule,{
	__call=function(self,module)
		if Capsule.strictMode() then
			for k:string,v:any in module do
				if type(k) ~= "string" then
					if Capsule.strictMode() then
						error(`Only string is allowed as a module's key in strict mode, got {k}({typeof(k)})`,2)
					end
					continue
				end
				local firstLetter = k:sub(1,1)
				if type(v) ~= "function" and firstLetter ~= string.lower(firstLetter) then
					local meta = getmetatable(v)
					if meta and (meta.__call == nil or type(meta) == "table") then --- metatable has __call or locked
						continue
					end
					error(`Only 'lowerCamelCase' is allowed as a property in strict mode, got {k}`,2)
				end
			end
		end
		return table.freeze(module)
	end
}))
