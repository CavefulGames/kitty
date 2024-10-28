# PaidContents
유료 콘텐츠 추상화 유틸리티

## 사용 예시
```lua
-- paidcontents.luau
return PaidContents {
	passes = {
		ak8087 = {
			id = 1234567,
			image = 1234567
		}
	},
	developerProducts = {
		bail = 1234567
	},
}

paidcontents.passes.ak8087:promptPurchase()
paidcontents.passes.ak8087.price
paidcontents.passes.ak8087.id
paidcontents.passes.ak8087.image
paidcontents.passes.ak8087.name
paidcontents.passes.ak8087:userOwns(player.UserId) -- server only
paidcontents.passes.ak8087.owns -- client only
```
