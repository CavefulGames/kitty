--!strict

--// TODO: do event handling with Warp's signal

--// kit
local Hook = require(script.Parent.hook)
local Debugger = require(script.Parent.debugger)
local Strict = require(script.Parent.strict)
local Net = Debugger.Module({})
type Net = typeof(Net)

--// dependencies
local MsgPack = require(script.Parent["msgpack-luau"])
local Promise = require(script.Parent.promise)
local Warp = require(script.Parent.warp)
local CRC16 = require(script.Parent.crc16)
local Option = require(script.Parent.option)

--// services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()
local events:{[string]:Hook.Event<Option.Option<Player>>} = {}
local outgoingEvent:Hook.Event<Option.Option<Player>>?
local outgoingBuffer:buffer
local outgoingBufferUsed:number
local outgoingBufferSize:number
local outgoingInstances:{Instance} = {}
local incomingBuffer:buffer
local incomingBufferRead:number
local incomingInstances:{Instance}
local booleanMap:{[any]:any} = {
	[0] = false,
	[1] = true,
	[false] = 0,
	[true] = 1
}

Net.orderedInstanceReading = Strict.Mutable(false)

local function initializeBuffer()
	outgoingBufferSize = 64
	outgoingBufferUsed = 0
	outgoingBuffer = buffer.create(64)
	table.clear(outgoingInstances)
end

local function allocate(size:number):number
	if outgoingBufferUsed + size > outgoingBufferSize then
		while outgoingBufferUsed + size > outgoingBufferSize do
			outgoingBufferSize = outgoingBufferSize * 2
		end

		local new_buff = buffer.create(outgoingBufferSize)
		buffer.copy(new_buff, 0, outgoingBuffer, 0, outgoingBufferUsed)

		outgoingBuffer = new_buff
	end

	local offset = outgoingBufferUsed
	outgoingBufferUsed = outgoingBufferUsed + size

	return offset
end

local function getEvent(messageName:string):Hook.Event<Option.Option<Player>>
	local event = events[messageName]
	if event then
		return event
	else
		local newEvent = Hook()
		newEvent.LimitedToSynchronized = true
		events[messageName] = newEvent
		if isServer then
			local warp = Warp.Server(messageName)
			newEvent._warp = warp
			warp:Connect(function(player:Player,buf:buffer,instances:{Instance}) --- to cleanup, do DisconnectAll()
				incomingBufferRead = 0
				incomingBuffer = buf
				incomingInstances = instances
				newEvent:Fire(Option.Some(player))
			end)
			return newEvent
		else
			local warp = Warp.Client(messageName)
			newEvent._warp = warp
			warp:Connect(function(buf:buffer,instances:{Instance})
				incomingBufferRead = 0
				incomingBuffer = buf
				incomingInstances = instances
				newEvent:Fire(Option.None)
			end)
			return newEvent
		end
	end
end

Net.getReceiveEvent = getEvent

function Net.start(messageName:string)
	outgoingEvent = getEvent(messageName)
end

function Net.getServerTime()
	return workspace:GetServerTimeNow()
end

local function newSharedRandom(key:string)
	return Random.new(Net.getServerTime()*CRC16(key))
end

function Net.randomInt(key:string,min:number,max:number)
	return newSharedRandom(key):NextInteger(min,max)
end

function Net.randomFloat(key:string,min:number,max:number)
	return newSharedRandom(key):NextNumber(min,max)
end

if RunService:IsServer() then
	function Net.addNetworkString(messageName:string)
		getEvent(messageName)
	end

	function Net.removeNetworkString(messageName:string)
		events[messageName]:Destroy()
		events[messageName] = nil
	end

	function Net.broadcast(unreliable:boolean)
		if not outgoingEvent then
			error("No event was started, but 'broadcast()' was called")
		end
		outgoingEvent._warp:Fires(not unreliable,outgoingBuffer,#outgoingInstances>0 and outgoingInstances or nil)
		outgoingEvent = nil
	end

	function Net.send(player:Player,unreliable:boolean?)
		if not outgoingEvent then
			error("No event was started, but 'send()' was called")
		end
		outgoingEvent._warp:Fire(not unreliable,player,outgoingBuffer,#outgoingInstances>0 and outgoingInstances or nil)
		outgoingEvent = nil
		initializeBuffer()
	end

	local fetchHandleStorage
	function Net.onFetch(address:string,callback:(player:Player)->())
		if not fetchHandleStorage then
			fetchHandleStorage = Instance.new("Folder")
			fetchHandleStorage.Name = "Kolloid.Net.FetchHandles"
			fetchHandleStorage.Parent = ReplicatedStorage
		end
		if fetchHandleStorage:FindFirstChild(address) ~= nil then
			error(`fetch handle '{address}' is already in use`)
		end
		local remote = Instance.new("RemoteFunction")
		remote.Name = address
		remote.OnServerInvoke = callback
		remote.Parent = fetchHandleStorage
	end

	function Net.disconnectHandle(address:string)
		if not fetchHandleStorage then
			error("Handle not initialized")
		end
		local handle = fetchHandleStorage:FindFirstChild(address)
		if not handle then
			error(`Handle '{address}' not found`)
		end
		handle:Destroy()
		handle = nil
	end
else
	function Net.sendToServer(unreliable:boolean)
		if not outgoingEvent then
			error("No event was started, but 'sendToServer()' was called")
		end
		outgoingEvent._warp:Fire(not unreliable,outgoingBuffer,#outgoingInstances>0 and outgoingInstances or nil)
		outgoingEvent = nil
		initializeBuffer()
	end

	local fetchHandleStorage
	function Net.fetch(address:string,query:{})
		return Promise.new(function(resolve,reject,onCancel)
			if not fetchHandleStorage then
				fetchHandleStorage = ReplicatedStorage:WaitForChild("Kolloid.Net.FetchHandles")
			end
			local fetchHandle = fetchHandleStorage:WaitForChild(address)::RemoteFunction
			local data = fetchHandle:InvokeServer(query)
			resolve(data)
		end)
	end
end

function Net.writeInt8(int8:number):Net
	buffer.writei8(outgoingBuffer,allocate(1),int8)
	return Net
end;Debugger.Inspector(function(x)
	if x > math.pow(2,8)-1 then
		error("dang")
	end
end)

function Net.readInt8():number
	local i8 = buffer.readi8(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 1
	return i8
end

function Net.writeInt16(int16:number):Net
	buffer.writei16(outgoingBuffer,allocate(2),int16)
	return Net
end

function Net.readInt16():number
	local i16 = buffer.readi16(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 2
	return i16
end

function Net.writeInt32(i32:number):Net
	buffer.writei32(outgoingBuffer,allocate(4),i32)
	return Net
end

function Net.readInt32():number
	local i32 = buffer.readi32(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 4
	return i32
end

function Net.writeUInt8(u8:number):Net
	buffer.writeu8(outgoingBuffer,allocate(1),u8)
	return Net
end

function Net.readUInt8():number
	local u8 = buffer.readu8(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 1
	return u8
end

function Net.writeUInt16(u16:number):Net
	buffer.writeu16(outgoingBuffer,allocate(2),u16)
	return Net
end

function Net.readUInt16():number
	local u16 = buffer.readu16(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 2
	return u16
end

function Net.writeUInt32(u32:number):Net
	buffer.writeu32(outgoingBuffer,allocate(4),u32)
	return Net
end

function Net.readUInt32():number
	local u32 = buffer.readu32(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 4
	return u32
end

function Net.writeFloat32(f32:number):Net
	buffer.writef32(outgoingBuffer,allocate(4),f32)
	return Net
end

function Net.readFloat32():number
	local f32 = buffer.readf32(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 4
	return f32
end

function Net.writeFloat64(f64:number):Net
	buffer.writef64(outgoingBuffer,allocate(8),f64)
	return Net
end

function Net.readFloat64():number
	local f64 = buffer.readf64(incomingBuffer,incomingBufferRead)
	incomingBufferRead += 8
	return f64
end

function Net.writeBool(boolean:boolean):Net
	buffer.writeu8(outgoingBuffer,allocate(1),booleanMap[boolean])
	return Net
end

function Net.readBool():boolean
	local boolean = booleanMap[buffer.readu8(incomingBuffer,incomingBufferRead)]
	incomingBufferRead += 1
	return boolean
end

function Net.writeString(str:string):Net
	local len = #str
	Net.writeUInt16(len)
	buffer.writestring(outgoingBuffer,allocate(len),str,len)
	return Net
end

function Net.readString():string
	local len = Net.readUInt16()
	local str = buffer.readstring(incomingBuffer,incomingBufferRead,len)
	incomingBufferRead += #str
	return str
end

function Net.writeChar(char:string):Net
	Net.writeUInt8(char:byte())
	return Net
end

function Net.readChar():string
	local char = string.char(Net.readUInt8())
	return char
end

function Net.writeBuffer(b:buffer):Net
	Net.writeString(buffer.tostring(b))
	return Net
end

function Net.readBuffer()
	return buffer.fromstring(Net.readString())
end

function Net.writeVector3(vector3:Vector3):Net
	Net.writeFloat(vector3.X)
	Net.writeFloat(vector3.Y)
	Net.writeFloat(vector3.Z)
	return Net
end

function Net.readVector3()
	return Vector3.new(Net.readFloat(),Net.readFloat(),Net.readFloat())
end

function Net.writeVector3Int16(vector3:Vector3):Net
	Net.writeInt16(vector3.X)
	Net.writeInt16(vector3.Y)
	Net.writeInt16(vector3.Z)
	return Net
end

function Net.readVector3Int16()
	return Vector3.new(Net.readInt16(),Net.readInt16(),Net.readInt16())
end

function Net.writeVector2(vector2:Vector2):Net
	Net.writeFloat(vector2.X)
	Net.writeFloat(vector2.Y)
	return Net
end

function Net.readVector2()
	return Vector2.new(Net.readFloat(),Net.readFloat())
end

function Net.writeVector2Int16(vector2:Vector2):Net
	Net.writeInt16(vector2.X)
	Net.writeInt16(vector2.Y)
	return Net
end

function Net.readVector2Int16()
	return Vector2.new(Net.readInt16(),Net.readInt16())
end

function Net.writeColor3(color3:Color3):Net --- 32 * 3 = 96 bytes
	Net.writeFloat(color3.R)
	Net.writeFloat(color3.G)
	Net.writeFloat(color3.B)
	return Net
end

function Net.readColor3()
	return Color3.new(Net.readFloat(),Net.readFloat(),Net.readFloat())
end

function Net.writeColor3Int8(color3:Color3):Net --- 8 * 3 = 24 bytes
	Net.writeUInt8(math.round(color3.R*255))
	Net.writeUInt8(math.round(color3.G*255))
	Net.writeUInt8(math.round(color3.B*255))
	return Net
end

function Net.readColor3Int8():Color3
	return Color3.fromRGB(Net.readUInt8(),Net.readUInt8(),Net.readUInt8())
end

function Net.writeBrickColor(brickColor:BrickColor):Net
	Net.writeUInt32(brickColor.Number)
	return Net
end

function Net.readBrickColor()
	return BrickColor.new(Net.readUInt32())
end

function Net.writeUDim(udim:UDim):Net
	Net.writeFloat(udim.Scale)
	Net.writeInt32(udim.Offset)
	return Net
end

function Net.readUDim()
	return UDim.new(Net.readFloat(),Net.readInt32())
end

function Net.writeUDim2(udim2:UDim2):Net
	Net.writeUDim(udim2.X)
	Net.writeUDim(udim2.Y)
	return Net
end

function Net.readUDim2()
	return UDim2.new(Net.readUDim(),Net.readUDim())
end

function Net.writeRotation(cframe:CFrame):Net
	local LookVector = cframe.LookVector
	local Azumith = math.atan2(-LookVector.X, -LookVector.Z)
	local Elevation = math.atan2(LookVector.Y, math.sqrt(LookVector.X * LookVector.X + LookVector.Z * LookVector.Z))
	local WithoutRoll = CFrame.new(cframe.Position) * CFrame.Angles(0, Azumith, 0) * CFrame.Angles(Elevation, 0, 0)
	local _, _, Roll = (WithoutRoll:Inverse() * cframe):ToEulerAnglesXYZ()

	-- Atan2 -> in the range [-pi, pi]
	Azumith = math.floor(((Azumith / math.pi) * 2097151) + 0.5)
	Roll = math.floor(((Roll / math.pi) * 1048575) + 0.5)
	Elevation = math.floor(((Elevation / 1.5707963267949) * 1048575) + 0.5)

	--buffer:WriteInt(22, Azumith)
	Net.writeInt32(Azumith)
	--buffer:WriteInt(21, Roll)
	Net.writeInt32(Roll)
	--buffer:WriteInt(21, Elevation)
	Net.writeInt32(Elevation)

	return Net
end

function Net.readRotation()
	--local Azumith = buffer:ReadInt(22)
	local Azumith = Net.readInt32()
	--local Roll = buffer:ReadInt(21)
	local Roll = Net.readInt32()
	--local Elevation = buffer:ReadInt(21)
	local Elevation = Net.readInt32()

	Azumith = math.pi * (Azumith / 2097151)
	Roll = math.pi * (Roll / 1048575)
	Elevation = math.pi * (Elevation / 1048575)

	local Rotation = CFrame.Angles(0, Azumith, 0)
	Rotation = Rotation * CFrame.Angles(Elevation, 0, 0)
	Rotation = Rotation * CFrame.Angles(0, 0, Roll)

	return Rotation
end

function Net.writeCFrame(cframe:CFrame):Net
	Net.writeVector3(cframe.Position)
	Net.writeRotation(cframe)
	return Net
end

function Net.readCFrame()
	local Position = CFrame.new(Net.readVector3())

	--local Azumith = buffer:ReadInt(22)
	local Azumith = Net.readInt32()
	--local Roll = buffer:ReadInt(21)
	local Roll = Net.readInt32()
	--local Elevation = buffer:ReadInt(21)
	local Elevation = Net.readInt32()

	Azumith = math.pi * (Azumith / 2097151)
	Roll = math.pi * (Roll / 1048575)
	Elevation = math.pi * (Elevation / 1048575)

	local Rotation = CFrame.fromOrientation(Elevation, Azumith, Roll)

	return Position * Rotation
end

function Net.writeTable(t:{[any]:any}):Net
	Net.writeString(MsgPack.encode(t))
	return Net
end

function Net.readTable():{[any]:any}
	return MsgPack.decode(Net.readString())
end

function Net.writeInstance(instance:Instance):Net
	table.insert(outgoingInstances,instance)
	return Net
end

function Net.readInstance()
	local instance = incomingInstances[1]
	table.remove(incomingInstances,1)
	return instance
end

--// ORDERED INSTANCE READING (should i support this?)
-- function Net.writeInstance(instance:Instance):Net
-- 	table.insert(outgoingInstances,instance)
-- 	Net.writeUInt8(#outgoingInstances)
-- 	return Net
-- end

-- function Net.readInstance()
-- 	local instance = incomingInstances[Net.readUInt8()]
-- 	return instance
-- end

function Net.readAllInstances()
	return outgoingInstances
end

function Net.writeTimestamp():Net
	Net.writeDouble(Net.getServerTime())
	return Net
end

function Net.readTimestamp()
	return Net.readDouble()
end

initializeBuffer()

return Strict.Capsule(Net)
