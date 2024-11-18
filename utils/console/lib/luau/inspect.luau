--!strict
local primordials = require(script.Parent:WaitForChild('primordials'))

local defaultFG = 39
local defaultBG = 49
local inspectDefaultOptions = {
    showHidden = false,
    depth = 2,
    colors = false,
    customInspect = true,
    showProxy = false,
    maxArrayLength = 100,
    maxStringLength = 10000,
    breakLength = 80,
    compact = 3,
    sorted = false,
    getters = false,
    numericSeparator = false,
}

local inspect = {}

inspect.colors = {
    reset =  { 0, 0 },
    bold =  { 1, 22 },
    dim =  { 2, 22 }, 
    italic =  { 3, 23 },
    underline =  { 4, 24 },
    blink =  { 5, 25 },
    inverse =  { 7, 27 },
    hidden =  { 8, 28 }, 
    strikethrough =  { 9, 29 }, 
    doubleunderline =  { 21, 24 }, 
    black =  { 30, defaultFG },
    red =  { 31, defaultFG },
    green =  { 32, defaultFG },
    yellow =  { 33, defaultFG },
    blue =  { 34, defaultFG },
    magenta =  { 35, defaultFG },
    cyan =  { 36, defaultFG },
    white =  { 37, defaultFG },
    bgBlack =  { 40, defaultBG },
    bgRed =  { 41, defaultBG },
    bgGreen =  { 42, defaultBG },
    bgYellow =  { 43, defaultBG },
    bgBlue =  { 44, defaultBG },
    bgMagenta =  { 45, defaultBG },
    bgCyan =  { 46, defaultBG },
    bgWhite =  { 47, defaultBG },
    framed =  { 51, 54 },
    overlined =  { 53, 55 },
    gray =  { 90, defaultFG },
    redBright =  { 91, defaultFG },
    greenBright =  { 92, defaultFG },
    yellowBright =  { 93, defaultFG },
    blueBright =  { 94, defaultFG },
    magentaBright =  { 95, defaultFG },
    cyanBright =  { 96, defaultFG },
    whiteBright =  { 97, defaultFG },
    bgGray =  { 100, defaultBG },
    bgRedBright =  { 101, defaultBG },
    bgGreenBright =  { 102, defaultBG },
    bgYellowBright =  { 103, defaultBG },
    bgBlueBright =  { 104, defaultBG },
    bgMagentaBright =  { 105, defaultBG },
    bgCyanBright =  { 106, defaultBG },
    bgWhiteBright =  { 107, defaultBG },
}

local function defineColorAlias(target, alias)
    inspect.colors[alias] = {
        get = function()
            return inspect.colors[alias][target]
        end,
        set = function(value)
            inspect.colors[alias][target] = value
        end,
        configurable = true,
        enumerable = false,
    }
end

defineColorAlias('gray', 'grey')
defineColorAlias('gray', 'blackBright')
defineColorAlias('bgGray', 'bgGrey')
defineColorAlias('bgGray', 'bgBlackBright')
defineColorAlias('dim', 'faint')
defineColorAlias('strikethrough', 'crossedout')
defineColorAlias('strikethrough', 'strikeThrough')
defineColorAlias('strikethrough', 'crossedOut')
defineColorAlias('hidden', 'conceal')
defineColorAlias('inverse', 'swapColors')
defineColorAlias('inverse', 'swapcolors')
defineColorAlias('doubleunderline', 'doubleUnderline')

inspect.styles = {
    special = 'cyan',
    number = 'yellow',
    bigint = 'yellow',
    boolean = 'yellow',
    undefined = 'grey',
    null = 'bold',
    string = 'green',
    symbol = 'green',
    date = 'magenta',
    regexp = 'red',
    module = 'underline',
}

local function formatValue(ctx, value, depth: number)
    if type(value) == "nil" then return "nil" end
    if type(value) == "string" then return "'" .. value .. "'" end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    if type(value) == "function" then return "[Function]" end
    
    if type(value) == "table" then
        local items = {}
        for k, v in pairs(value) do
            table.insert(items, tostring(k) .. ": " .. formatValue(ctx, v, depth + 1))
        end
        return "{ " .. table.concat(items, ", ") .. " }"
    end
    
    return tostring(value)
end

local function stylizeNoColor(str)
    return str;
end

local function stylizeWithColor(str, styleType)
    local style = (inspect::any).styles[styleType]
    if style ~= nil then
        local color = (inspect::any).colors[style]
        if color ~= nil then
            return `\\u001b[{color[1]}m{str}\\u001b[{color[2]}m`
        end
    end

    return str
end

local function inspectCall(value, opts, ...)
    local arguments = { value, opts, ... }
    local ctx = {
        budget = {},
        indentationLvl = 0,
        seen = {},
        currentDepth = 0,
        stylize = stylizeNoColor,
        showHidden = inspectDefaultOptions.showHidden,
        depth = inspectDefaultOptions.depth,
        colors = inspectDefaultOptions.colors,
        customInspect = inspectDefaultOptions.customInspect,
        showProxy = inspectDefaultOptions.showProxy,
        maxArrayLength = inspectDefaultOptions.maxArrayLength,
        maxStringLength = inspectDefaultOptions.maxStringLength,
        breakLength = inspectDefaultOptions.breakLength,
        compact = inspectDefaultOptions.compact,
        sorted = inspectDefaultOptions.sorted,
        getters = inspectDefaultOptions.getters,
        numericSeparator = inspectDefaultOptions.numericSeparator,
    }

    if #arguments > 1 then
        if #arguments > 2 then
            if arguments[3] ~= nil then
                ctx.depth = arguments[3]
            end
            if #arguments > 3 and arguments[4] ~= nil then
                ctx.colors = arguments[4]
            end
        end

        if typeof(opts) == 'boolean' then
            ctx.showHidden = opts
        elseif opts then
            local optKeys = primordials.objectKeys(opts)
            local i = 1
            while true do
                if not (i < #optKeys + 1) then
                    break
                end

                local key = optKeys[i]

                if inspectDefaultOptions[key] or key == 'stylize' then
                    ctx[key] = opts[key]
                elseif ctx.userOptions == nil then
                    ctx.userOptions = opts
                end

                i += 1
            end
        end
    end

    if ctx.colors then ctx.stylize = stylizeWithColor :: any end
    if ctx.maxArrayLength == nil then ctx.maxArrayLength = math.huge end
    if ctx.maxStringLength == nil then ctx.maxStringLength = math.huge end

    return formatValue(ctx, value, 0)
end

return setmetatable(inspect, { 
    __call = inspectCall 
})
