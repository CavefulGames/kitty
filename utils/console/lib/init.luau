--!strict
local listenerCount = {}

local console = require(script:WaitForChild('luau'):WaitForChild('console')).new {
    write = function(str)
        if listenerCount['error'] then
            if listenerCount['error'] > 0 then
                error(str)
            else
                print(str)
            end
        else
            print(str)
        end
    end,
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

console:kBindProperties(true, 'auto')

console:log('this console')
console:assert(3 % 2 == 0, 'assert');
console:count('error')
console:countReset('error')
console:debug('debug')
console:dir {
    dir = 'dir'
}
console:dirxml {
    dirxml = 'dirxml'
}
console:error('this error')

return console