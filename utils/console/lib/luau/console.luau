--!strict
local errorMain = require(script.Parent:WaitForChild('mainError'))
local safeWeakMap = require(script.Parent:WaitForChild('safeMap'))
local colors = require(script.Parent:WaitForChild('colors'))
local primordials = require(script.Parent:WaitForChild('primordials'))
local inspect = require(script.Parent:WaitForChild('inspect'))
local timeFunctions = require(script.Parent:WaitForChild('timeFunctions'))

local errorCodes = errorMain.codes
local isStackOverflowError = errorMain.isStackOverflowError

export type Console = typeof(setmetatable({} :: {
    --// user configs
    round: 'always' | 'only_tree' | 'only_table' | 'off' | boolean, 

    --// system
    _stdout: { 
        kBindStreamsEager: any,
        enumerable: any,
        writable: any,
        configurable: any,
        value: any,
        listener: any,
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
    warn: (self: Console, ...any) -> (),
    dir: (self: Console, object: any, options: any) -> (),

    --// todo (make a time's)
    time: (self: Console, label: any) -> (),
    timeEnd: (self: Console, label: any) -> (),
    timeLog: (self: Console, label: any) -> (),

    trace: (self: Console, ...any) -> (),
    assert: (self: Console, expression: any, ...any) -> (),

    --// todo (make a clear)
    clear: (self: Console) -> (),

    count: (self: Console, label: string?) -> (),
    countReset: (self: Console, table: string?) -> (),
    group: (self: Console, ...any) -> (),
    groupEnd: (self: Console) -> (),
    table: (self: Console, tabularData: any, properties: any) -> (any),
    tree: (self: Console, top: Instance | string, child: { [any]: any }?) -> (),

    --// pulsing
    debug: (self: Console, ...any) -> (),
    info: (self: Console, ...any) -> (),
    dirxml: (self: Console, ...any) -> (),
    error: (self: Console, ...any) -> (),
    groupCollapsed: (self: Console, ...any) -> (),
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

local kTraceConsoleCategory = 'node,node.console';

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

local tableChars = {
    middleMiddle = '─',
    rowMiddle = '┼',
    topRight = '┐',
    topLeft = '┌',
    leftMiddle = '├',
    topMiddle = '┬',
    bottomRight = '┘',
    bottomLeft = '└',
    bottomMiddle = '┴',
    rightMiddle = '┤',
    left = '│ ',
    right = ' │',
    middle = '│'
}

local treeChars = {
    middleMiddle = '─',
    rowMiddle = '┼',
    topRight = '┐',
    topLeft = '┌',
    leftMiddle = '├',
    topMiddle = '┬',
    bottomRight = '┘',
    bottomLeft = '└',
    bottomMiddle = '┴',
    rightMiddle = '┤',
    left = '│ ',
    right = ' │',
    middle = '│'
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

local function timeLogImpl(consoleRef, label, formatted, args)
    if args == nil then
        consoleRef:log('%s:%s', label, formatted)
    else
        consoleRef:log('%s:%s', label, formatted, table.unpack(args))
    end
end

local function changeTableChars(round: 'always' | 'only_tree' | 'only_table' | 'off' | boolean)
    if round == 'always' then
        tableChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '╮',
            topLeft = '╭',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '╯',
            bottomLeft = '╰',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
        treeChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '╮',
            topLeft = '╭',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '╯',
            bottomLeft = '╰',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
    elseif round == 'only_tree' then
        tableChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '┐',
            topLeft = '┌',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '┘',
            bottomLeft = '└',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
        treeChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '╮',
            topLeft = '╭',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '╯',
            bottomLeft = '╰',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
    elseif round == 'only_table' then
        tableChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '╮',
            topLeft = '╭',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '╯',
            bottomLeft = '╰',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
        treeChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '┐',
            topLeft = '┌',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '┘',
            bottomLeft = '└',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
    elseif round == 'off' then
        tableChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '┐',
            topLeft = '┌',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '┘',
            bottomLeft = '└',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
        
        treeChars = {
            middleMiddle = '─',
            rowMiddle = '┼',
            topRight = '┐',
            topLeft = '┌',
            leftMiddle = '├',
            topMiddle = '┬',
            bottomRight = '┘',
            bottomLeft = '└',
            bottomMiddle = '┴',
            rightMiddle = '┤',
            left = '│ ',
            right = ' │',
            middle = '│'
        }
    elseif round then
        changeTableChars('always')
    else
        changeTableChars('off')
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

    local self = setmetatable({}, console) :: Console

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
            error(ERR_INCOMPATIBLE_OPTION_PAIR('options.inspectOptions.color', 'colorMode'))
        end

        optionsMap:set(self, inspectOptions)
    end

    self:kBindStreamsEager(stdout, stderr)
    self:kBindProperties(ignoreErrors, colorMode, groupIndentation)

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
        listener = nil,
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
    local groupIndent = internalIndentationMap:get(self) or ''

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
    return primordials.reflectApply(primordials.formatWithOptions, nil, args)
end

function console.kFormatForStderr(self, args)
    local opts = self:kGetInspectOptions(self._stderr)
    args = primordials.arrayPrototypeUnshift(args, opts)
    return primordials.reflectApply(primordials.formatWithOptions, nil, args)
end

function console.log(self, ...)
    local args = { ... }
    self:kWriteToConsole(kUseStdout, self:kFormatForStdout(args))
end

function console.warn(self, ...)
    local args = { ... }
    self:kWriteToConsole(kUseStderr, self:kFormatForStderr(args))
end

function console.dir(self, object, options)
    self:kWriteToConsole(kUseStdout, inspect(object, (function() 
        local result = {}
        result.customInspect = false

        for k, v in self:kGetInspectOptions(self._stdout) do
            result[k] = v
        end

        for k, v in options do
            result[k] = v
        end
        
        return result
    end)()))
end

function console.time(self, label)
    if label == nil then 
        label = 'default'
    end
    timeFunctions.time(self._times, kTraceConsoleCategory, 'console.time()', timeFunctions.kNone, label, `time::{label}`)
end

function console.timeEnd(self, label)
    if label == nil then
        label = 'default'
    end
    timeFunctions.timeEnd(self._times, kTraceConsoleCategory, 'console.timeEnd()', timeFunctions.kNone, function(label, formatted, args)
        timeLogImpl(self, label, formatted, args)
    end, label, `time::{label}`)
end

function console.timeLog(self, label, ...)
    if label == nil then
        label = 'default'
    end
    timeFunctions.timeLog(self._times, kTraceConsoleCategory, 'console.timeLog()', timeFunctions.kNone, function(label, formatted, args)
       timeLogImpl(self, label, formatted, args) 
    end, label, `time::{label}`, { ... })
end

function console.trace(self, ...)
    local args = { ... }
    local err = {
        name = 'Trace',
        message = self:kFormatForStderr(args)
    }
    err.stack = debug.traceback("", 2)
    self:warn(err.stack)
end

function console.assert(self, expression, ...)
    local args = { ... }
    if not expression then
        if args[1] and typeof(args[1]) == 'string' then
            args[1] = `Assertion failed: {args[1]}`
        else
            primordials.arrayPrototypeUnshift(args, 'Assertion failed')
        end

        primordials.reflectApply(self.warn, self, args)
    end
end

function console.count(self, label)
    label = label or 'default'
    local counts = self.kCounts
    local count = counts.value:get(label)
    if count == nil then
        count = 1
    else
        count += 1
    end
    counts.value:set(label, count)
    debug.traceback(`count::{label}: {count}`)
    self:log(`{label}: {count}`)
end

function console.countReset(self, label)
    label = label or 'default'

    local counts = self.kCounts
    if not counts.value:has(label) then
        warn(`Count for '{label}' does not exist`)
        return
    end
    debug.traceback(`count::{label}`, 0)
    counts.value:delete(label)
end

function console.group(self, ...)
    local data = { ... }

    if #data > 0 then
        primordials.reflectApply(self.log, self, data)
    end

    local currentIndentation = internalIndentationMap:get(self) or ''
    currentIndentation ..= primordials.stringPrototypeRepeat(' ', self.kGroupIndentationWidth.value)

    internalIndentationMap:set(self, currentIndentation)
end

function console.groupEnd(self)
    local currentIndentation = internalIndentationMap:get(self) or ''
    local newIndentation = primordials.stringPrototypeSlice(
        currentIndentation,
        0,
        #currentIndentation - self.kGroupIndentationWidth.value
    )

    internalIndentationMap:set(self, newIndentation)
end

function console.table(self, value, options)
    if type(value) ~= "table" or #value == 0 then
        return tostring(value)
    end
    
    changeTableChars(self.round)
    
    local headers = {"(index)"}
    local rows = {}
    local widths = {7}
    
    if type(value[1]) == "table" then
        for k in value[1] do
            table.insert(headers, k)
            widths[#widths + 1] = #k
        end
    end
    
    for i, item in ipairs(value) do
        local row = {i - 1}
        for j = 2, #headers do
            local val = tostring(item[headers[j]] or "")
            row[j] = val :: any
            widths[j] = math.max(widths[j], #val)
        end
        table.insert(rows, row)
    end
    
    local result = ""
    
    result = result .. tableChars.topLeft
    for i, width in ipairs(widths) do
        result = result .. string.rep(tableChars.middleMiddle, width + 2)
        result = result .. (i == #widths and tableChars.topRight or tableChars.topMiddle)
    end
    result = result .. "\n"
    
    result = result .. tableChars.middle
    for i, header in ipairs(headers) do
        local padding = widths[i] - #header
        result = result .. " " .. header .. string.rep(" ", padding) .. tableChars.right
    end
    result = result .. "\n"
    
    result = result .. tableChars.leftMiddle
    for i, width in ipairs(widths) do
        result = result .. string.rep(tableChars.middleMiddle, width + 2)
        result = result .. (i == #widths and tableChars.rightMiddle or tableChars.rowMiddle)
    end
    result = result .. "\n"
    
    for _, row in ipairs(rows) do
        result = result .. tableChars.middle
        for i, cell in ipairs(row) do
            local padding = widths[i] - #tostring(cell)
            if i == 1 then
                result = result .. " " .. string.rep(" ", padding) .. cell .. tableChars.right
            else
                result = result .. " " .. cell .. string.rep(" ", padding) .. tableChars.right
            end
        end
        result = result .. "\n"
    end
    
    result = result .. tableChars.bottomLeft
    for i, width in ipairs(widths) do
        result = result .. string.rep(tableChars.middleMiddle, width + 2)
        result = result .. (i == #widths and tableChars.bottomRight or tableChars.bottomMiddle)
    end

    return print(`\n{result}`)
end

function console.tree(self, top, child)
    changeTableChars(self.round)
    if typeof(top) =='Instance' then
        local topName = top.Name
        local function changeInstanceToChild(argument)
            local reusltChild = {} :: any
            for k, v: Instance in argument:GetChildren() do
                reusltChild[v] = changeInstanceToChild(v)
                reusltChild[v].TREE_INSTANCE = v.ClassName
            end
            return reusltChild
        end

        child = changeInstanceToChild(top)
        top = `{topName}: {top.ClassName}`
    end

    local result = top :: string
    local voidDefultSize = ' '
    local defultMiddleVoidSize = ' '
    local defultHightMiddle = treeChars.middle
    local defultWightMiddle = treeChars.middleMiddle
    
    local function childResult(argument: { [any]: any }, voidSize: number)
        local childMaxLoopCound = primordials.getObjectOrArrayLen(argument)
        local childCount = 0 
        for k, v in argument do
            if typeof(k) ~= 'string' then 
                k = tostring(k) 
            end
            childCount += 1
            
            local hightMiddle = treeChars.leftMiddle
            local argumentIsTable = typeof(v) == 'table' and not v.TREE_INSTANCE
            local widthMiddle = if argumentIsTable then treeChars.topMiddle else defultWightMiddle
            
            if childCount == childMaxLoopCound then 
                hightMiddle = treeChars.bottomLeft 
            end
            if argumentIsTable and primordials.getObjectOrArrayLen(v) == 0 then 
                widthMiddle = defultWightMiddle 
            end
            
            result ..= `\n{defultMiddleVoidSize}{primordials.stringPrototypeRepeat(`{defultHightMiddle}{voidDefultSize}`, voidSize)}{hightMiddle}{defultWightMiddle}{widthMiddle} {k}`
            if argumentIsTable then
                if childCount == childMaxLoopCound then
                    defultMiddleVoidSize = '   '
                    childResult(v, voidSize)
                else
                    childResult(v, voidSize+1)
                end
            else
                if typeof(v) == 'table' then
                    result ..= `: {v.TREE_INSTANCE}`
                    v.TREE_INSTANCE = nil
                    childResult(v, voidSize+1)
                else
                    result ..= `: {v}`
                end    
            end
        end
    end
    
    childResult(child :: any, 0)

    return print(`\n{result}`)
end

console.debug = console.log
console.info = console.log
console.dirxml = console.log
console.error = console.warn
console.groupCollapsed = console.group

return console
