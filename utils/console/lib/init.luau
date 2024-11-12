--!strict
local ERR_CONSOLE_WRITABLE_STREAM = 'ERR_CONSOLE_WRITABLE_STREAM'
local ERR_INCOMPATIBLE_OPTION_PAIR = 'ERR_INCOMPATIBLE_OPTION_PAIR'

local io = require('@lune/stdio')

local function validateArray(arr)
    if type(arr) ~= 'table' then
        error('Expected array')
    end
end

local function validateInteger(num)
    if type(num) ~= 'number' or math.floor(num) ~= num then
        error('Expected integer')
    end
end

local function validateObject(obj)
    if type(obj) ~= 'table' then
        error('Expected object')
    end
end

local function validateOneOf(value, allowed)
    local valid = false
    for _, allowedValue in ipairs(allowed) do
        if value == allowedValue then
            valid = true
            break
        end
    end
    if not valid then
        error('Invalid value')
    end
end

local function isBuffer(obj)
    return type(obj) == 'string'
end

local function isTypedArray(obj)
    return type(obj) == 'table' and obj._isTypedArray
end

local function isSet(obj)
    return type(obj) == 'table' and obj._isSet
end

local function isMap(obj)
    return type(obj) == 'table' and obj._isMap
end

local function isSetIterator(obj)
    return type(obj) == 'function' and obj._isSetIterator
end

local function isMapIterator(obj)
    return type(obj) == 'function' and obj._isMapIterator
end

local kTraceCount = string.byte('C')
local kMaxGroupIndentation = 1000

local kCounts = ('counts')
local kGroupIndentationWidth = ('groupIndentWidth')
local kFormatForStderr = ('formatForStderr')
local kFormatForStdout = ('formatForStdout')
local kGetInspectOptions = ('getInspectOptions')
local kColorMode = ('colorMode')
local kIsConsole = ('isConsole')
local kWriteToConsole = ('writeToConsole')
local kBindProperties = ('bindProperties')
local kBindStreamsEager = ('bindStreamsEager')
local kBindStreamsLazy = ('bindStreamsLazy')
local kUseStdout = ('useStdout')
local kUseStderr = ('useStderr')

local timeLog = {}
local timeEnd = {}
local kNone = {}

local kTraceConsoleCategory = 'node,node.console'
local kMaxGroupIndentation = 1000

local cliTable
local utilColors

local kGroupIndentationWidth = ('kGroupIndentWidth');
local kFormatForStderr = ('kFormatForStderr');
local kFormatForStdout = ('kFormatForStdout');
local kGetInspectOptions = ('kGetInspectOptions');
local kColorMode = ('kColorMode');
local kIsConsole = ('kIsConsole');
local kWriteToConsole = ('kWriteToConsole');
local kBindProperties = ('kBindProperties');
local kBindStreamsEager = ('kBindStreamsEager');
local kBindStreamsLazy = ('kBindStreamsLazy');
local kUseStdout = ('kUseStdout');
local kUseStderr = ('kUseStderr');

local optionsMap = {}

local function console(options: { [any]: any }, stderr, ignoreErrors)

    if not options or typeof(options.write) == "function" then
        options = {
            stdout = options,
            stderr = stderr,
            ignoreErrors = ignoreErrors
        }
    end

    local stdout = options.stdout
    local stderr = options.stdout
    local ignoreErrors = true
    local colorMode = 'auto'
    local inspectOptions = options.inspectOptions
    local groupIndentation = options.groupIndentation

    if not stdout or typeof(stdout.write) ~= 'function' then
        error('stdout')
    end

end