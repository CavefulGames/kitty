# Net
- ByteNet과 Zap에 영감을 얻은 네트워킹 라이브러리

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
- Support single data reader&writer for definePacket
- defineRawPacket
- Use a RemoteEvent per namespaces
- Rename packet config's from field "server", "client" into "Server", "Client"
- Add moonwave comments
