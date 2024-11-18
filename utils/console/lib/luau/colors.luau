--!strict
return {
    blue = '',
    green = '',
    white = '',
    red = '',
    gray = '',
    clear = '',
    reset = '',
    hasColors = false,
    shouldColorize = function(stream)
        return if stream.isTTy and typeof(stream.getColorDepth) == 'function' then
            stream.getColorDepth() > 2 else true
    end,
}