--!strict

export type SafeMap = typeof(setmetatable({} :: {
    value: { [any]: any }
}, {} :: SafeMapImpl))

type SafeMapImpl = {
    __index: SafeMapImpl,
    new: () -> (SafeMap),
    set: (self: SafeMap, key: any, value: any) -> (),
    get: (self: SafeMap, key: any) -> (any),
    has: (self: SafeMap, Key: any) -> (boolean),
    delete: (self: SafeMap, key: any) -> (boolean),
    clear: (self: SafeMap) -> (),
    size: (self: SafeMap) -> (number),
}


local safeMap = {} :: SafeMapImpl
safeMap.__index = safeMap

function safeMap.new()
    return setmetatable({ 
        value = {} 
    }, safeMap)
end

function safeMap.set(self, key, value)
    assert(key ~= nil, "Key cannot be nil")
    self.value[key] = value
end

function safeMap.get(self, key)
    assert(key ~= nil, "Key cannot be nil")
    return self.value[key]
end

function safeMap.has(self, key)
    assert(key ~= nil, "Key cannot be nil")
    return self.value[key] ~= nil
end

function safeMap.delete(self, key)
    assert(key ~= nil, "Key cannot be nil")
    if self.value[key] ~= nil then
        self.value[key] = nil
        return true
    end
    return false
end

function safeMap.clear(self)
    self.value = {}
end

function safeMap.size(self)
    local count = 0
    for _ in pairs(self.value) do
        count += 1
    end
    return count
end

return safeMap
