--!strict

--$Packages
local Debugger = require(script.Parent.debugger)
--[=[
	@class Strict
	런타임 타입 체킹을 위한 라이브러리
]=]
local Strict = {}

local typeKey = function() end
local errorLevel = 2

--$Types
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
	예상의 예외 메시지를 생성합니다.

	```lua
	error(Strict.createExpectException("wrong value", "number")) --- number expected, got string
	```
]=]
function Strict.createExpectException<T>(value: T, typeName: BasicTypes, ...: string?)
	local t = Strict.typeof(value)
	local message = concatMessage(...)
	return `{message}{typeName} expected, got {t}`
end

--[=[
	선택적 예상의 예외 메시지를 생성합니다.

	```lua
	error(Strict.createOptionalExpectException("wrong value", "number")) --- (optional) number expected, got string
	```
]=]
function Strict.createOptionalExpectException<T>(value: T?, typeName: BasicTypes, ...: string?)
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
			return error(Strict.createExpectException(value, typeName), errorLevel)
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
		return error(Strict.createOptionalExpectException(value, typeName, ...), errorLevel)
	end
	return
end

--[=[
	런타임 타입 체킹을 위한 변수 getter/setter를 생성합니다.

	```lua
	local value = Strict.createValue(1)
	value(2) -- ok
	value("aaa") -- not ok
	print(value()) -- getter
	```
]=]
function Strict.createValue<T>(initialValue: T, callback: (newValue: T) -> ()?): (newValue: T?) -> (T)
	local value = initialValue
	local t = Strict.typeof(initialValue)
	return function(newValue: T?): T
		if newValue == nil then
			return value
		end
		if Strict.typeof(newValue) ~= t then
			error(`{t} expected, got {Strict.typeof(newValue)}`, 2)
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
	런타임 타입 체킹 가능한 비어있는 가변 변수를 만들고 setter/getter 인터페이스를 반환합니다.
]=]
function Strict.createEmptyValue(typeName: BasicTypes, callback: (newValue: any) -> ()?): (newValue: any) -> ()
	local value = nil
	local t = typeName
	return function(newValue)
		if newValue == nil then
			return value
		end
		if Strict.typeof(newValue) ~= t then
			error(`{t} expected, got {Strict.typeof(newValue)}`, 2)
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
	`Strict.typeof`로 타입을 확인 가능한 타입이 적용된 오브젝트로 변경하여 반환합니다.

	```lua
	local myTypedTable = Strict.TypedTable("Kitty", {
		name = "kitty"
	})
	print(Strict.typeof(myTypedTable)) --- output: "Kitty"
	```
]=]
function Strict.TypedTable<T>(typeName: BasicTypes, tbl: T?): T
	Strict.Tuple.new():expect(typeName, "string"):expectOptional(tbl, "table")
	if type(tbl) ~= "table" then
		error(Strict.createExpectException(tbl, "table"))
	end
	tbl = tbl or {}
	tbl[typeKey] = typeName
	return tbl
end

--[=[
	`TypedTable`를 포합하여 주어진 값의 타입을 반환합니다.

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

--[=[
	`Strict.TypedTable`로 지정된 타입을 제거합니다.

	```lua
	local t = Strict.TypedTable("kitty")
	Strict.removeType(t)
	assert(Strict.typeof(t) == "table")
	```
]=]
function Strict.removeType<T>(typedTable: T)
	if type(typedTable) ~= "table" then
		error(Strict.createExpectException(typedTable, "table"))
	end
	typedTable[typeKey] = nil
end

return Debugger.Module(Strict)
