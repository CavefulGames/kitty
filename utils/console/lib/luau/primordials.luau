local function reflectConstruct(func, args)
    func(table.unpack(args))
end

local function reflectApply(target, self, args)
    return target(self, table.unpack(args))
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
    local start = (start or 0) :: number
    if start < 0 then
        start = math.max(#str + start, 0)
    else
        start = math.min(start, #str)
    end
    
    local end_ = (end_ or #str) :: number
    if end_ < 0 then
        end_ = math.max(#str + end_, 0)
    else
        end_ = math.min(end_, #str)
    end
    
    if start >= end_ then
        return ""
    end
    
    return string.sub(str, start + 1, end_)
end

local function isArray(arr)
    for k, _ in arr do
        if typeof(k) ~= 'number' then
            return false
        end
    end

    return true
end

local function isObject(arr)
    for k, _ in arr do
        if typeof(k) == 'number' then
            return false
        end
    end

    return true
end

return {
    arrayPrototypeUnshift=arrayPrototypeUnshift,
    arrayPrototypeMap=arrayPrototypeMap,
    arrayPrototypeJoin=arrayPrototypeJoin,
    reflectConstruct=reflectConstruct,
    reflectApply=reflectApply,
    stringPrototypeRepeat=stringPrototypeRepeat,
    stringPrototypeSlice=stringPrototypeSlice,
    mathMaxApply=mathMaxApply,
    mathMax=mathMax,
    objectKeys=objectKeys,
    objectAssign=objectAssign,
    isArray=isArray,
    isObject=isObject,
}