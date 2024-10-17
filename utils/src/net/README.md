# Net
ByteNet과 Zap에 영감을 얻은 서버와 클라이언트 교신을 위한 강력한 네트워킹 라이브러리

## 특징
- 작동 방식은 Zap을 참고하여 좋은 성능을 자랑합니다.
- API 및 모듈 디자인은 ByteNet을 참고하여 설계했습니다.
- 속도는 조금 느리더라도 더 적은 메모리를 사용하도록 설계했습니다.
- 강력한 타입 체킹과 자동완성을 지원합니다.
- 이론상 Zap과 ByteNet보다 느립니다.
- CFrame은 정렬 상태일 때 13바이트를 차지하며 일반적인 CFrame은 19바이트를 차지합니다. (Special thanks to `roasted_shrimps`)

## 사용 예시
`packets.luau`
```lua
local namespace = Net.defineNamespace("MyNetworking")
return {
	SayHello = namespace:defineReliablePacket(
		"Client", -- from
		Net.sturct({
			message = Net.string(Net.u16)
		}), -- datatype
	)
}
```
`client.luau`
```lua
local packets = require(script.Parent.packets)

packets.SayHello:sendToServer({
	message = "hello, this is from client!"
})
```
`server.luau`
```lua
local packets = require(script.Parent.packets)

packets.SayHello.onReceived:Connect(function(player: Player?, data: { message: string })
	print(data.message)
end)
```

## TODO
- Packet으로 단일 데이터 전송 지원
- RawPacket 구현
- 한 Namespace 마다 한개의 리모트 이벤트를 사용
- ~~패킷 설정값의 from 필드에서 client, server를 Client, Server로 변경~~
- `moonwave` 주석 작성
- crc16 라이선스 문제 해결
- 테스트
