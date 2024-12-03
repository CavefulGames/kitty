--!strict
local constructors = require(script:WaitForChild('constructors'))

local console = {}

function console.log(...)
    constructors.logConstructor:log(...)
end



return console