# Net
- ByteNet과 Zap에 영감을 얻은 서버와 클라이언트 교신을 위한 네트워킹 라이브러리

# Example
`packets.luau`
```lua
return Net.defineNamespace("MyNetworking", {
	SayHello = Net.definePacket({
		reliable = true,
		from = "Client",
		data = {
			message = Net.string(Net.u16)
		}
	})
})
```
`client.luau`
```lua
local packets = require(script.Parent.packets)

packets.SayHello.sendToServer({
	message = "hello, this is from client!"
})
```
`server.luau`
```lua
local packets = require(script.Parent.packets)

packets.SayHello.onReceive:Connect(function(data)
	print(data.message)
end)
```

# TODO
- definePacket으로 단일 데이터 전송 지원
- defineRawPacket 구현
- 한 Namespace 마다 한개의 리모트 이벤트를 사용
- 페킷 설정값의 from 필드에서 client, server를 Client, Server로 변경
- `moonwave` 주석 작성
