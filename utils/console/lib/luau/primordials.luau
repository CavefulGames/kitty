--!strict
local typeError = require(script.Parent:WaitForChild('typeError'))

local function reflectConstruct(func, args)
    func(table.unpack(args))
end

local function reflectApply(target, self, args, ...)
    if typeof(args) ~= 'table' then
        args = { args, ... }
    end
    if self == nil then
        return target(table.unpack(args))
    else
        return target(self, table.unpack(args))
    end
end

local function arrayPrototypeUnshift(arr, ...)
    for _, v in { ... } do
        table.insert(arr, 1, v)
    end
    return arr 
end 

local function objectKeys(obj)
    local result = {}
    for _, v in obj do
        table.insert(result, tostring(v))
    end
    return result
end

local function objectValues(obj)
    local result = {}
    for v, _ in obj do
        table.insert(result, v)
    end
    return result
end

local function objectAssign(...)
    local args = { ... }
    local arr = args[1]
    for i=2, #args - 1, 1 do
        for k, v in args[i] do
            arr[k] = v
        end
    end
    return arr
end

local function stringPrototypeRepeat(str: string, num: number)
    local result = ''
    for i=1, num do
        result ..= str
    end
    return result
end

local function arrayPrototypeMap<T>(array: { [number]: T }, call: (v: T, i: number) -> (any))
    local result = {}
    for i, v in array do
        result[i] = call(v, i)
    end
    return result
end

local function mathMaxApply(array: { [number]: number }): number
    local result: number
    for _, v in array do
        if not result then
            result = v
            continue
        end

        if result < v then
            result = v 
        end
    end
    return result
end

local function mathMax(...: number)
    local result: number
    for _, v in { ... } do
        if not result then
            result = v 
            continue
        end

        if result < v then
            result = v
        end
    end
    return result
end

local function arrayPrototypeJoin(array: { [number]: string }, str: string?)
    local result = ''
    str = str::string or ',' :: string

    for i=1, #array do
        result ..= `{array[i]}{str}`
    end

    return result
end

local function stringPrototypeSlice(str: string, start: number?, end_: number?): string
    start = (start or 0)
    if start < 0 then
        start = math.max(#str + start :: number, 0)
    else
        start = math.min(start :: number, #str)
    end
    
    end_ = (end_ or #str)
    if end_ < 0 then
        end_ = math.max(#str + end_ :: number, 0)
    else
        end_ = math.min(end_ :: number, #str)
    end
    
    if start >= end_ then
        return ""
    end
    
    return string.sub(str, start :: number + 1, end_)
end

local function stringPrototypePadStart(str: string, size: number, addStr: string)
    if #str >= size then
        return str
    end

    for i=1, size - #str do
        str = addStr .. str
    end

    return str
end

local function isArray(arr)
    if typeof(arr) ~= 'table' then
        return false
    end
    for k, _ in arr do
        if typeof(k) ~= 'number' then
            return false
        end
    end

    return true
end

local function isObject(arr)
    if typeof(arr) ~= 'table' then
        return false
    end
    for k, _ in arr do
        if typeof(k) == 'number' then
            return false
        end
    end

    return true
end

local function getOwnPropertyDescriptor(obj: any, key: string)
    if not isObject(obj) then
        error(typeError.new("Object must be an object"))
    end

    local mt = getmetatable(obj)
    if mt and type(mt.__propertyDescriptors) == "table" then
        return mt.__propertyDescriptors[key]
    end

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

--[=[
-- local function formatWithOptions(str, arr)
--     print(str, arr)
--     for k, v in arr do
--         -- if typeof(v) == 'table' then
--         --     formatWithOptions(str, v)
--         -- end 
--         (str::string):format(v)
--     end
--     return str
-- end
--]=]

local function getObjectOrArrayLen(arrOrObj)
    local result = 0
    for k, v in arrOrObj do
        result += 1
    end
    return result
end

local function escapeString(str)
    return string.gsub(str, '["\\\n\r\t]', {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    })
end

local function formatWithOptions(options, value, recurseTimes)
    options = options or {}
    recurseTimes = tonumber(recurseTimes) or 0
    
    options.depth = options.depth or 2
    options.colors = options.colors or false
    options.maxArrayLength = options.maxArrayLength or 100
    options.breakLength = options.breakLength or 80
    options.compact = options.compact or 3
    options.sorted = options.sorted or false
    
    if recurseTimes > options.depth then
        return '"[Maximum depth reached]"'
    end
    
    if typeof(value) == "nil" then
        return "nil"
    end
    
    if typeof(value) == "number" then
        if value ~= value then
            return "NaN"
        elseif value == math.huge then
            return "Infinity"
        elseif value == -math.huge then
            return "-Infinity"
        end
        return tostring(value)
    end
    
    if typeof(value) == "string" then
        return '"' .. escapeString(value) .. '"'
    end
    
    if typeof(value) == "boolean" then
        return tostring(value)
    end
    
    if typeof(value) == "function" then
        return "[Function]"
    end
    
    if typeof(value) == "table" then
        local result = {}
        
        if isArray(value) then
            if #value == 0 then
                return "[]"
            end
            
            table.insert(result, "[")
            local elements = {}
            
            local length = math.min(#value, options.maxArrayLength)
            
            for i = 1, length do
                table.insert(elements, 
                    formatWithOptions(options, value[i], recurseTimes + 1))
            end
            
            if #value > options.maxArrayLength then
                table.insert(elements, "... " .. (#value - options.maxArrayLength) .. " more items")
            end

            if options.compact <= recurseTimes then
                table.insert(result, "\n  " .. table.concat(elements, ",\n  ") .. "\n")
            else
                table.insert(result, " " .. table.concat(elements, ", ") .. " ")
            end
            
            table.insert(result, "]")
            
        else
            if next(value) == nil then
                return "{}"
            end
            
            table.insert(result, "{")
            local elements = {}
            
            local keys = {}
            for k in pairs(value) do
                table.insert(keys, k)
            end
            
            if options.sorted then
                table.sort(keys)
            end
            
            for _, k in ipairs(keys) do
                local formattedKey = type(k) == "string" and 
                    k:match("^[%a_][%w_]*$") and k or 
                    formatWithOptions(options, k :: any, recurseTimes + 1)
                
                local formattedValue = formatWithOptions(options, value[k], recurseTimes + 1)
                table.insert(elements, formattedKey .. ": " .. formattedValue)
            end
            
            if options.compact <= recurseTimes then
                table.insert(result, "\n  " .. table.concat(elements, ",\n  ") .. "\n")
            else
                table.insert(result, " " .. table.concat(elements, ", ") .. " ")
            end
            
            table.insert(result, "}")
        end
        
        return table.concat(result)
    end
    
    return tostring(value)
end

local function isExtensible(value: any): boolean
    if type(value) ~= "table" then
        return false
    end
    
    local mt = getmetatable(value)
    if mt and mt.__extensible ~= nil then
        return mt.__extensible
    end
    
    return true
end

local function numberPrototypeToFixed(num: number, fixPos: number)
    return (10 * fixPos) / math.round(num * (10 * fixPos))
end

return {
    arrayPrototypeUnshift=arrayPrototypeUnshift,
    arrayPrototypeMap=arrayPrototypeMap,
    arrayPrototypeJoin=arrayPrototypeJoin,
    reflectConstruct=reflectConstruct,
    reflectApply=reflectApply,
    formatWithOptions=formatWithOptions,
    stringPrototypeRepeat=stringPrototypeRepeat,
    stringPrototypeSlice=stringPrototypeSlice,
    stringPrototypePadStart=stringPrototypePadStart,
    numberPrototypeToFixed=numberPrototypeToFixed,
    mathMaxApply=mathMaxApply,
    mathMax=mathMax,
    escapeString=escapeString,
    getOwnPropertyDescriptor=getOwnPropertyDescriptor,
    getObjectOrArrayLen=getObjectOrArrayLen,
    objectKeys=objectKeys,
    objectValues=objectValues,
    objectAssign=objectAssign,
    isArray=isArray,
    isObject=isObject,
    isExtensible=isExtensible,
}