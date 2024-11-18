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

return {
    arrayPrototypeUnshift=arrayPrototypeUnshift,
    reflectConstruct=reflectConstruct,
    reflectApply=reflectApply,
    objectKeys=objectKeys,
}