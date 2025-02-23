local types = require(script.Parent.types)
local errorState = require(script.Parent.errorState)
local arguments = require(script.Parent.arguments)

export type Tuple = typeof(setmetatable(
	{} :: {
		index: number,
	},
	{} :: TupleImpl
))

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
	expect: <T>(self: Tuple, value: T, typeName: types.BasicTypes) -> (Tuple),
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
	expectOptional: <T>(self: Tuple, value: T?, typeName: types.BasicTypes) -> (Tuple),
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

--[=[
	@class Tuple
	튜플 형식으로 Strict 런타임 타입 체크를 하기 위한 클래스
]=]
local Tuple = {} :: TupleImpl
Tuple.__index = Tuple

function Tuple.new()
	return setmetatable({ index = 1 }, Tuple)
end

function Tuple.expect<T>(self: Tuple, value: T, typeName)
	--error message example: Bad tuple index #1: string expected, got nil
	errorState.level = 3
	arguments.expect(value, typeName, "Bad tuple index #", tostring(self.index), ":")
	errorState.level = 2
	self.index += 1
	return self
end

function Tuple.expectOptional<T>(self: Tuple, value: T?, typeName)
	errorState.level = 3
	arguments.expectOptional(value, typeName, "Bad tuple index #", tostring(self.index), ":")
	errorState.level = 2
	self.index += 1
	return self
end

function Tuple.skip(self: Tuple)
	self.index += 1
	return self
end

function Tuple.from(self: Tuple, newIndex: number)
	self.index = newIndex
	return self
end

return Tuple
