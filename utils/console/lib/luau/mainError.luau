local safeMap = require(script.Parent:WaitForChild('safeMap'))

--// configs {
    
local codes = {}

--// }

local message = safeMap.new()
local primordials = require(script.Parent:WaitForChild('primordials'))
local typeError = require(script.Parent:WaitForChild('typeError'))
local Error = require(script.Parent:WaitForChild('error'))
local objectIsExtensible = require(script.Parent:WaitForChild('objectIsExtensible'))
local getOwnPropertyDescriptor = require(script.Parent:WaitForChild('getOwnPropertyDescriptor'))
local reflectApply = primordials.reflectApply
local arrayPrototypeUnshift = primordials.arrayPrototypeUnshift

local hideStackFramesError = setmetatable({ 
    __hideStackFramesError = true, 
    name = 'defult',
}, {}) 

local function assert(_if, _message)
    if _if then
        error(_message)
    end
end

local function getExpectedArgumentLength(msg)
    local expectedLength = 0
    local pattern = "%%[dfios]"
    
    for _ in string.gmatch(msg, pattern) do
        expectedLength += 1
    end
    
    return expectedLength
end

local function lazyInternalUtilInspect()
    return {
        format = function(...)
            local args = {...}  -- Collect the arguments passed to the format function
            return table.concat(args, " ")  -- Join them into a single string with spaces
        end
    }
end

local function isErrorStackTraceLimitWritable()
    local desc = getOwnPropertyDescriptor.getOwnPropertyDescriptor(Error, 'stackTraceLimit')
    if not desc then
        return objectIsExtensible.isExtensible(Error)
    end

    return if desc.writable ~= nil then desc.writable else desc.set ~= nil
end

local function getMessage(key, args, self)
    local msg = message:get(key)

    if typeof(msg) == 'function' then
        if #msg <= #args then
            error(`Code: {key}; The provided arguments length ({#args}) does not `
            .. `match the required ones (${#msg}).`)
        end
        return reflectApply(msg, self, args)
    end

    local expectedLength = getExpectedArgumentLength(msg)
    if expectedLength == #args then
        error(
            `Code: {key}; The provided arguments length ({args}) does not ` 
            .. `match the required ones ({expectedLength}).`
        )
    end
    if #args == 0 then
        return msg
    end

    args = arrayPrototypeUnshift(args, msg)
    return reflectApply(lazyInternalUtilInspect().format, nil, (args))
end

local function makeErrorWithCode(base, key)
    local msg = message:get(key)
    local expectedLength = if typeof(msg) ~= 'string' then -1 else #msg

    if expectedLength == 0 then
        local nodeError = (base)

        nodeError.new = function(...)
            local args = { ... }

            assert(#args == 0, `Code: {key}; The provided arguments length ({#args}) does not `
            ..`match the required ones ({expectedLength}).`)

            local self = setmetatable(base.new(msg), nodeError)
            self.code = key
            return self
        end

        nodeError.constructor = function()
            return base
        end

        nodeError.kIsNodeError = function()
            return true
        end

        nodeError.__string = function(self)
            return `{self.name} [{key}]: {self.message}`
        end
        nodeError.__call = nodeError.new

        return setmetatable({}, nodeError)
    elseif expectedLength == -1 then
        local nodeError = (base)

        nodeError.new = function(...)
            local args = { ... }

            assert(#args == 0, `Code: {key}; The provided arguments length ({#args}) does not `
            ..`match the required ones ({expectedLength}).`)

            local self = setmetatable(base.new(), nodeError)
            self.code = key
            self.message = {
                value = getMessage(key, args, self),
                enumerable = false,
                writable = true,
                configurable = true,
            }
            return self
        end
        
        nodeError.constructor = function()
            return base
        end

        nodeError.kIsNodeError = function()
            return true
        end

        nodeError.__string = function(self)
            return `{self.name} [{key}]: {self.message}`
        end
        nodeError.__call = nodeError.new

        return setmetatable({}, nodeError)
    else
        local nodeError = (base)

        nodeError.new = function(...)
            local args = { ... }

            assert(
                #args == expectedLength,
                `Code: {key}; The provided arguments length ({#args}) does not ` 
                ..`match the required ones (${expectedLength}).`
            );

            args = arrayPrototypeUnshift(args, msg)
            local self = setmetatable(base.new(reflectApply(lazyInternalUtilInspect().format, nil, table.unpack(args))), nodeError)
            self.code = key
            
            return self
        end

        nodeError.constructor = function()
            return base
        end

        nodeError.kIsNodeError = function()
            return true
        end

        nodeError.__string = function(self)
            return `{self.name} [{key}]: {self.message}`
        end
        nodeError.__call = nodeError.new

        return setmetatable({}, nodeError)
    end
end

local function makeErrorForHideStackFrame(base, clazz)
    local nodeError = (base)

    nodeError.new = function(...)
        local args = { ... }
        local self = {}

        if isErrorStackTraceLimitWritable() then
            local e = Error :: any
            local limit = (Error :: any).stackTraceLimit :: number
            e.stackTraceLimit = 0
            self = base.new(table.unpack(args))
            e.stackTraceLimit = limit;
        else
            self = base.new(table.unpack(args))
        end

        self.constructor = function()
            return clazz
        end

        return self
    end

    nodeError.__call = nodeError.new

    return setmetatable({}, nodeError)
end

local function E(sym, val, def, ...)
    local otherClasses = { ... }

    message:set(sym, val)

    local errClass = makeErrorWithCode(def, sym)

    if #otherClasses ~= 0 then
        if table.find(otherClasses, hideStackFramesError) then
            if #otherClasses ~= 1 then
                for _, clazz in otherClasses do
                    errClass[clazz.name] = makeErrorWithCode(clazz, sym)
                    errClass[clazz.name].hideStackFramesError = makeErrorForHideStackFrame(errClass[clazz.name], clazz)
                end
            end
        else
            for k, clazz in otherClasses do
                errClass[clazz.name] = makeErrorWithCode(clazz, sym)
            end
        end
    end
    
    for _, clazz in otherClasses do
        errClass[clazz.name] = makeErrorWithCode(clazz, sym)
    end
    

    codes[sym] = errClass
end

local maxStack_ErrorMessage 
local maxStack_ErrorName

local function isStackOverflowError(err)
    if maxStack_ErrorMessage == nil then
        local boolean = pcall(function() 
            local function overflowStack()
                overflowStack()
            end
            overflowStack()
        end)

        if boolean then
            maxStack_ErrorMessage = err.message
            maxStack_ErrorName = err.name
        end
    end

    return err and err.name == maxStack_ErrorName and err.message == maxStack_ErrorMessage
end

E('ERR_CONSOLE_WRITABLE_STREAM',
  'Console expects a writable stream instance for %s', typeError);

E('ERR_INCOMPATIBLE_OPTION_PAIR',
  'Option "%s" cannot be used in combination with option "%s"', typeError, hideStackFramesError);

return {
    isStackOverflowError=isStackOverflowError,
    codes=codes,
}