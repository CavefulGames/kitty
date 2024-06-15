--!strict

--// $Packages
--[=[
	@class Strict
	런타임 타입 체킹을 위한 라이브러리
]=]
local Strict = {}

local typeKey = function() end
local errorLevel = 2

--// $Types
export type BasicTypes = "string" | "number" | "boolean" | "table" | "function" | string
--[=[
	@class Tuple
	튜플 형식으로 Strict 런타임 타입 체크를 하기 위한 클래스
]=]
type TupleImpl = {
	__index: TupleImpl,
	--[=[
		런타임 타입 체킹을 위한 튜플 오브젝트를 생성합니다.
		@within Tuple
	]=]
	new: () -> Tuple,
	--[=[
		튜플에서 값을 예상합니다.

		```lua
		local function foo(a: number, b: string)
			Strict.Tuple()
			:expect(a, "number") -- Bad tuple index #1: number expected, got string
			:expect(b, "string")
		end

		foo("wrong type", "correct type")
		```
	]=]
	expect: <T>(self: Tuple, value: T, typeName: BasicTypes) -> (Tuple),
	--[=[
		튜플에서 선택적 값으로 예상합니다.

		```lua
		local function foo(a: number?, b: string?)
			Strict.Tuple()
			:expectOptional(a, "number") -- Bad tuple index #1: number expected, got string
			:expectOptional(b, "string")
		end

		foo("wrong type", nil)
		```
	]=]
	expectOptional: <T>(self: Tuple, value: T?, typeName: BasicTypes) -> (Tuple),
	--[=[
		현재 튜플 index를 한번 건너뜁니다.

		```lua
		local function foo(a: number, b: any, c: string)
			Strict.Tuple()
			:expect(a, "number")
			:skip()
			:expect(b, "string")
		end

		foo(123, { anything = 123 }, "example")
		```
	]=]
	skip: (self: Tuple) -> (Tuple),
	--[=[
		인덱스를 변경하고 현재 튜플을 재반환합니다.
	]=]
	from: (self: Tuple, newIndex: number) -> (Tuple)
}

local Tuple = {} :: TupleImpl
Tuple.__index = Tuple
Strict.Tuple = Tuple
export type Tuple = typeof(setmetatable(
    {} :: {
        index: number,
    },
    {} :: TupleImpl
))

function Tuple.new()
	return setmetatable({ index = 1 }, Tuple)
end

function Tuple:expect<T>(value: T, typeName)
	--error message example: Bad tuple index #1: string expected, got nil
	errorLevel = 3
	Strict.expect(value, typeName, "Bad tuple index #", tostring(self.index), ":")
	errorLevel = 2
	self.index += 1
	return self
end

function Tuple:expectOptional<T>(value: T?, typeName)
	errorLevel = 3
	Strict.expectOptional(value, typeName, "Bad tuple index #", tostring(self.index), ":")
	errorLevel = 2
	self.index += 1
	return self
end

function Tuple:skip()
	self.index += 1
	return self
end

function Tuple:from(newIndex: number)
	self.index = newIndex
	return self
end

local function concatMessage(...: string?): string
	local tbl = { ... }
	local m = ""
	if #tbl > 0 then
		m = table.concat(tbl)
		m ..= " "
	end
	return m
end

--[=[
	예상의 예외 메시지를 생성하기 위한 구조체입니다.

	```lua
	error(Strict.ExpectException("wrong value", "number")) --- number expected, got string
	```
]=]
function Strict.ExpectException<T>(value: T, typeName: BasicTypes, ...: string?)
	local t = Strict.typeof(value)
	local message = concatMessage(...)
	return `{message}{typeName} expected, got {t}`
end

--[=[
	선택적 예상의 예외 메시지를 생성하기 위한 구조체입니다.

	```lua
	error(Strict.OptionalExpectException("wrong value", "number")) --- (optional) number expected, got string
	```
]=]
function Strict.OptionalExpectException<T>(value: T?, typeName: BasicTypes, ...: string?)
	local t = Strict.typeof(value)
	local message = concatMessage(...)
	return `{message}(optional) {typeName} expected, got {t}`
end

--[=[
	런타임에서 주어진 값에 대해 특정 타입으로 예상합니다.
	값의 타입과 주어진 타입이 일치하지 않으면 오류가 발생합니다.

	```lua
	Strict.expect(123, "number") --- ok
	Strict.expect("wrong value", "number") --- number expected, got string
	```
]=]
function Strict.expect<T>(value: T, typeName: BasicTypes?, ...: string?): never?
	local t = Strict.typeof(value)
	if typeName then
		if t ~= typeName then
			return error(Strict.ExpectException(value, typeName), errorLevel)
		end
	elseif value == nil then
		local message = concatMessage(...)
		return error(`{message}missing or nil`, errorLevel)
	end
	return
end

--[=[
	런타임에서 주어진 값에 대해 nil 가능성이 존재하는 특정 타입으로 예상합니다.
	값과 타입과 주어진 타입이 일치하지 않으면 오류가 발생합니다.
	주어진 값이 nil이여도 오류가 발생하지 않습니다.

	```lua
	Strict.expectOptional(nil, "number") --- ok
	Strict.expectOptional(123, "number") --- ok
	Strict.expectOptional("wrong value", "number") --- number expected, got string
	```
]=]
function Strict.expectOptional<T>(value: T?, typeName: BasicTypes, ...: string?): never?
	local t = Strict.typeof(value)
	if value ~= nil and t ~= typeName then
		return error(Strict.OptionalExpectException(value, typeName), errorLevel)
	end
	return
end

--[=[
	주어진 모듈(테이블)을 캡슐화합니다.
	read-only가 적용되여 수정이 불가능해집니다.
	테이블 인수는 대체적으로 모듈이 적합하며, 모듈의 필드 타입을 검사하여 키가 모두 문자열인지 확인합니다.

	```lua
	local Encapsulated = Strict.Capsule({
		something = 123,
		[123] = "foo" --- not ok
	})
	Encapsulated.something = nil --- not ok
	```
]=]
function Strict.Capsule(module)
	for k: string, v: any in module do
		if type(k) ~= "string" then
			error(`Only string is allowed as a module's field in strict mode, got {k}({typeof(k)})`, 2)
		end
		-- local firstLetter = k:sub(1, 1)
		-- if type(v) ~= "function" and firstLetter ~= string.lower(firstLetter) then
		-- 	local meta = getmetatable(v)
		-- 	if meta and (meta.__call == nil or type(meta) == "table") then --- metatable has __call or locked
		-- 		continue
		-- 	end
		-- 	error(`Only 'lowerCamelCase' is allowed as a property in strict mode, got {k}`, 2)
		-- end
	end
	return table.freeze(module)
end

--[=[
	외부에서 변경 가능하고 런타입 타입 체킹 가능한 가변 변수를 만들고 setter/getter 인터페이스를 생성합니다.
	read-only 테이블 안에서 사용하는 것이 적합합니다.

	```lua
	local value = Strict.createValue(123)
	print(value()) --- getter
	value(value() + 1) --- setter
	value("wrong value") --- not ok
	```
]=]
function Strict.createValue<T>(initialValue: T, callback: (newValue: T) -> ()?): (newValue: T?) -> T
	local value = initialValue
	local t = typeof(initialValue)
	return function(newValue: T?): T
		if newValue == nil then
			return value
		end
		if typeof(newValue) ~= t then
			error(`{t} expected, got {typeof(newValue)}`, 2)
		end
		local oldValue = value
		value = newValue
		if callback then
			callback(newValue)
		end
		return oldValue
	end
end

--[=[
	Strict.typeof로 타입을 확인 가능한 타입이 적용된 오브젝트로 변경하여 반환합니다.

	```lua
	local myTypedObject = Strict.TypedObject("Kitty", {
		name = "kitty"
	})
	print(Strict.typeof(myTypedObject)) --- output: "Kitty"
	```
]=]
function Strict.TypedObject<T>(typeName: BasicTypes, t: T?): T
	Strict.Tuple.new():expect(typeName, "string"):expectOptional(t, "table")
	if type(t) ~= "table" then
		error(Strict.ExpectException(t, "table"))
	end
	local tbl = t or {}
	tbl[typeKey] = typeName
	return tbl
end

--[=[
	TypedObject를 포합하여 주어진 값의 타입을 반환합니다.

	```lua
	assert(Strict.typeof(123) == typeof(123))
	```
]=]
function Strict.typeof(value: any): string
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
