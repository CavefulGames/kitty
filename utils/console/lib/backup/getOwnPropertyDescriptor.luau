--!strict
local TypeError = require(script.Parent.typeError).TypeError

export type PropertyDescriptor = {
    value: any?,
    writable: boolean?,
    enumerable: boolean?,
    configurable: boolean?,
    get: (() -> any)?,
    set: ((value: any) -> ())?,
}

local function isObject(value: any): boolean
    return type(value) == "table"
end

local function toPropertyDescriptor(obj: any): PropertyDescriptor
    if not isObject(obj) then
        error(TypeError.new("Property description must be an object"))
    end

    local desc: PropertyDescriptor = {}

    -- 데이터 디스크립터와 접근자 디스크립터를 동시에 가질 수 없음
    if obj.get ~= nil or obj.set ~= nil then
        if obj.value ~= nil or obj.writable ~= nil then
            error(TypeError.new(
                "Invalid property descriptor. Cannot both specify accessors and a value or writable attribute"
            ))
        end
    end

    -- get과 set은 함수이거나 undefined여야 함
    if obj.get ~= nil and type(obj.get) ~= "function" then
        error(TypeError.new("Property descriptor get must be callable"))
    end
    if obj.set ~= nil and type(obj.set) ~= "function" then
        error(TypeError.new("Property descriptor set must be callable"))
    end

    -- 속성 복사
    if obj.enumerable ~= nil then
        desc.enumerable = not not obj.enumerable  -- boolean으로 변환
    end
    if obj.configurable ~= nil then
        desc.configurable = not not obj.configurable
    end
    if obj.value ~= nil then
        desc.value = obj.value
    end
    if obj.writable ~= nil then
        desc.writable = not not obj.writable
    end
    if obj.get ~= nil then
        desc.get = obj.get
    end
    if obj.set ~= nil then
        desc.set = obj.set
    end

    return desc
end

local function getOwnPropertyDescriptor(obj: any, key: string): PropertyDescriptor?
    if not isObject(obj) then
        error(TypeError.new("Object must be an object"))
    end

    -- 메타테이블을 통해 속성 정보 가져오기
    local mt = getmetatable(obj)
    if mt and type(mt.__propertyDescriptors) == "table" then
        return mt.__propertyDescriptors[key]
    end

    -- 기본 속성 가져오기
    if rawget(obj, key) ~= nil then
        return {
            value = rawget(obj, key),
            writable = true,
            enumerable = true,
            configurable = true
        }
    end

    return nil
end

local function defineProperty(obj: any, key: string, descriptor: PropertyDescriptor): any
    if not isObject(obj) then
        error(TypeError.new("Object must be an object"))
    end

    local desc = toPropertyDescriptor(descriptor)
    
    -- 메타테이블 생성 또는 가져오기
    local mt = getmetatable(obj) or {}
    if not mt.__propertyDescriptors then
        mt.__propertyDescriptors = {}
    end

    -- 디스크립터 저장
    mt.__propertyDescriptors[key] = desc

    -- getter/setter 구현
    if desc.get or desc.set then
        mt.__index = mt.__index or {}
        mt.__newindex = mt.__newindex or {}
        
        if type(mt.__index) == "table" then
            local oldIndex = mt.__index
            mt.__index = function(t, k)
                if k == key and desc.get then
                    return desc.get()
                end
                return oldIndex[k]
            end
        end
        
        if type(mt.__newindex) == "table" then
            local oldNewIndex = mt.__newindex
            mt.__newindex = function(t, k, v)
                if k == key and desc.set then
                    return desc.set(v)
                end
                oldNewIndex[k] = v
            end
        end
    else
        -- 데이터 속성 설정
        rawset(obj, key, desc.value)
    end

    setmetatable(obj, mt)
    return obj
end

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


return {
    getOwnPropertyDescriptor = getOwnPropertyDescriptor,
    defineProperty = defineProperty,
    toPropertyDescriptor = toPropertyDescriptor,
}