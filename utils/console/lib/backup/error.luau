--!strict
type ErrorOptions = {
    cause: any?,
}

export type Error = {
    new: (message: string?, options: ErrorOptions?) -> Error,
    message: string,
    name: string,
    stack: string?,
    cause: any?,
    toString: (self: Error) -> string,
    captureStackTrace: (targetObject: any, constructor: (...any) -> any?) -> (),
}

-- Error 클래스 구현
local Error = {}
Error.__index = Error

-- Error.prototype.name
Error.prototype = {
    name = "Error"
}

-- Error.stackTraceLimit
Error.stackTraceLimit = 10

-- prepareStackTrace 커스텀 포매팅 함수 (기본값)
local function defaultPrepareStackTrace(err: Error, stackTraces: {string}): string
    local result = err.name .. ": " .. err.message
    for _, trace in ipairs(stackTraces) do
        result = result .. "\n    at " .. trace
    end
    return result
end

Error.prepareStackTrace = defaultPrepareStackTrace

function Error.new(message: string?, options: ErrorOptions?): Error
    local self = setmetatable({}, Error)
    
    -- message 처리
    self.message = if type(message) == "string" then message else ""
    
    -- name 설정
    self.name = "Error"
    
    -- options 처리
    if options then
        self.cause = options.cause
    end
    
    -- stack trace 캡처
    Error.captureStackTrace(self, Error.new)
    
    return self :: any
end

function Error.captureStackTrace(targetObject: any, constructor: (...any) -> any?)
    -- 기본 스택 트레이스 생성
    local stack = debug.traceback("", 2)
    
    -- 스택 트레이스 파싱 및 포맷팅
    local stackTraces = {}
    local skipNext = false
    
    for line in string.gmatch(stack, "[^\n]+") do
        -- "stack traceback:" 라인 스킵
        if line:match("stack traceback:") then
            continue
        end
        
        -- 생성자 이후의 스택만 포함
        if constructor and skipNext then
            continue
        end
        
        -- 내부 구현 디테일 라인 필터링
        if line:match("%.%.%.") or line:match("%[C%]") then
            continue
        end
        
        -- 라인 정보 파싱
        local func, location = line:match("%s*([^%s].*) ([^%s]+)$")
        if func and location then
            -- 불필요한 접두사 제거
            func = func:gsub("in function ", "")
            -- 위치 정보 정리
            location = location:gsub("%.%.%.", "")
            
            local formattedTrace = func .. " " .. location
            table.insert(stackTraces, formattedTrace)
            
            -- 스택 트레이스 제한 확인
            if #stackTraces >= Error.stackTraceLimit then
                break
            end
        end
    end
    
    -- Error.prepareStackTrace 사용하여 최종 스택 문자열 생성
    targetObject.stack = Error.prepareStackTrace(targetObject, stackTraces)
end

function Error:toString(): string
    return `{self.name} : {self.message}`
end

-- 서브클래스 생성을 위한 유틸리티 함수
local function inherits(childClass: any, parentClass: any)
    childClass.prototype = setmetatable({}, {__index = parentClass.prototype})
    childClass.__index = childClass
    setmetatable(childClass, {__index = parentClass})
end

-- TypeError 구현
local TypeError = setmetatable({}, {__index = Error})
TypeError.__index = TypeError

function TypeError.new(message: string?, options: ErrorOptions?): Error
    local self = Error.new(message, options)
    setmetatable(self, TypeError)
    self.name = "TypeError"
    return self :: any
end

inherits(TypeError, Error)

-- ReferenceError 구현
local ReferenceError = setmetatable({}, {__index = Error})
ReferenceError.__index = ReferenceError

function ReferenceError.new(message: string?, options: ErrorOptions?): Error
    local self = Error.new(message, options)
    setmetatable(self, ReferenceError)
    self.name = "ReferenceError"
    return self :: any
end

inherits(ReferenceError, Error)

-- 테스트 유틸리티
local function assertEqual(actual: any, expected: any, message: string?)
    if actual ~= expected then
        error(string.format("%s: expected %s but got %s", 
            message or "Assertion failed",
            tostring(expected),
            tostring(actual)
        ))
    end
end

-- 사용 예시와 테스트
local function runTests()
    -- 기본 Error 테스트
    local err = Error.new("test error")
    assertEqual(err.message, "test error")
    assertEqual(err.name, "Error")
    assert(err.stack ~= nil)
    
    -- TypeError 테스트
    local typeErr = TypeError.new("invalid type")
    assertEqual(typeErr.message, "invalid type")
    assertEqual(typeErr.name, "TypeError")
    assert(typeErr.stack ~= nil)
    
    -- Error with cause 테스트
    local causeErr = Error.new("outer error", {
        cause = Error.new("inner error")
    })
    assertEqual(causeErr.message, "outer error")
    assert(causeErr.cause ~= nil)
    assertEqual(causeErr.cause.message, "inner error")
    
    -- 커스텀 prepareStackTrace 테스트
    local originalPrepare = Error.prepareStackTrace
    Error.prepareStackTrace = function(err, stackTraces)
        return "Custom: " .. err.message
    end
    
    local customErr = Error.new("custom stack")
    assert(string.match(customErr.stack :: any, "^Custom: "))
    
    -- 원래 prepareStackTrace 복구
    Error.prepareStackTrace = originalPrepare
    
    print("All tests passed!")
end

-- 예외 처리 예시
local function throwExample()
    error(Error.new("Something went wrong", {
        cause = TypeError.new("Invalid input")
    }))
end

return {
    Error = Error,
    TypeError = TypeError,
    ReferenceError = ReferenceError,
    runTests = runTests,
    throwExample = throwExample
}