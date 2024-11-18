--!strict
local errorMain = require(script.Parent:WaitForChild('mainError'))
local safeWeakMap = require(script.Parent:WaitForChild('safeMap'))
local colors = require(script.Parent:WaitForChild('colors'))
local primordials = require(script.Parent:WaitForChild('primordials'))

local errorCodes = errorMain.codes
local isStackOverflowError = errorMain.isStackOverflowError

export type Console = typeof(setmetatable({} :: {
    _stdout: { 
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        configurable: any,
        value: any,
    },
    _stderr: { 
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: any,
    },
    _stdoutErrorHandler: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: any,
    },
    _stderrErrorHandler: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: any,
    },
    _ignoreErrors: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: boolean,
    },
    _times: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: safeWeakMap.SafeMap,
    },
    kCounts: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: safeWeakMap.SafeMap,
    },
    kColorMode: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: any,
    },
    kIsConsole: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: boolean,
    },
    kGroupIndentationWidth: {
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        value: number,
    },
    SymbolToStringTag: {
        writable: boolean,
        enumerable: boolean,
        configurable: boolean,
        value: string,
    },
}, {} :: ConsoleImpl))

type ConsoleImpl = {
    __index: ConsoleImpl,
    new: (options: any, stderr: any, ignoreErrors: any) -> (Console),
    __call: (...any) -> (Console),
    symbolHasInstance: (self: Console, value: any) -> any,
    kBindStreamsEager: (self: Console, stdout: any, stderr: any) -> (),
    kBindStreamsLazy: (self: Console, object: any) -> (),
    kBindProperties: (self: Console, ignoreErrors: any, colorMode: any, groupIndentation: number?) -> (),
    kWriteToConsole: (self: Console, streamSymbol: any, str: string) -> (),
    kGetInspectOptions: (self: Console, stream: any) -> (any),
    kFormatForStdout: (self: Console, args: any) -> (any),
    kFormatForStderr: (self: Console, args: any) -> (any),

    log: (self: Console, ...any) -> (),
}

local ERR_CONSOLE_WRITABLE_STREAM = errorCodes.ERR_CONSOLE_WRITABLE_STREAM
local ERR_INCOMPATIBLE_OPTION_PAIR = errorCodes.ERR_INCOMPATIBLE_OPTION_PAIR

local kBindStreamsEager = 'kBindStreamsEager'
local kBindProperties = 'kBindProperties'
local kIsConsole = 'kIsConsole'
local kBindStreamsLazy = 'kBindStreamsLazy'
local kUseStdout = 'kUseStdout'
local kUseStderr = 'kUseStderr'
local kCounts = 'kCounts'
local kColorMode = 'kColorMode'
local kGroupIndentationWidth = 'kGroupIndentationWidth'
local kWriteToConsole = 'kWriteToConsole'
local SymbolToStringTag = 'SymbolToStringTag'
local kFormatForStdout = 'kFormatForStdout'

local kMaxGroupIndentation = 1000
local optionsMap = safeWeakMap.new()
local internalIndentationMap = safeWeakMap.new()

local kColorInspectOptions = { colors = true }

local kNoColorInspectOptions = {}

local consolePropAttributes = {
    writable = true,
    enumerable = false,
    configurable = true,
}

local function noop() end

local function createWriteErrorHandler(instance, streamSymbol)
    return function(err)
        local stream = if streamSymbol == kUseStdout then
            instance._stdout else instance._stderr
        if err ~= nil and not stream._writableState.errorEmitted then
            if (stream.value :: any).listenerCount('error') == 0 then
                (stream.value :: any ).once('error', noop)
            end
        end
    end
end

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

    local self = setmetatable({}, console)

    local stdout = options.stdout
    stderr = options.stderr or stdout
    ignoreErrors = options.ignoreErrors or true
    local colorMode = options.colorMode or 'auto'
    local inspectOptions = options.inspectOptions
    local groupIndentation = options.groupIndentation

    if not stdout or typeof(stdout.write) ~= 'function' then
        error(ERR_CONSOLE_WRITABLE_STREAM('stdout'))
    end
    if not stderr or typeof(stderr.write) ~= 'function' then
        error(ERR_CONSOLE_WRITABLE_STREAM('stderr'))
    end

    if not table.find({ 'auto', true, false } :: { [number]: any }, colorMode) then
        error '나중에 에러 써야함'
    end

    if groupIndentation ~= nil then
        if math.clamp(groupIndentation, 0, kMaxGroupIndentation) ~= groupIndentation then
            error '나중에 에러 써야함'
        end
    end

    if inspectOptions ~= nil then
        if typeof(inspectOptions) == 'table' then
            error '나중에 에러 써야함'
        end

        if inspectOptions.colors ~= nil and options.colorMode ~= nil then
            error(ERR_CONSOLE_WRITABLE_STREAM('options.inspectOptions.color', 'colorMode'))
        end

        optionsMap:set(self, inspectOptions)
    end

    self[kBindStreamsEager](stdout, stderr)
    self[kBindProperties](ignoreErrors, colorMode, groupIndentation)

    return self :: any
end

function console.__call(...)
    return console.new(...)
end

function console.symbolHasInstance(self, instance)
    return instance[kIsConsole]
end

function console.kBindStreamsEager(self, stdout, stderr)
    self._stdout = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = stdout,
    }

    self._stderr = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = stderr,
    }
end

function console.kBindStreamsLazy(self, object)
    local stdout
    local stderr

    self._stdout = {
        enumerable = false,
        configurable = true,
        get = function()
            return stdout and object.stdout
        end,
        set = function(value)
            stdout = value
        end,
    }

    self._stderr = {
        enumerable = false,
        configurable = true,
        get = function()
            return stderr and object.stderr
        end,
        set = function(value)
            stderr = value
        end,
    }
end

function console.kBindProperties(self, ignoreErrors, colorMode, groupIndentation)
    groupIndentation = (groupIndentation or 2) ::number

    self._stdoutErrorHandler = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = createWriteErrorHandler(self :: any , kUseStdout),
    }

    self._stderrErrorHandler = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = createWriteErrorHandler(self :: any , kUseStderr),
    }

    self._ignoreErrors = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = ignoreErrors,
    }

    self._times = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = safeWeakMap.new(),
    }

    self.kCounts = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = safeWeakMap.new(),
    }

    self.kColorMode = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = colorMode,
    }

    self.kIsConsole = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = true,
    }

    self.kGroupIndentationWidth = {
        kBindStreamsEager = consolePropAttributes.configurable,
        enumerable = consolePropAttributes.enumerable,
        writable = consolePropAttributes.writable,
        value = groupIndentation :: number,
    }

    self.SymbolToStringTag = {
        writable = false,
        enumerable = false,
        configurable = true,
        value = 'console',
    }
end

function console.kWriteToConsole(self, streamSymbol, str)
    local ignoreErrors = self._ignoreErrors
    local groupIndent = internalIndentationMap.get(self :: any) or ''

    local useStdout = streamSymbol == kUseStdout
    local stream = if useStdout then self._stdout else self._stderr
    local errorHandler = if useStdout then 
        self._stderrErrorHandler else self._stderrErrorHandler

    if #groupIndent ~= 0 then
        if string.find(str, "\n") then
            str = string.gsub(str, "\n", "\n" .. groupIndent)
        end
        str = groupIndent .. str
    end
    str ..= '\n'

    if ignoreErrors.value == false then return stream.value.write(str) end

    local b, e = pcall(function() 
        if stream.value.listenerCount('error') == 0 then
            stream.value.once('error', noop)
        end

        stream.value.write(str, errorHandler)
    end)

    if b then
        if isStackOverflowError(e) then
            error(e)
        end
    else
        stream.value.removeListener('error', noop)
    end
end

function console.kGetInspectOptions(self, stream)
    local color = self[kColorMode]
    if color == 'auto' then
        color = colors.shouldColorize(stream)
    end

    local options = optionsMap:get(self)
    if options then
        if options.colors == nil then
            options.colors = color
        end
        return options
    end

    return if color then kColorInspectOptions else kNoColorInspectOptions
end

function console.kFormatForStdout(self, args)
    local opts = self:kGetInspectOptions(self._stdout)
    args = primordials.arrayPrototypeUnshift(args, opts)
    return primordials.reflectApply(string.format, nil, table.unpack(args))
end

function console.kFormatForStderr(self, args)
    local opts = self:kGetInspectOptions(self._stderr)
    args = primordials.arrayPrototypeUnshift(args, opts)
    return primordials.reflectApply(string.format, nil, table.unpack(args))
end

function console.log(self, ...)
    -- selfLkWriteToConsole(kUseStdout, )
end

return setmetatable({}, {})