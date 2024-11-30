--!strict
type ErrorOptions = {
    cause: any?,
}

export type Error = {
    new: (message: string?, options: ErrorOptions?) -> Error,
    message: string,
    name: string,
    stack: string?,
    cause: any?,
    toString: (self: Error) -> string,
    captureStackTrace: (targetObject: any, constructor: (...any) -> any?) -> (),
}

local Error = {}
Error.__index = Error

Error.prototype = {
    name = "Error"
}

Error.stackTraceLimit = 10

local function defaultPrepareStackTrace(err: Error, stackTraces: {string}): string
    local result = err.name .. ": " .. err.message
    for _, trace in ipairs(stackTraces) do
        result = result .. "\n    at " .. trace
    end
    return result
end

Error.prepareStackTrace = defaultPrepareStackTrace

function Error.new(message: string?, options: ErrorOptions?): Error
    local self = setmetatable({}, Error)
    
    self.message = if type(message) == "string" then message else ""
    
    self.name = "Error"
    
    if options then
        self.cause = options.cause
    end
    
    Error.captureStackTrace(self, Error.new)
    
    return self :: any
end

function Error.captureStackTrace(targetObject: any, constructor: (...any) -> any?)
    local stack = debug.traceback("", 2)
    
    local stackTraces = {}
    local skipNext = false
    
    for line in string.gmatch(stack, "[^\n]+") do
        if line:match("stack traceback:") then
            continue
        end
        
        if constructor and skipNext then
            continue
        end
        
        if line:match("%.%.%.") or line:match("%[C%]") then
            continue
        end

        local func, location = line:match("%s*([^%s].*) ([^%s]+)$")
        if func and location then
            func = func:gsub("in function ", "")
            location = location:gsub("%.%.%.", "")
            
            local formattedTrace = func .. " " .. location
            table.insert(stackTraces, formattedTrace)
            
            if #stackTraces >= Error.stackTraceLimit then
                break
            end
        end
    end
    
    targetObject.stack = Error.prepareStackTrace(targetObject, stackTraces)
end

function Error:toString(): string
    return `{self.name} : {self.message}`
end

local function inherits(childClass: any, parentClass: any)
    childClass.prototype = setmetatable({}, {__index = parentClass.prototype})
    childClass.__index = childClass
    setmetatable(childClass, {__index = parentClass})
end

local TypeError = setmetatable({}, {__index = Error})
TypeError.__index = TypeError

function TypeError.new(message: string?, options: ErrorOptions?): Error
    local self = Error.new(message, options)
    setmetatable(self, TypeError)
    self.name = "TypeError"
    return self :: any
end

inherits(TypeError, Error)

local ReferenceError = setmetatable({}, {__index = Error})
ReferenceError.__index = ReferenceError

function ReferenceError.new(message: string?, options: ErrorOptions?): Error
    local self = Error.new(message, options)
    setmetatable(self, ReferenceError)
    self.name = "ReferenceError"
    return self :: any
end

inherits(ReferenceError, Error)

return {
    Error = Error,
    TypeError = TypeError,
    ReferenceError = ReferenceError,
}