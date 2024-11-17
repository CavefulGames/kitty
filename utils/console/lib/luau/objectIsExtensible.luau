--!strict
-- objectIsExtensible.lua
local TypeError = require("./error").TypeError

export type ExtensibleObject = {
    __extensible: boolean,
    [any]: any
}

-- Object.isExtensible 구현
local function isExtensible(value: any): boolean
    -- 기본 타입 체크
    if type(value) ~= "table" then
        return false
    end
    
    -- 메타테이블 체크
    local mt = getmetatable(value)
    if mt and mt.__extensible ~= nil then
        return mt.__extensible
    end
    
    -- 기본적으로 Lua 테이블은 확장 가능
    return true
end

-- Object.preventExtensions 구현
local function preventExtensions(obj: any): any
    if type(obj) ~= "table" then
        error(TypeError.new("Object.preventExtensions called on non-object"))
    end
    
    -- 메타테이블 생성 또는 가져오기
    local mt = getmetatable(obj) or {}
    mt.__extensible = false
    mt.__newindex = function(t, k, v)
        if rawget(t, k) == nil then
            error(TypeError.new("Cannot add property '" .. tostring(k) .. "', object is not extensible"))
        end
        rawset(t, k, v)
    end
    setmetatable(obj, mt)
    
    return obj
end

-- Object.seal 구현
local function seal(obj: any): any
    if type(obj) ~= "table" then
        error(TypeError.new("Object.seal called on non-object"))
    end
    
    -- 기존 프로퍼티를 configurable: false로 설정
    local mt = getmetatable(obj) or {}
    mt.__extensible = false
    mt.__newindex = function(t, k, v)
        if rawget(t, k) == nil then
            error(TypeError.new("Cannot add property '" .. tostring(k) .. "', object is sealed"))
        end
        rawset(t, k, v)
    end
    
    -- 프로퍼티 삭제 방지
    mt.__metatable = "sealed"  -- 메타테이블 변경 방지
    
    setmetatable(obj, mt)
    return obj
end

-- Object.freeze 구현
local function freeze(obj: any): any
    if type(obj) ~= "table" then
        error(TypeError.new("Object.freeze called on non-object"))
    end
    
    -- 모든 프로퍼티를 읽기 전용으로 설정
    local mt = getmetatable(obj) or {}
    mt.__extensible = false
    mt.__newindex = function(t, k, v)
        error(TypeError.new("Cannot assign to read only property '" .. tostring(k) .. "' of object"))
    end
    
    -- 프로퍼티 삭제 방지
    mt.__metatable = "frozen"  -- 메타테이블 변경 방지
    
    setmetatable(obj, mt)
    return obj
end

-- Object.isFrozen 구현
local function isFrozen(obj: any): boolean
    if type(obj) ~= "table" then
        return true  -- 원시 타입은 항상 frozen
    end
    
    local mt = getmetatable(obj)
    return mt and mt.__metatable == "frozen"
end

-- Object.isSealed 구현
local function isSealed(obj: any): boolean
    if type(obj) ~= "table" then
        return true  -- 원시 타입은 항상 sealed
    end
    
    local mt = getmetatable(obj)
    return mt and (mt.__metatable == "sealed" or mt.__metatable == "frozen")
end

-- 테스트 유틸리티
local function assert(condition: boolean, message: string?)
    if not condition then
        error(TypeError.new(message or "Assertion failed"))
    end
end

return {
    isExtensible = isExtensible,
    preventExtensions = preventExtensions,
    seal = seal,
    freeze = freeze,
    isFrozen = isFrozen,
    isSealed = isSealed,
}