```luau
-- config.luau
return gear.defineConfiguration("db_key", {
    apple = gear.defineField(
      gear.string(1), -- 자료형(HandyNet)
      "A" -- 기본값
    )
  })
  
  -- server.luau
  gear.startServer() -- 수동 구현 필요없어짐, 라이브러리가 대신 해줌 = 넷 난발 안해도 됌 z
  
  local config = require(path.to.config)
  Player.PlayerAdded:Connect(function(player)
    local playerConfig = config:load(player)
    playerConfig().apple = "C"
    playerConfig:save()
  end)
  
  -- client.luau
  local config = require(path.to.config):load() -- 아무것도 없으면 Players.LocalPlayer
  config().apple = "B"
  config:save()
```