[한국어](https://github.com/CavefulGames/HandyNet/blob/main/README_kr.md) 👈
# English

## Flow
A collection of utilities related to script timing, flow, control, and coroutines.
- Includes `LimeSignal` which is fork of `LemonSignal`.

# Example Usage
```lua
-- time, os.clock, time 라벨링
Flow.getGameTime() -- time
Flow.getLuaTime() -- os.clock
Flow.getUTCTime() -- time
Flow.getServerTime() -- workspace:GetServerTimeNow()

-- signal
Flow.Signal.new()
Flow.Bindable.new()

-- threadpool
local t = Flow.spawn(function()
	-- do something
end)

-- Safely killing a thread
Flow.kill(t)

-- timer (from RbxUtil)
local timer = Flow.Timer.new(2)
timer.tick:connect(function()
	print("tock")
end)
timer:start()

-- batch (TaskQueue from RbxUtil)
local bulletBatch = Flow.Batch.new(function(bullets)
	bulletRemoteEvent:FireAllClients(bullets)
end)
bulletBatch:add(someBullet)
bulletBatch:add(someBullet)
bulletBatch:add(someBullet)
```

# TO-DOs
- [x] Add LimeSignal
- [ ] Implement `Batch`
- [ ] Implement `Timer`
- [ ] Test
