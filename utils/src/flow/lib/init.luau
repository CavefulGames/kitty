local go = require(script.Parent.roblox_packages.go)
local Signal = require(script.Parent.roblox_packages.signal)
local Batch = require(script.Batch)
local Timer = require(script.Timer)
local noYield = require(script.noYield)

export type Batch<T> = Batch.Batch<T>
export type Timer = Timer.Timer

local flow = {}

flow.getGameTime = time
flow.getLuaTime = os.clock
flow.getUTCTime = os.time
flow.getSharedTime = workspace.GetServerTimeNow
flow.getRobloxTime = elapsedTime
flow.spawn = go
flow.noYield = noYield

flow.Signal = Signal
flow.Batch = Batch
flow.Timer = Timer

return table.freeze(flow)
