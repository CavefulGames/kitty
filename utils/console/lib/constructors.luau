--!strict
local console = require(script.Parent:WaitForChild('luau'):WaitForChild('console'))
local constructor = require(script:WaitForChild('luau'):WaitForChild('console'))

local listenerCount = {}
local baseOptions = { 
    removeListener = function(str)
        listenerCount[str] = 0
    end,
    once = function(str)
        listenerCount[str] += 1
    end,
    listenerCount = function(str)
        return listenerCount[str]
    end 
}

local logOptions = table.clone(baseOptions)
logOptions.write = function(str)
    print(str)
end

local warnOptions = table.clone(baseOptions)
warnOptions.write = function(str)
    warn(str)
end

local errorOptions = table.clone(baseOptions)
errorOptions.write = function(str)
    error(str)
end

return {
    logConstructor = constructor.new(logOptions),
    warnConstructor = constructor.new(warnOptions),
    errorConstructor = constructor.new(errorOptions),
}