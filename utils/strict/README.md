# Strict
런타임에서 엄격한 유형검사를 위한 간단한 라이브러리

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
