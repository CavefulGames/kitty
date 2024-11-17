--!strict
export type Console = typeof(setmetatable({} :: {

}, {} :: ConsoleImpl))

type ConsoleImpl = {
    __index: ConsoleImpl,
    new: (options: any, stderr: any, ignoreErrors: any) -> (Console),
    __call: (...any) -> (Console),
}

local primordials = require(script.Parent:WaitForChild('primordials'))
local errorCodes = require(script.Parent:WaitForChild('mainError')).codes
local ERR_CONSOLE_WRITABLE_STREAM = errorCodes.ERR_CONSOLE_WRITABLE_STREAM

local console = {} :: ConsoleImpl
console.__index = console

function console.new(options, stderr, ignoreErrors)
    if not options or typeof(options.write) == 'function' then
        options = {
            stdout = options,
            stderr = stderr,
            ignoreErrors = ignoreErrors,
        }
    end

    local stdout = options.stdout
    local stderr = options.stderr or stdout
    local ignoreErrors = options.ignoreErrors or true
    local colorMode = options.colorMode or 'auto'
    local inspectOptions = options.inspectOptions
    local groupIndentation = options.groupIndentation

    if not stdout or typeof(stdout.write) ~= 'function' then
        error(ERR_CONSOLE_WRITABLE_STREAM('stdout'))
    end
    if not stderr or typeof(stderr.write) ~= 'function' then
        error(ERR_CONSOLE_WRITABLE_STREAM('stderr'))
    end

end

function console.__call(...)
    return console.new(...)
end

return setmetatable({}, {})