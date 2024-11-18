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

return {
    arrayPrototypeUnshift=arrayPrototypeUnshift,
    reflectConstruct=reflectConstruct,
    reflectApply=reflectApply,
    objectKeys=objectKeys,
    objectAssign=objectAssign,
}