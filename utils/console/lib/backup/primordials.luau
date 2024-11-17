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

return {
    arrayPrototypeUnshift=arrayPrototypeUnshift,
    reflectConstruct=reflectConstruct,
    reflectApply=reflectApply,
}