local arguments = require(script.arguments)
local Tuple = require(script.Tuple)

--[=[
	@class Strict

	런타임 타입 체킹을 위한 라이브러리
]=]
local strict = {}
strict.Tuple = Tuple
strict.createExpectException = arguments.createExpectException
strict.createOptionalExpectException = arguments.createOptionalExpectException
strict.expect = arguments.expect
strict.expectOptional = arguments.expectOptional

local mutableIdentifier = {}
local nothingIdentifier = function() end

local function typecheckMutable(propertyName: string, mutable: any, value: any)
	local typeName = typeof(value)
	if not (typeName == "nil" and mutable.optional) then
		local mutableTypeName = mutable.typeName
		if mutableTypeName ~= "any" and typeName ~= mutableTypeName then
			error(`Unable to assign property {propertyName}. {mutable.typeName} expected, got {typeName}`, 2)
		end
	end
end

--[=[
	모듈의 속성은 `strict.mut` 제외 읽기 전용이며 키값은 문자열만 허용됩니다.

	프로덕션 환경 성능에 지장을 줄 수 있으므로 `_G.__DEV__ = true`인 상태에서만 메타테이블을 사용하여 런타임 타입 체킹을 수행합니다.

	```luau
	local module = strict.table({
		mutable = strict.mut(123),
		emptyThing = strict.mut(nil, "string?"),
		anything = strict.mut(nil, "any"),
		nothing = strict.nothing
	}, "module name for debug")

	module.mutable = 1000 -- ok
	module.mutable = "a" -- not ok

	module.emptyThing = 123 -- not ok
	module.emptyThing = "a" -- ok

	module.anything = "abc" -- ok
	module.anything = 123 -- ok

	print(module.sans) -- not ok
	print(module.nothing) -- ok
	```
]=]
function strict.table<T>(tbl: T, name: string?): T
	if type(tbl) ~= "table" then
		error(`Attempt to create a strict table from '{typeof(tbl)}'`)
	end
	-- selene: allow(global_usage)
	if _G.__DEV__ then
		if getmetatable(tbl) then
			error("strict tables are not supported for metatables")
		end
		name = name or "<unnamed strict table>"

		local properties = {} -- { [K]: V }
		local mutables = {} -- { [K]: mutable }
		for k: string, v: any in tbl do
			local mutable = getmetatable(v) == mutableIdentifier and v or nil
			if mutable then
				typecheckMutable(k, mutable, mutable.value)
				properties[k] = mutable.value
				mutables[k] = mutable
			else
				properties[k] = v
			end
			tbl[k] = nil
		end

		setmetatable(tbl :: any, {
			__index = function(_, key)
				local value = properties[key]
				if value ~= nil then
					if value == nothingIdentifier then
						return nil
					end
					return value
				end
				error(`{tostring(key)} is not a valid member of {name}`, 2)
			end,
			__newindex = function(_, key, value)
				if properties[key] == nil then
					error(`{tostring(key)} is not a valid member of {name}`, 2)
				end
				local mutable = mutables[key]
				if mutable then
					typecheckMutable(key, mutable, value)
					mutable.value = value
					properties[key] = value
				else
					error(`Cannot assign to '{name}.{key}', as '{key}' is not declared as mutable`, 2)
				end
			end,
			__iter = function()
				return next, properties
			end
		})
	end
	return tbl
end

--[=[
	`strict.table`에 가변 속성을 정의합니다.

	타입은 정적이며 빈 속성은 `strict.mut(nil, "typeName?")`으로 정의 가능합니다.

	`strict.table`의 속성이며, `_G.__DEV__ = true`인 상태에서만 동작합니다.
]=]
strict.mut = (function<T>(initialValue: T, typeName: string?): T
	-- selene: allow(global_usage)
	if _G.__DEV__ then
		local optional: boolean?
		if typeName then
			optional = typeName:sub(-1) == "?"
			if optional then
				typeName = typeName:sub(1, -2)
			end
		else
			typeName = typeof(initialValue)
		end
		return setmetatable({
			value = initialValue,
			typeName = typeName,
			optional = optional
		}, mutableIdentifier) :: any
	end
	return initialValue
end :: any) :: ((initialValue: nil, typeName: "string?") -> string?)
	& ((initialValue: nil, typeName: "boolean?") -> boolean?)
	& ((initialValue: nil, typeName: "number?") -> number?)
	& ((initialValue: nil, typeName: "table?") -> {}?)
	& ((initialValue: nil, typeName: "function?") -> ((any?) -> (any?))?)
	& ((initialValue: nil, typeName: "Instance?") -> Instance?)
	& ((initialValue: nil, typeName: "thread?") -> thread?)
	& ((initialValue: nil, typeName: "buffer?") -> buffer?)
	& ((initialValue: nil, typeName: "Vector3?") -> Vector3?)
	& ((initialValue: nil, typeName: "CFrame?") -> CFrame?)
	& (<T>(initialValue: T, typeName: "any") -> any)
	& (<T>(initialValue: T, typeName: string?) -> T)

--[=[
	`strict.table`에 `nil`값을 가진 속성을 정의합니다.
]=]
strict.nothing = (nothingIdentifier :: any) :: nil

return strict.table(strict, "strict")
