--!strict

local tableChars = {
    middleMiddle = '─',
    rowMiddle = '┼',
    topRight = '┐',
    topLeft = '┌',
    leftMiddle =  '├',
    topMiddle = '┬',
    bottomRight = '┘',
    bottomLeft = '└',
    bottomMiddle = '┴',
    rightMiddle = '┤',
    left = '│ ',
    right = ' │',
    middle = ' │ ',
};

local function stringPrototypeRepeat(str: string, num: number)
    local result = ''
    for i=1, num do
        result ..= str
    end
    return result
end

local function arrayPrototypeMap<T>(array: { [number]: T }, call: (v: T, i: number) -> (any))
    local result = {}
    for i, v in array do
        result[i] = call(v, i)
    end
    return result
end

local function mathMaxApply(array: { [number]: number }): number
    local result: number
    for _, v in array do
        if not result then
            result = v
            continue
        end

        if result < v then
            result = v 
        end
    end
    return result
end

local function mathMax(...: number)
    local result: number
    for _, v in { ... } do
        if not result then
            result = v 
            continue
        end

        if result < v then
            result = v
        end
    end
    return result
end

local function arrayPrototypeJoin(array: { [number]: string }, str: string?)
    local result = ''
    str = str::string or ',' :: string

    for i=1, #array do
        result ..= `{array[i]}{str}`
    end

    return result
end

local function renderRow(row: { [number]: string }, columnWidths: { [number]: number }): string
    local out = tableChars.left
    for i=1, #row do
        local cell: string = row[i]
        local len: number = #cell
        local needed: number = (columnWidths[i] - len)

        out ..= cell .. stringPrototypeRepeat(' ', math.round(needed))
        if i ~= #row - 1 then
            out ..= tableChars.middle
        end
    end
    out ..=  tableChars.right
    return out
end

local function tableFunction(head: { [number]: string }, columns: { [number]: string })
    local rows = {} :: { [number]: { [number]: string } }
    local columnWidths = arrayPrototypeMap(head, function(v, i)
        return #v
    end)
    local longestColumn = mathMaxApply(arrayPrototypeMap(columns, function(v)
        return #v
    end))

    for i=1, #head do
        local column = columns[i]
        for j = 1, longestColumn do
            if not rows[j] then
                local s, ss = column:find(tostring(j))
                rows[j] = {}
                rows[j][i] = if s then column:sub(s, ss) else ''
                
                local value: string = rows[j][i]
                local width: number = columnWidths[i] or 0
                local counted: number = #value
                columnWidths[i] = mathMax(width, counted)
            end
        end
    end

    local divider = arrayPrototypeMap(columnWidths, function(i)
        return stringPrototypeRepeat(tableChars.middleMiddle, i + 2)
    end)

    local result = tableChars.topLeft
     .. arrayPrototypeJoin(divider, tableChars.topMiddle)
     .. `{tableChars.topRight}\n`
     .. renderRow(head, columnWidths)
     .. `\n{tableChars.leftMiddle}`
     .. arrayPrototypeJoin(divider, tableChars.rowMiddle)
     .. `\n{tableChars.rightMiddle}\n`

    for _, row in rows do
        result ..= `{renderRow(row, columnWidths)}\n`
    end

    result ..= tableChars.bottomLeft 
    .. arrayPrototypeJoin(divider, tableChars.bottomMiddle) 
    .. tableChars.bottomRight

    return result
end

return tableFunction