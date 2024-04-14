local core = script.Parent.Parent
local MessagePack = require(core.libs.msgpack)
local TableUtil = require(core.libs.tableutil)
local Promise = require(core.wally.promise)
local Warp = require(core.wally.warp)
local MMH3 = require(core.libs.mmh3)
local OnInit = require(core.events.Init)
local ReplicatedStorage = game:GetService"ReplicatedStorage"
local Net = {}

local isServer = require(core.libs.isserver)
local masterkey = require(core.libs.masterkey)
local createEvent = isServer and Warp.Server or Warp.Client
local events = {}
local outgoingStartedEvent
local outgoingBuffer = nil
local outgoingBufferUsed = 0
local outgoingBufferSize = 0
local outgoingInstances = {}
local booleanMap = {
	[false] = 0,
	[true] = 1
}
local numberBooleanMap = {
	[0] = false,
	[1] = true
}

local Hook
OnInit:Connect(function(dependencies)
	Hook = dependencies.Hook
end)

local function initializeBuffer()
	outgoingBufferSize = 64
	outgoingBufferUsed = 0
	outgoingBuffer = buffer.create(64)
end

local function allocate(size:number)

end

local function getEvent(messageName:string)
	local event = events[messageName]
	if not event then
		event = createEvent(messageName)
		events[messageName] = event
	end
	return event
end

function Net.start(messageName:string)
	local event = createEvent(messageName)
	currentStartedEvent = event
	resetBuffer()
end

function Net.getServerTime()
	return workspace:GetServerTimeNow(workspace)
end

local function newSharedRandom(key:string)
	return Random.new(Net.getServerTime()*MMH3.hash32(key))
end

function Net.randomInt(key:string,min:number,max:number)
	return newSharedRandom(key):NextInteger(min,max)
end

function Net.randomFloat(key:string,min:number,max:number)
	return newSharedRandom(key):NextNumber(min,max)
end

if isServer then
	function Net.addNetworkString(messageName:string)
		getEvent(messageName)
	end

	function Net.removeNetworkString(messageName:string)
		events[messageName]:Destroy()
		events[messageName] = nil
	end

	function Net.broadcast(unreliable:boolean)
		currentStartedEvent:Fires(not unreliable,packBuffer(),currentInstanceArguments)
		currentStartedEvent = nil
		resetBuffer()
	end

	function Net.send(player:Player,unreliable:boolean?)
		currentStartedEvent:Fire(not unreliable,player,packBuffer(),currentInstanceArguments)
		currentStartedEvent = nil
		resetBuffer()
	end

	function Net.getReceiveHook(messageName:string)
		local event = events[messageName]
		if not event then

		end
		return
	end

	local fetchHandleStorage
	function Net.onFetchAsync(address:string,callback:(player:Player)->())
		if not fetchHandleStorage then
			fetchHandleStorage = Instance.new("Folder")
			fetchHandleStorage.Name = "Kolloid.Net.FetchHandles"
			fetchHandleStorage.Parent = ReplicatedStorage
		end
		Console.fatalfAssert(fetchHandleStorage:FindFirstChild(address)==nil,"fetch handle '%s' is already in use",address)
		local remote = Instance.new("RemoteFunction")
		remote.Name = address
		remote.OnServerInvoke = callback
		remote.Parent = fetchHandleStorage
	end

	function Net.disconnectHandle(address:string)
		local handle = fetchHandleStorage[address]
		handle:Destroy()
		handle = nil
	end
else
	function Net.sendToServer(unreliable:boolean)
		currentStartedEvent:Fire(not unreliable,packBuffer(),currentInstanceArguments)
		currentStartedEvent = nil
		resetBuffer()
	end

	function Net.onReceive(messageName:string,callback,identifier:any?)
		identifier = identifier or masterkey
		local event = getEvent(messageName)
		if not callback then
			return event
		end
		local handles = getHandles(messageName,identifier)
		handles[identifier] = event:Connect(function(buf,instanceArgs)
			if disabled[messageName] then
				return
			end
			currentBufferOffset = 0
			currentBuffer = buf
			currentInstanceArguments = instanceArgs
			callback()
		end)
		return
	end

	function Net.onceReceive(messageName:string,callback,identifier:any?)
		local event = getEvent(messageName)
		local handles = getHandles(messageName,identifier)
		handles[identifier] = event:Once(function(buf,instanceArgs)
			Net.disconnectReceive(messageName,identifier)
			if disabled[messageName] then
				return
			end
			currentBufferOffset = 0
			currentBuffer = buf
			currentInstanceArguments = instanceArgs
			callback()
		end)
	end

	function Net.waitForReceive(messageName:string,callback)
		local event = getEvent(messageName)
		return event:Wait()
	end

	local fetchHandleStorage
	function Net.fetchAsync(address:string,query:{})
		return Promise.new(function(resolve,reject,onCancel)
			if not fetchHandleStorage then
				fetchHandleStorage = ReplicatedStorage:WaitForChild("Kolloid.Net.FetchHandles")
			end
			local fetchHandle = fetchHandleStorage:WaitForChild(address)
			local data = fetchHandle:InvokeServer(query)
			resolve(data)
		end)
	end
end

function Net.writeInt8(integer:number)
	currentBufferOffset += 1
	table.insert(currentBufferQueue,{buffer.writei8,integer})
	return Net
end

function Net.readInt8()
	local integer = buffer.readi8(currentBuffer,currentBufferOffset)
	currentBufferOffset += 1
	return integer
end

function Net.writeInt16(integer:number)
	currentBufferOffset += 2
	table.insert(currentBufferQueue,{buffer.writei16,integer})
	return Net
end

function Net.readInt16()
	local integer = buffer.readi16(currentBuffer,currentBufferOffset)
	currentBufferOffset += 2
	return integer
end

function Net.writeInt32(integer:number)
	currentBufferOffset += 4
	table.insert(currentBufferQueue,{buffer.writei32,integer})
	return Net
end

function Net.readInt32()
	local integer = buffer.readi32(currentBuffer,currentBufferOffset)
	currentBufferOffset += 4
	return integer
end

function Net.writeUInt8(unsignedInteger:number)
	currentBufferOffset += 1
	table.insert(currentBufferQueue,{buffer.writeu8,unsignedInteger})
	return Net
end

function Net.readUInt8()
	local unsignedInteger = buffer.readu8(currentBuffer,currentBufferOffset)
	currentBufferOffset += 1
	return unsignedInteger
end

function Net.writeUInt16(unsignedInteger:number)
	currentBufferOffset += 2
	table.insert(currentBufferQueue,{buffer.writeu16,unsignedInteger})
	return Net
end

function Net.readUInt16()
	local unsignedInteger = buffer.readu16(currentBuffer,currentBufferOffset)
	currentBufferOffset += 2
	return unsignedInteger
end

function Net.writeUInt32(unsignedInteger:number)
	currentBufferOffset += 4
	table.insert(currentBufferQueue,{buffer.writeu32,unsignedInteger})
	return Net
end

function Net.readUInt32()
	local unsignedInteger = buffer.readu32(currentBuffer,currentBufferOffset)
	currentBufferOffset += 4
	return unsignedInteger
end

function Net.writeFloat(float:number)
	currentBufferOffset += 4
	table.insert(currentBufferQueue,{buffer.writef32,float})
	return Net
end

function Net.readFloat()
	local float = buffer.readf32(currentBuffer,currentBufferOffset)
	currentBufferOffset += 4
	return float
end

function Net.writeDouble(double:number)
	currentBufferOffset += 8
	table.insert(currentBufferQueue,{buffer.writef64,double})
	return Net
end

function Net.readDouble()
	local double = buffer.readf64(currentBuffer,currentBufferOffset)
	currentBufferOffset += 8
	return double
end

function Net.writeBool(boolean:boolean)
	currentBufferOffset += 1
	table.insert(currentBufferQueue,{buffer.writeu8,booleanMap[boolean]})
	return Net
end

function Net.readBool()
	local boolean = numberBooleanMap[buffer.readu8(currentBuffer,currentBufferOffset)]
	currentBufferOffset += 1
	return boolean
end

function Net.writeString(str:string)
	Net.writeUInt16(#str)
	currentBufferOffset += #str
	table.insert(currentBufferQueue,{buffer.writestring,str})
	return Net
end

function Net.readString()
	local length = Net.readUInt16()
	local str = buffer.readstring(currentBuffer,currentBufferOffset,length)
	currentBufferOffset += #str
	return str
end

function Net.writeChar(char:string)
	currentBufferOffset += 1
	table.insert(currentBufferQueue,{buffer.writestring,char})
	return Net
end

function Net.readChar()
	local str = buffer.readstring(currentBuffer,currentBufferOffset,1)
	currentBufferOffset += 1
	return str
end

function Net.writeBuffer(b:buffer)
	Net.writeString(buffer.tostring(b))
	return Net
end

function Net.readBuffer()
	return buffer.fromstring(Net.readString())
end

function Net.writeVector3(vector3:Vector3)
	Net.writeFloat(vector3.X)
	Net.writeFloat(vector3.Y)
	Net.writeFloat(vector3.Z)
	return Net
end

function Net.readVector3()
	return Vector3.new(Net.readFloat(),Net.readFloat(),Net.readFloat())
end

function Net.writeVector3Int16(vector3:Vector3)
	Net.writeInt16(vector3.X)
	Net.writeInt16(vector3.Y)
	Net.writeInt16(vector3.Z)
	return Net
end

function Net.readVector3Int16()
	return Vector3.new(Net.readInt16(),Net.readInt16(),Net.readInt16())
end

function Net.writeVector2(vector2:Vector2)
	Net.writeFloat(vector2.X)
	Net.writeFloat(vector2.Y)
	return Net
end

function Net.readVector2()
	return Vector2.new(Net.readFloat(),Net.readFloat())
end

function Net.writeVector2Int16(vector2:Vector2)
	Net.writeInt16(vector2.X)
	Net.writeInt16(vector2.Y)
	return Net
end

function Net.readVector2Int16()
	return Vector2.new(Net.readInt16(),Net.readInt16())
end

function Net.writeColor3(color3:Color3)
	Net.writeFloat(color3.R)
	Net.writeFloat(color3.G)
	Net.writeFloat(color3.B)
	return Net
end

function Net.readColor3()
	return Color3.new(Net.readFloat(),Net.readFloat(),Net.readFloat())
end

function Net.writeColor3fromRGB(color3fromrgb:Color3)

end

function Net.readColor3fromRGB()

end

function Net.writeBrickColor(brickColor:BrickColor)
	Net.writeUInt32(brickColor.Number)
	return Net
end

function Net.readBrickColor()
	return BrickColor.new(Net.readUInt32())
end

function Net.writeUDim(udim:UDim)
	Net.writeFloat(udim.Scale)
	Net.writeInt32(udim.Offset)
	return Net
end

function Net.readUDim()
	return UDim.new(Net.readFloat(),Net.readInt32())
end

function Net.writeUDim2(udim2:UDim2)
	Net.writeUDim(udim2.X)
	Net.writeUDim(udim2.Y)
	return Net
end

function Net.readUDim2()
	return UDim2.new(Net.readUDim(),Net.readUDim())
end

function Net.writeRotation(cframe:CFrame)
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

function Net.writeCFrame(cframe:CFrame)
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

function Net.writeTable(t:{})
	Net.writeString(MessagePack.pack(t))
	return Net
end

function Net.readTable()
	return MessagePack.unpack(Net.readString())
end

function Net.writeInstance(instance:Instance) --- defer
	table.insert(currentInstanceArguments,instance)
	return Net
end

function Net.readInstance()
	local instance = currentInstanceArguments[1]
	table.remove(currentInstanceArguments,1)
	return instance
end

function Net.readAllInstances()
	return currentInstanceArguments
end

function Net.writeTimestamp()
	Net.writeDouble(Net.getServerTime(workspace))
	return Net
end

function Net.readTimestamp()
	return Net.readDouble()
end

return Net
