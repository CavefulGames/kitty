--!strict
local primordials = require(script.Parent:WaitForChild('primordials'))

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
}

local arrayPrototypeJoin = primordials.arrayPrototypeJoin
local arrayPrototypeMap = primordials.arrayPrototypeMap
local stringPrototypeRepeat = primordials.stringPrototypeRepeat
local mathMaxApply = primordials.mathMaxApply
local mathMax = primordials.mathMax

local function renderRow(row: { [number]: string }, columnWidths: { [number]: number }): string
    local out = tableChars.left
    for i=1, #row do
        local cell: string = row[i]
        local len: number = #cell
        local needed: number = (columnWidths[i] - len)

        if typeof(cell) == 'table' then
            cell = table.concat(cell)
        end

        out ..= cell .. stringPrototypeRepeat(' ', math.round(needed))
        if i ~= #row - 1 then
            out ..= tableChars.middle
        end
    end
    out ..=  tableChars.right
    return out
end

local function tableFunction(head: { [number]: string }, columns: { [number]: any })
    --[[
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
            if rows[j] == nil then
                rows[j] = {}
            end
            rows[j][i] = if 
                typeof(column) == 'table' and table.find(column, j) then 
                    column[j] else ''
            local value = rows[j][i]
            local width = columnWidths[i] or 0
            local counted = #value
            columnWidths[i] = mathMax(width, counted)
            --[=[
                -- local s, ss = column:find(tostring(j))
                -- rows[j] = {}
                -- rows[j][i] = if s then column:sub(s, ss) else ''
                
                -- local value: string = rows[j][i]
                -- local width: number = columnWidths[i] or 0
                -- local counted: number = #value
                -- columnWidths[i] = mathMax(width, counted)
            --]=]
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
    --]]

    local rows = {  }
    local widths = { 7 }
end

return tableFunction