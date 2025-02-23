# English

## Strict
A simple library for strict type checking at runtime.

## 사용 예시
```lua
local function foo(a: number)
	Strict.expect(a, "number")
end

local function bar(a: string?, c: any, b: {})
	Strict.Tuple.new(a, b)
		:expectOptional("string")
		:skip()
		:expect("table")
end

local function baz<T>(a: T): number
	if type(a) == "string" then -- for the lsp
		error(Strict.createExpectException(a, "string"))
	end
	return #a
end
```

## TODO
- [ ] 커스텀 타입 관련 `typeof`, `TypedObject` 삭제
