local errorState = require(script.Parent.errorState)
local types = require(script.Parent.types)

--[=[
	인수 타입 체킹 유틸리티
]=]
local arguments = {}

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
function arguments.createExpectException<T>(value: T, typeName: types.BasicTypes, ...: string?)
	local t = typeof(value)
	local message = concatMessage(...)
	return `{message}{typeName} expected, got {t}`
end

--[=[
	선택적 예상의 예외 메시지를 생성합니다.

	```lua
	error(Strict.createOptionalExpectException("wrong value", "number")) --- (optional) number expected, got string
	```
]=]
function arguments.createOptionalExpectException<T>(value: T?, typeName: types.BasicTypes, ...: string?)
	local t = typeof(value)
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
function arguments.expect<T>(value: T, typeName: types.BasicTypes?, ...: string?): never?
	local t = typeof(value)
	if typeName then
		if t ~= typeName then
			return error(arguments.createExpectException(value, typeName), errorState.level)
		end
	elseif value == nil then
		local message = concatMessage(...)
		return error(`{message}missing or nil`, errorState.level)
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
function arguments.expectOptional<T>(value: T?, typeName: types.BasicTypes, ...: string?): never?
	local t = typeof(value)
	if value ~= nil and t ~= typeName then
		return error(arguments.createOptionalExpectException(value, typeName, ...), errorState.level)
	end
	return
end

return arguments
