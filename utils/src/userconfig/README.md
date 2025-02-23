# UserConfig
유저 설정을 관리하는 라이브러리

## 특징
- 설정 정보는 데이터스토어와 연동됨
- 변경된 값만 서버에 전송하여 저장함
- 클라이언트 정보를 신뢰함 (서버에서 스키마 검사는 진행함)
- 압축 기능 포함
- 타입 체크, 자동완성을 지원함

## 사용 예시
```lua
-- userconfig.luau
local UserConfig = require(script.Parent.packages.userconfig)
return UserConfig.new({
	mySetting = "";
	mySetting1 = 123;
})

-- client.luau
local config = require(script.Parent.userconfig)

config().mySetting = "aaaa"
config:saveChangesToServer()
```

## TODO
- 기초 구현
