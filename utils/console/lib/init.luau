--!strict
local constructors = require(script:WaitForChild('constructors'))
local type = require(script:WaitForChild('type'))

local console = {}

function console.log(...)
    constructors.logConstructor:log(...)
end

function console.count(...)
    constructors.logConstructor:count(...)
end

function console.countReset(...)
    constructors.logConstructor:countReset(...)
end

function console.debug(...)
    constructors.logConstructor:debug(...)
end

function console.dir(...)
    constructors.logConstructor:dir(...)
end

function console.dirxml(...)
    constructors.logConstructor:dirxml(...)
end

function console.group(...)
    constructors.logConstructor:group(...)
end

function console.groupCollapsed(...)
    constructors.logConstructor:groupCollapsed(...)
end

function console.groupEnd(...)
    constructors.logConstructor:groupEnd(...)
end

function console.info(...)
    constructors.logConstructor:info(...)
end

function console.time(...)
    constructors.logConstructor:time(...)
end

function console.timeEnd(...)
    constructors.logConstructor:timeEnd(...)
end

function console.timeLog(...)
    constructors.logConstructor:timeLog(...)
end

function console.table(...)
    constructors.logConstructor:table(...)
end

function console.tree(...)
    constructors.logConstructor:tree(...)
end

function console.warn(...)
    constructors.warnConstructor:log(...)
end

function console.trace(...)
    constructors.warnConstructor:trace(...)
end

function console.error(...)
    constructors.errorConstructor:log(...)
end

function console.assert(...)
    constructors.errorConstructor:assert(...)
end

return console :: type.Console