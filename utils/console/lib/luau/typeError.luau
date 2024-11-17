--!strict
local primordials = {}

-- 기본 Error 클래스 정의
local Error = {}
Error.__index = Error

function Error.new(message: string?)
    local self = setmetatable({}, Error)
    self.message = message or ""
    self.name = "Error"
    self._stack = nil
    Error.captureStackTrace(self, Error.new)
    return self
end

function Error.captureStackTrace(targetObject: any, constructorOpt: (...any) -> any?)
    local stack = debug.traceback("", 2)
    -- V8 스타일의 스택트레이스로 변환
    stack = stack:gsub("stack traceback:", ""):gsub("\n%s+", "\n    at ")
    targetObject._stack = stack
end

function Error:getStack()
    return self._stack
end

-- TypeError 클래스 정의
local TypeError = setmetatable({}, {__index = Error})
TypeError.__index = TypeError

export type TypeError = {
    new: (message: string?) -> TypeError,
    message: string,
    name: string,
    code: string?,
    toString: (self: TypeError) -> string,
    getStack: (self: TypeError) -> string?,
}

function TypeError.new(message: string?): TypeError
    local self = setmetatable(Error.new(message), TypeError)
    self.name = "TypeError"
    self.code = nil
    return self
end

function TypeError:toString(): string
    return string.format("%s: %s", self.name, self.message)
end

-- 에러 코드 정의
local ERR_CODES = {
    ERR_INVALID_ARG_TYPE = "ERR_INVALID_ARG_TYPE",
    ERR_INVALID_ARG_VALUE = "ERR_INVALID_ARG_VALUE",
    ERR_OUT_OF_RANGE = "ERR_OUT_OF_RANGE",
}

-- Node.js 스타일의 에러 생성 함수들
local function createInvalidArgType(name: string, expected: string, actual: string): TypeError
    local message = string.format(
        'The "%s" argument must be of type %s. Received %s',
        name, expected, actual
    )
    local error = TypeError.new(message)
    error.code = ERR_CODES.ERR_INVALID_ARG_TYPE
    return error
end

local function createInvalidArgValue(name: string, value: any, reason: string): TypeError
    local message = string.format(
        'The value "%s" is invalid for argument "%s". %s',
        tostring(value), name, reason
    )
    local error = TypeError.new(message)
    error.code = ERR_CODES.ERR_INVALID_ARG_VALUE
    return error
end

-- primordials 객체 설정
primordials.Error = Error
primordials.TypeError = TypeError

-- 타입 체크 유틸리티
local function isNaN(value: number): boolean
    return value ~= value
end

local function validateInteger(value: any, name: string)
    if type(value) ~= "number" then
        error(createInvalidArgType(name, "number", type(value)))
    end
    if isNaN(value) or value % 1 ~= 0 then
        error(createInvalidArgValue(name, value, "Must be an integer"))
    end
end

-- 테스트 헬퍼
local function assert(condition: boolean, message: string?)
    if not condition then
        error(TypeError.new(message or "Assertion failed"))
    end
end

-- 사용 예제
local function validatePort(port: any)
    validateInteger(port, "port")
    if port < 0 or port > 65535 then
        local err = TypeError.new("Port should be >= 0 and < 65536")
        err.code = ERR_CODES.ERR_OUT_OF_RANGE
        error(err)
    end
end

return {
    primordials = primordials,
    TypeError = TypeError,
    createInvalidArgType = createInvalidArgType,
    createInvalidArgValue = createInvalidArgValue,
    validateInteger = validateInteger,
    validatePort = validatePort,
    assert = assert,
    ERR_CODES = ERR_CODES
}