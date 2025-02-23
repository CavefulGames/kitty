local strict = require(script.Parent.roblox_packages.strict)
local threadpool = require(script.Parent.roblox_packages.threadpool)
local limesignal = require(script.Parent.roblox_packages.limesignal)
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
flow.spawn = threadpool
flow.noYield = noYield

flow.Signal = limesignal.Signal
flow.Bindable = limesignal.Bindable
flow.Batch = Batch
flow.Timer = Timer

return strict.table(flow, "flow")
