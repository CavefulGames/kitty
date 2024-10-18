--!strict
-- inspired by nodejs console and C# Debug

local Debugger = {}

local RunService = game:GetService("RunService")

local isStudio = RunService:IsStudio()
local MutableTypeKey = function() end

local function typecheckMutable(propertyName: string, mutable: any, value: any)
	local typeName = typeof(value)
	if not (typeName == "nil" and mutable.optional) then
		if typeName ~= mutable.typeName then
			error(`Unable to assign property {propertyName}. {mutable.typeName} expected, got {typeName}`)
		end
	end
end

--[=[
	모듈의 속성은 `Debugger.Mutable` 제외 읽기 전용이며 키값은 문자열만 허용됩니다.

	성능에 지장을 줄 수 있으므로 `_G.__DEV__ = true`인 상태에서만 메타테이블을 사용하여 런타임 타입 체킹을 수행합니다.

	```lua
	local module = Debugger.Module("MyModule", {
		something = 123,
		[123] = "foo", -- not ok
		some = 1
	})
	module.something = nil -- not ok
	module.some = "a" -- not ok
	print(module.something) -- ok
	```
]=]
function Debugger.Module<T>(name: string, module: T): T
	if type(module) ~= "table" then
		error("Module must be a table!")
	end

	local mutableProperties = {}
	for k: string, v: any in module do
		if type(k) ~= "string" then
			error(`Only string is allowed as a module's field in strict mode, got {k}({typeof(k)})`, 2)
		end
		local mutable = v[MutableTypeKey]
		if mutable then
			typecheckMutable(k, mutable, mutable.value)
			mutableProperties[k] = mutable
			module[k] = nil
		end
	end
	-- selene: allow(global_usage)
	if _G.__DEV__ then
		setmetatable(module :: any, {
			__index = function(_, key)
				local mutable = mutableProperties[key]
				if mutable then
					return mutable.value
				end
				error(`{tostring(key)} is not a valid member of {name}`)
			end,
			__newindex = function(_, key, value)
				local mutable = mutableProperties[key]
				if mutable then
					typecheckMutable(key, mutable, value)
					mutable.value = value
				end
				error(`{tostring(key)} is not a valid member of {name}`)
			end
		})
	end
	return module
end

--[=[
	`Debugger.Module`에 가변 속성을 정의합니다.

	타입은 정적이며 빈 속성은 `Debugger.Mutable(nil, "typeName?")`으로 정의 가능합니다.

	`Debugger.Module`의 속성이며, `_G.__DEV__ = true`인 상태에서만 동작합니다.

	```lua
	local module = Debugger.Module({
		property = Debugger.Mutable(123),
		emptyThing = Debugger.Mutable(nil, "string?") :: string? -- waiting for type functions..
	})

	module.property = 1000 -- ok
	module.property = "a" -- not ok

	module.emptyThing = 123 -- not ok
	module.emptyThing = "a" -- ok
	```
]=]
function Debugger.Mutable<T>(initialValue: T, typeName: string?): T
	-- selene: allow(global_usage)
	return if _G.__DEV__ then {
		[MutableTypeKey] = {
			value = initialValue,
			typeName = if typeName then if typeName:sub(-1) == "?" then typeName:sub(1, -2) else typeName else typeof(typeName),
			optional = if typeName then typeName:sub(-1) == "?" else false
		}
	} else initialValue :: any
end

Debugger.enabled = Debugger.Mutable(false)

if isStudio then
	-- selene: allow(global_usage)
	_G.__DEV__ = true
end

return Debugger.Module("Debugger", Debugger)
