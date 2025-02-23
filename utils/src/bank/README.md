# StateBank
반응형 UI의 스테이트를 생성 및 저장을 편하게 관리해주는 유틸리티

## 특징
- `kitty-net`과

## 사용 예시
### Vide
```lua
-- packets.luau
return HandyNet.defineNamespace("example", {
	count = HandyNet.defineEvent()
})

-- shared.luau
local packets = require(path.to.packets)

local states = Bank.new(function()
	return {
		count = vide.source(0)
	}
end)

packets.count.connect(function(player)
	local count = states(player).count
	count(count() + 1)
end)
```
