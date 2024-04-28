--// dependencies
local Strict = {}

local typeKey = function()end
local errorLevel = 2

export type BasicTypes = "string"|"number"|"boolean"|"table"|"function"|string

local Tuple = {}
Tuple.__index = Tuple

function Tuple:expect<T>(value:T,typeName:BasicTypes?)
	--error message example: Bad tuple index #1: string expected, got nil
	errorLevel = 3
	Strict.expect(value,typeName,"Bad tuple index #",self.index,":")
	errorLevel = 2
	self.index += 1
	return self
end

function Tuple:expectOptional<T>(value:T,typeName:BasicTypes)
	errorLevel = 3
	Strict.expectOptional(value,typeName,"Bad tuple index #",self.index,":")
	errorLevel = 2
	self.index += 1
	return self
end

function Tuple:skip()
	self.index += 1
	return self
end

local function concatMessage(...:string?):string
	local tbl = {...}
	local m = ""
	if #tbl > 0 then
		m = table.concat(tbl)
		m ..= " "
	end
	return m
end

function Strict.ExpectException<T>(value:T,typeName:BasicTypes,...:string?)
	local t = Strict.typeof(value)
	local message = concatMessage(...)
	return `{message}(optional) {typeName} expected, got {t}`
end

function Strict.expect<T>(value:T,typeName:BasicTypes?,...:string?):never?
	local t = Strict.typeof(value)
	if typeName then
		if t ~= typeName then
			return error(Strict.ExpectException(value,typeName),errorLevel)
		end
	elseif value == nil then
		local message = concatMessage(...)
		return error(`{message}missing or nil`,errorLevel)
	end
	return
end

function Strict.expectOptional<T>(value:T,typeName:BasicTypes,...:string?)
	local t = Strict.typeof(value)
	if value ~= nil and t ~= typeName then
		return error(Strict.ExpectException(value,typeName),errorLevel)
	end
	return
end

function Strict.Capsule(module)
	for k:string,v:any in module do
		if type(k) ~= "string" then
			error(`Only string is allowed as a module's key in strict mode, got {k}({typeof(k)})`,2)
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
	return table.freeze(module)
end

function Strict.Mutable<T>(initialValue:T,callback:(newValue:T)->()):(newValue:T?)->(T)
	local value = initialValue
	local t = typeof(initialValue)
	return function(newValue:T?):T
		if newValue then
			if typeof(newValue) ~= t then
				error(`{t} expected, got {typeof(newValue)}`,2)
			end
			value = newValue
			callback(newValue)
		end
		return value
	end
end

function Strict.Tuple()
	return setmetatable({index=1},Tuple)
end

function Strict.Table<T>(typeName:BasicTypes,t:T?):T
	Strict.Tuple()
		:expect(typeName,"string")
		:expectOptional(t,"table")
	local tbl = t or {}
	tbl[typeKey] = typeName
	return tbl
end

function Strict.typeof(value:any):string
	local typeName = typeof(value)
	if typeName == "table" then
		local customType = value[typeKey]
		if customType ~= nil then
			typeName = customType
		end
	end
	return typeName
end

return Strict.Capsule(Strict)
