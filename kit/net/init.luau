--!strict

--// inspired by bytenet and zap

--// $Kit
local Hook = require(script.Parent.hook)
local Debugger = require(script.Parent.debugger)
local Strict = require(script.Parent.strict)
--- @class Net
local Net = {}

--// $Packages
local MsgPack = require(script.Parent["msgpack-luau"])
local Promise = require(script.Parent.promise)
local CRC16 = require(script.Parent.crc16)

--// $Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// $PrivateVariables
local isServer = RunService:IsServer()
local outgoingBuffer: buffer
local outgoingBufferUsed: number
local outgoingBufferSize: number
local outgoingBufferApos: number
local outgoingInstances: { Instance }
local incomingBuffer: buffer
local incomingBufferRead: number
local incomingInstances: { Instance }
local incomingInstancePos: number
local reliableRemoteEvent: RemoteEvent
local unreliableRemoteEvent: UnreliableRemoteEvent
local remoteFunction: RemoteFunction
local packetId = 1
local packetNames = {}
local events = {}
local writingDebuggerWarned = false
local playerMap: { [Player]: {
	buff: buffer,
	inst: { Instance },
	size: number,
	used: number
} } = {}

--// $Constants
local EXECEPTION_OUT_OF_RANGE = "Literal out of range for '%s'"
local EXECEPTION_NEGATIVE_NUMBER = "Cannot apply unary operator '-' to type '%s'"
local EXECEPTION_FLOATING_NUMBER = "Expected '%s', found floating-point number"

--// $PrivateFunctions
local function fetchRemoteEvents()
	if isServer then
		reliableRemoteEvent = Instance.new("RemoteEvent")
		reliableRemoteEvent.Name = "ReliableRemoteEvent"
		reliableRemoteEvent.Parent = script
		unreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
		unreliableRemoteEvent.Name = "UnreliableRemoteEvent"
		unreliableRemoteEvent.Parent = script
	else
		reliableRemoteEvent = script:WaitForChild("ReliableRemoteEvent", 10) :: any
		unreliableRemoteEvent = script:WaitForChild("UnreliableRemoteEvent", 10) :: any
	end
end

local function load(data: {
	buff: buffer,
	used: number,
	size: number,
	inst: { Instance },
})
	outgoingBuffer = data.buff
	outgoingBufferUsed = data.used
	outgoingBufferSize = data.size
	outgoingInstances = data.inst
end

local function save()
	return {
		buff = outgoingBuffer,
		used = outgoingBufferUsed,
		size = outgoingBufferSize,
		inst = outgoingInstances,
	}
end

local function loadEmpty()
	outgoingBufferSize = 64
	outgoingBufferUsed = 0
	outgoingBuffer = buffer.create(64)
	outgoingInstances = {}
end

local function reserve(size: number)
	if outgoingBufferUsed + size > outgoingBufferSize then
		while outgoingBufferUsed + size > outgoingBufferSize do
			outgoingBufferSize = outgoingBufferSize * 2
		end

		local new_buff = buffer.create(outgoingBufferSize)
		buffer.copy(new_buff, 0, outgoingBuffer, 0, outgoingBufferUsed)

		outgoingBuffer = new_buff
	end

	outgoingBufferApos = outgoingBufferUsed
	outgoingBufferUsed += size
end

local function read(size: number): number
	local offset = incomingBufferRead
	incomingBufferRead += size
	return offset
end

local function newSharedRandom(key: string)
	return Random.new(workspace:GetServerTimeNow() * CRC16(key))
end

local function loadPlayer(player: Player)
	if playerMap[player] then
		load(playerMap[player])
	else
		loadEmpty()
	end
end

--// $Events
if isServer then
	Players.PlayerRemoving:Connect(function(player)
		playerMap[player] = nil
	end)

	RunService.Heartbeat:Connect(function()
		for player, outgoing in playerMap do
			if outgoing.used > 0 then
				local buff = buffer.create(outgoing.used)
				buffer.copy(buff, 0, outgoing.buff, 0, outgoing.used)

				reliableRemoteEvent:FireClient(player, buff, outgoing.inst)

				outgoing.buff = buffer.create(64)
				outgoing.used = 0
				outgoing.size = 64
				table.clear(outgoing.inst)
			end
		end
	end)
else
	local time = 0

	RunService.Heartbeat:Connect(function(dt)
		time += dt

		if time >= (1 / 61) then
			time -= (1 / 61)

			if outgoingBufferUsed ~= 0 then
				local buff = buffer.create(outgoingBufferUsed)
				buffer.copy(buff, 0, outgoingBuffer, 0, outgoingBufferUsed)

				reliableRemoteEvent:FireServer(buff, outgoingInstances)

				outgoingBuffer = buffer.create(64)
				outgoingBufferUsed = 0
				outgoingBufferSize = 64
				table.clear(outgoingInstances)
			end
		end
	end)
end

--// $SerDes $Fields
--// write (buffer, offset, value)
--// read (buffer, offset)
type RW = { [number]: (value: any) -> any }
type AdvancedPrimitiveNumber = { value: number, callback: () -> ()?, doClamp: boolean?, lastSentServerTime: number?, lastWrote: string?, timeTakenToWrite: number?, doRecord: boolean? }

local u8R, u8W =
	function(): number
		return buffer.readu8(incomingBuffer, read(1))
	end, function(value: number)
		if Debugger.enabled() then
			local t = "u8"
			if value > 2^8-1 then
				Debugger.warn(EXECEPTION_OUT_OF_RANGE:format(t))
			elseif value < 0 then
				Debugger.warn(EXECEPTION_NEGATIVE_NUMBER:format(t))
			elseif value % 1 ~= 0 then
				Debugger.warn(EXECEPTION_FLOATING_NUMBER:format(t))
			end
		end
		reserve(1)
		buffer.writeu8(outgoingBuffer, outgoingBufferApos, value)
	end
export type u8 = AdvancedPrimitiveNumber
--- @prop u8 number
--- @within Net
--- 부호 없는 8비트 정수
Net.u8 = (({ u8R, u8W } :: RW) :: any) :: number | u8

local u16R, u16W =
	function(): number
		return buffer.readu16(incomingBuffer, read(2))
	end, function(value: number)
		if Debugger.enabled() then
			if value > 2^16-1 then
				Debugger.warn("Literal out of range for 'u16'")
			elseif value < 0 then
				Debugger.warn("Cannot apply unary operator '-' to type 'u16'")
			elseif value % 1 ~= 0 then
				Debugger.warn("Expected 'u16', found floating-point number")
			end
		end
		reserve(2)
		buffer.writeu16(outgoingBuffer, outgoingBufferApos, value)
	end
export type u16 = AdvancedPrimitiveNumber
--- @prop u16 number
--- @within Net
--- 부호 없는 16비트 정수
Net.u16 = (({ u16R, u16W } :: RW ) :: any) :: number | u16

local u32R, u32W =
	function(): number
		return buffer.readu32(incomingBuffer, read(4))
	end,
	function(value: number)
		if Debugger.enabled() then
			if value > 2^32-1 then
				Debugger.warn("Literal out of range for 'u32'")
			elseif value < 0 then
				Debugger.warn("Cannot apply unary operator '-' to type 'u32'")
			elseif value % 1 ~= 0 then
				Debugger.warn("Expected 'u32', found floating-point number")
			end
		end
		reserve(4)
		buffer.writeu32(outgoingBuffer, outgoingBufferApos, value)
	end
export type u32 = AdvancedPrimitiveNumber
--- @prop u32 number
--- @within Net
--- 부호 없는 32비트 정수
Net.u32 = (({ u32R, u32W } :: RW ) :: any) :: number | u32

local i8R, i8W =
	function(): number
		return buffer.readi8(incomingBuffer, read(1))
	end, function(value: number)
		if Debugger.enabled() then
			if value > 2^7-1 or value < -2^7 then
				Debugger.warn("Literal out of range for 'i8'")
			elseif value % 1 ~= 0 then
				Debugger.warn("Expected 'i8', found floating-point number")
			end
		end
		reserve(1)
		buffer.writei8(outgoingBuffer, outgoingBufferApos, value)
	end
export type i8 = AdvancedPrimitiveNumber
--- @prop i8 number
--- @within Net
--- 8비트 정수
Net.i8 = (({ i8R, i8W } :: RW) :: any) :: number | i8

local i16R, i16W =
	function(): number
		return buffer.readi16(incomingBuffer, read(2))
	end, function(value: number)
		if Debugger.enabled() then
			if value > 2^15-1 or value < -2^15 then
				Debugger.warn("Literal out of range for 'i16'")
			elseif value % 1 ~= 0 then
				Debugger.warn("Expected 'i8', found floating-point number")
			end
		end
		reserve(2)
		buffer.writei16(outgoingBuffer, outgoingBufferApos, value)
	end
export type i16 = AdvancedPrimitiveNumber
--- @prop i16 number
--- @within Net
--- 16비트 정수
Net.i16 = (({ i16R, i16W } :: RW) :: any) :: number | i16

local i32R, i32W =
	function(): number
		return buffer.readi32(incomingBuffer, read(4))
	end, function(value: number)
		outgoingBufferApos = reserve(4)
		buffer.writei32(outgoingBuffer, outgoingBufferApos, value)
	end
export type i32 = AdvancedPrimitiveNumber
--- @prop i32 number
--- @within Net
--- 32비트 정수
Net.i32 = (({ i32R, i32W } :: RW) :: any) :: number | i32

local f32R, f32W =
	function(): number
		return buffer.readf32(incomingBuffer, read(4))
	end, function(value: number)
		outgoingBufferApos = reserve(4)
		buffer.writef32(outgoingBuffer, outgoingBufferApos, value)
	end
export type f32 = AdvancedPrimitiveNumber
--- @prop f32 number
--- @within Net
--- 32비트 표준 부동소수점
Net.f32 = (({ f32R, f32W } :: RW) :: any) :: number | f32

local f64R, f64W =
	function(): number
		return buffer.readf64(incomingBuffer, read(8))
	end, function(value: number)
		outgoingBufferApos = reserve(8)
		buffer.writef64(outgoingBuffer, outgoingBufferApos, value)
	end
export type f64 = AdvancedPrimitiveNumber
--- @prop f64 number
--- @within Net
--- 64비트 표준 부동소수점
Net.f64 = (({ f64R, f64W } :: RW) :: any) :: number | f64

local stringR, stringW =
	function(): string
		local length = buffer.readu16(incomingBuffer, read(2))
		return buffer.readstring(incomingBuffer, read(length), length)
	end, function(value: string)
		local length = #value
		outgoingBufferApos = reserve(2)
		buffer.writeu16(outgoingBuffer, outgoingBufferApos, length)
		buffer.writestring(outgoingBuffer, length, value)
	end
--- @prop string string
--- @within Net
--- 부호 없는 16비트 정수의 최대 길이만큼의 길이를 가질 수 있는 문자열
Net.string = (({ stringR, stringW } :: RW) :: any) :: string

local boolR, boolW =
	function(): boolean
		return buffer.readu8(incomingBuffer, read(1)) == 0
	end,
	function(value: boolean)
		outgoingBufferApos = reserve(1)
		buffer.writeu8(outgoingBuffer, outgoingBufferApos, if value then 1 else 0)
	end
--- @prop boolean boolean
--- @within Net
--- 8비트를 사용하는 불리언
Net.boolean = (({ boolR, boolW } :: RW) :: any) :: boolean

local tableR, tableW =
	function(): { [any]: any }
		return MsgPack.decode(stringR())
	end,
	function(value: { [any]: any })
		stringW(MsgPack.encode(value))
	end
--- @prop table { [any]: any }
--- @within Net
--- MessagePack으로 인코딩된 테이블
--- 타입 케스팅을 통해 테이블 타입체킹을 할 수 있습니다.
Net.table = ({ tableR, tableW } :: RW) :: { [any]: any }

local charR, charW =
	function(): string
		return string.char(u8R())
	end, function(value: string)
		u8W(string.byte(value))
	end
--- @prop char string
--- @within Net
--- 8비트 한 자리 문자
Net.char = (({ charR, charW } :: RW) :: any) :: string

local bufferR, bufferW =
	function(): buffer
		return buffer.fromstring(stringR())
	end, function(value: buffer)
		stringW(buffer.tostring(value))
	end
--- @prop buffer buffer
--- @within Net
--- Luau buffer 데이터 타입
Net.buffer = (({ bufferR, bufferW } :: RW) :: any) :: buffer

local vector3R, vector3W =
	function(): Vector3
		return Vector3.new(f32R(), f32R(), f32R())
	end, function(value: Vector3)
		f32W(value.X)
		f32W(value.Y)
		f32W(value.Z)
	end
--- @prop vector3 Vector3
--- @within Net
--- 32비트 표준 부동소수점으로 구성된 3차원 벡터 데이터 타입
Net.vector3 = (({ vector3R, vector3W } :: RW) :: any) :: Vector3

local vector3int16R, vector3int16W =
	function(): Vector3int16
		return Vector3int16.new(i16R(), i16R(), i16R())
	end,function(value: Vector3int16)
		i16W(value.X)
		i16W(value.Y)
		i16W(value.Z)
	end
--- @prop vector3int16 Vector3int16
--- @within Net
--- 16비트 정수로 구성된 3차원 벡터 데이터 타입
Net.vector3int16 = (({ vector3int16R, vector3int16W } :: RW) :: any) :: Vector3int16

local vector2R, vector2W =
	function(): Vector2
		return Vector2.new(f32R(), f32R())
	end, function(value: Vector2)
		f32W(value.X)
		f32W(value.Y)
	end
--- @prop vector2 Vector2
--- @within Net
--- 32비트 표준 부동소수점으로 구성된 2차원 벡터 데이터 타입
Net.vector2 = (({ vector2R, vector2W } :: RW) :: any) :: Vector2

local vector2int16R, vector2int16W =
	function(): Vector2int16
		return Vector2int16.new(i16R(), i16R())
	end, function(value: Vector2int16)
		i16W(value.X)
		i16W(value.Y)
	end
--- @prop vector2int16 Vector2int16
--- @within Net
--- 16비트 정수로 구성된 2차원 벡터 데이터 타입
Net.vector2int16 = (({ vector2int16R, vector2int16W } :: RW) :: any) :: Vector2int16

local udimR, udimW =
	function(): UDim
		return UDim.new(f32R(), i32R())
	end,
	function(value: UDim)
		f32W(value.Scale)
		i32W(value.Offset)
	end
--- @prop udim UDim
--- @within Net
--- UDim 데이터 타입
Net.udim = (({ udimR, udimW } :: RW) :: any) :: UDim

local udim2R, udim2W =
	function(): UDim2
		return UDim2.new(udimR(),udimR())
	end, function(value: UDim2)
		udimW(value.X)
		udimW(value.Y)
	end
--- @prop udim2 UDim2
--- @within Net
--- UDim2 데이터 타입
Net.udim2 = (({ udim2R, udim2W } :: RW) :: any) :: UDim2

local color3R, color3W =
	function(): Color3
		return Color3.new(f32R(), f32R(), f32R())
	end, function(value: Color3)
		f32W(value.R)
		f32W(value.G)
		f32W(value.B)
	end
--- @prop color3 Color3
--- @within Net
--- 32비트 표준 부동소수점으로 구성된 Color3 데이터 타입
Net.color3 = (({ color3R, color3W } :: RW) :: any) :: Color3

local color3uint8R, color3uint8W =
	function(): Color3
		return Color3.fromRGB(u8R(), u8R(), u8R())
	end, function(value: Color3)
		u8W(math.floor(value.R * 255))
		u8W(math.floor(value.G * 255))
		u8W(math.floor(value.B * 255))
	end
--- @prop color3uint8 Color3
--- @within Net
--- 부호 없는 8비트 정수로 구성된 Color3 데이터 타입
Net.color3uint8 = (({ color3uint8R, color3uint8W } :: RW) :: any) :: Color3

local cframeRotationR, cframeRotationW =
	function(): CFrame
		local azumith = i32R()
		local roll = i32R()
		local elevation = i32R()

		azumith = math.pi * (azumith / 2097151)
		roll = math.pi * (roll / 1048575)
		elevation = math.pi * (elevation / 1048575)

		local rotation = CFrame.fromOrientation(elevation, azumith, roll)

		return rotation
	end, function(value: CFrame)
		local lookVector = value.LookVector
		local azumith = math.atan2(-lookVector.X, -lookVector.Z)
		local elevation = math.atan2(lookVector.Y, math.sqrt(lookVector.X * lookVector.X + lookVector.Z * lookVector.Z))
		local withoutRoll = CFrame.new(value.Position) * CFrame.Angles(0, azumith, 0) * CFrame.Angles(elevation, 0, 0)
		local _, _, roll = (withoutRoll:Inverse() * value):ToEulerAnglesXYZ()

		-- Atan2 -> in the range [-pi, pi]
		azumith = math.floor(((azumith / math.pi) * 2097151) + 0.5)
		roll = math.floor(((roll / math.pi) * 1048575) + 0.5)
		elevation = math.floor(((elevation / 1.5707963267949) * 1048575) + 0.5)

		i32W(azumith)
		i32W(roll)
		i32W(elevation)
	end
type CFrameRotation = {}
--- @prop cframeRotation CFrame
--- @within Net
--- CFrame 회전값
Net.cframeRotation = (({ cframeRotationR, cframeRotationW } :: RW) :: any) :: CFrame | CFrameRotation

local cframeR, cframeW =
	function(): CFrame
		local position = CFrame.new(vector3R())
		local rotation = cframeRotationR()
		return position * rotation
	end,
	function(value: CFrame)
		vector3W(value.Position)
		cframeRotationW(value)
	end
--- @prop cframe CFrame
--- @within Net
--- CFrame 데이터 타입
Net.cframe = (({ cframeR, cframeW } :: RW) :: any) :: CFrame

local brickcolorR, brickcolorW =
	function(): BrickColor
		return BrickColor.new(u16R())
	end, function(value: BrickColor)
		u16W(value.Number)
	end
--- @prop brickColor BrickColor
--- @within Net
--- 16비트 BrickColor 데이터 타입
Net.brickColor = (({ brickcolorR, brickcolorW } :: RW) :: any) :: BrickColor

local numberrangeR, numberrangeW =
	function(): NumberRange
		return NumberRange.new(f32R(),f32R())
	end, function(value: NumberRange)
		f32W(value.Min)
		f32W(value.Max)
	end
--- @prop numberRange NumberRange
--- @within Net
--- NumberRange 데이터 타입
Net.numberRange = (({ numberrangeR, numberrangeW } :: RW) :: any) :: NumberRange

local numbersequenceR, numbersequenceW =
	function(): NumberSequence
		local count = u32R()
		local keypoints: { NumberSequenceKeypoint } = table.create(count)
		for i = 1, count do
			table.insert(keypoints, NumberSequenceKeypoint.new(f32R(), f32R(), f32R()))
		end
		return NumberSequence.new(keypoints)
	end, function(value: NumberSequence)
		local keypoints = value.Keypoints
		u32W(#keypoints)
		for i, v in keypoints do
			f32W(v.Time)
			f32W(v.Value)
			f32W(v.Envelope)
		end
	end
--- @prop numberSequence NumberSequence
--- @within Net
--- numberSequence 데이터 타입
Net.numberSequence = (({ numbersequenceR, numbersequenceW } :: RW) :: any) :: NumberSequence
local colorsequenceR, colorsequenceW =
	function(): ColorSequence
		local count = u32R()
		local keypoints: { ColorSequenceKeypoint } = table.create(count)
		for i = 1, count do
			table.insert(keypoints, ColorSequenceKeypoint.new(f32R(), color3R()))
		end
		return ColorSequence.new(keypoints)
	end, function(value: ColorSequence)
		local keypoints = value.Keypoints
		u32W(#keypoints)
		for i, v in keypoints do
			f32W(v.Time)
			color3W(v.Value)
		end
	end
--- @prop colorSequence ColorSequence
--- @within Net
--- ColorSequence 데이터 타입
Net.colorSequence = (({ colorsequenceR, colorsequenceW } :: RW) :: any) :: ColorSequence

local instanceR, instanceW =
	function(): Instance
		incomingInstancePos += 1
		return incomingInstances[incomingInstancePos]
	end, function(value: Instance)
		table.insert(outgoingInstances, value)
	end
--- @prop instance Instance
--- @within Net
--- 로블록스 인스턴스 데이터 타입
--- 타입케스팅을 사용하여 인스턴스의 타입을 지정하세요.
Net.instance = (({ instanceR, instanceW } :: RW) :: any) :: Instance

local enumRWs: { [string]: RW } = {}
--- @prop enum Enum
--- @within Net
--- Enum 데이터 타입
--- Net.Enum[Enum Name]처럼 인덱싱하여 Enum을 지정하여 사용하세요.
Net.enum = (setmetatable(enumRWs, {
	__index = function(self, k: string)
		local enum = (Enum :: { [any]: any })[k] :: Enum
		local items: { EnumItem } = enum:GetEnumItems()
		local R,W = function(): EnumItem
			local item
			local value = u16R()
			for _,v in items do
				if v.Value == value then
					item = v
					break
				end
			end
			return item
		end, function(value: EnumItem)
			u16W(value.Value)
		end
		rawset(enumRWs, k, {R, W} :: RW)
	end
}) :: any) :: typeof(Enum)

--// $PublicFunctions
type BasePacket<T, P> = {
	onReceive: Hook.HookedEvent<T>
} & P

type PacketSendableFromServer<T> = {
	sendTo: (player: Player, data: T) -> (),
	broadcast: (data: T) -> ()
}
type PacketSendableFromClient<T> = {
	sendToServer: (data: T) -> (),
}

--[=[
	페킷 인터페이스 생성을 위한 구조체입니다.
	초기화되지 않은 단일 페킷 인터페이스는 작동하지 않습니다.

	```lua
	Net.Packet {
		from = "server",
		reliable = true,
		struct = {
			exampleParam = Net.u32
		}
	}
	```
]=]
Net.Packet = (function<T>(config: {
	from: "server" | "client",
	reliable: boolean,
	struct: T & { [string]: any }
})
	local packet = {} :: any
	local from = config.from
	local reliable = config.reliable
	local struct = config.struct
	local packetId: number

	if from ~= "server" and from ~= "client" then
		error(`Packet config 'from' expected 'server' or 'client' got {from}`)
	end
	Strict.expect(reliable, "boolean")
	if type(struct) ~= "table" then
		error(Strict.ExpectException(struct, "table"))
	end

	if isServer and from == "server" then
		local writers = {}
		for k, v in struct do
			writers[k] = v[2]
		end

		packet.sendTo = function(player: Player, data: T)
			if type(data) ~= "table" then
				error(Strict.ExpectException(data, "table"))
			end
			loadEmpty()
			u8W(packetId)
			for k, v in data do
				writers[k](v)
			end
			if reliable then --// need benchmark: using upvalue is cheaper or using if is cheaper
				playerMap[player] = save()
			else
				local buff = buffer.create(outgoingBufferUsed)
				buffer.copy(buff, 0, outgoingBuffer, 0, outgoingBufferUsed)
				unreliableRemoteEvent:FireClient(player, buff, outgoingInstances)
			end
		end

		packet.broadcast = function(data: T)
			if type(data) ~= "table" then
				error(Strict.ExpectException(data, "table"))
			end
			loadEmpty()
			u8W(packetId)
			for k, v in data do
				writers[k](v)
			end
			for _, player in Players:GetPlayers() do
				if reliable then --// need benchmark: using upvalue is cheaper or using if is cheaper
					playerMap[player] = save()
				else
					local buff = buffer.create(outgoingBufferUsed)
					buffer.copy(buff, 0, outgoingBuffer, 0, outgoingBufferUsed)
					unreliableRemoteEvent:FireClient(player, buff, outgoingInstances)
				end
			end
		end
	elseif not isServer and from == "client" then
		local writers = {}
		packet.sendToServer = function(data: T)
			if type(data) ~= "table" then
				error(Strict.ExpectException(data, "table"))
			end
			loadEmpty()
			u8W(packetId)
			for k, v in data do
				writers[k](v)
			end
		end
	else
		local readers = {}
		packet.onReceive = Hook() :: Hook.HookedEvent<T>
	end

	packet._init = function(id: number) --// used internally with packet interface
		if packetId then
			error("This packet already has been initialized!")
		end
		packetId = id
	end

	return table.freeze(packet)
end :: any) :: (<T>(config: {
	from: "client",
	reliable: boolean,
	struct: T
}) -> BasePacket<T, PacketSendableFromClient<T>>) & (<T>(packet: {
	from: "server",
	reliable: boolean,
	struct: T
}) -> BasePacket<T, PacketSendableFromServer<T>>)

function Net.RawPacket()

end

function Net.String(legnth)
	local stringR, stringW =
		function(): string
			local length = buffer.readu16(incomingBuffer, read(2))
			return buffer.readstring(incomingBuffer, read(length), length)
		end, function(value: string)
			local length = #value
			outgoingBufferApos = reserve(2)
			buffer.writeu16(outgoingBuffer, outgoingBufferApos, length)
			buffer.writestring(outgoingBuffer, 2, value)
		end
	return (({ stringR, stringW } :: RW) :: any) :: string
end

--[=[
	페킷 인터페이스를 사용할 수 있는 상태로 초기화하고 페킷의 집합 단위을 구성하기 위한 구조체입니다.

	```lua
	Net.PacketProvider {
		ExampleNamespace = Net.Packet {
			from = "client",
			reliable = true,
			struct = {
				exampleParam = Net.u32
			}
		}
	}
	```
]=]
Net.PacketProvider = (function<T>(packetInterfaces: T & { [string]: BasePacket<any, any> })
	if type(packetInterfaces) ~= "table" then
		error(Strict.ExpectException(packetInterfaces, "table"))
	end
	local packets = {}
	for names, packet in packetInterfaces do
		packet._init(#packets)
		table.insert(packets, packet)
	end
end :: any) :: (<T>(packetInterface: T & { [string]: BasePacket<any, PacketSendableFromClient<any>> }) -> ({
	server: { [string]: { sendToServer: nil } } & T, client: { [string]: { sendTo: nil, onReceive: nil } } & T
})) & (<T>(packetInterface: T & { [string]: BasePacket<any, PacketSendableFromServer<any>> }) -> ({
	server: { [string]: { sendToServer: nil, onReceive: nil } } & T, client: { [string]: { sendTo: nil, broadcast: nil } } & T
}))

function Net.RemoteStruct()

end

function Net.randomInt(key: string, min: number, max: number)
	return newSharedRandom(key):NextInteger(min, max)
end

function Net.randomFloat(key: string, min: number, max: number)
	return newSharedRandom(key):NextNumber(min, max)
end

if isServer then
	local callbacks: { [string]: (player: Player, ...any) -> () } = {}
	function Net.connectHandle(address: string, callback: (player: Player) -> ())
		if callbacks[address] then
			error(`Handle '{address}' has already been connected`)
		end
		callbacks[address] = callback
		if not remoteFunction then
			local newRF = Instance.new("RemoteFunction")
			newRF.Name = "RemoteFunction"
			newRF.Parent = script
			newRF.OnServerInvoke = function(player, address, ...)
				local cb = callbacks[address]
				if cb then
					cb(player, ...)
				end
			end
			remoteFunction = newRF
		end
	end

	function Net.disconnectHandle(address: string)
		if callbacks[address] then
			error(`Handle '{address}' was not connected`)
		end
		callbacks[address] = nil
	end
else
	function Net.fetch(address: string, query: {})
		return Promise.new(function(resolve, reject, onCancel)
			remoteFunction = script:WaitForChild("RemoteFunction", 10) :: RemoteFunction
			if not remoteFunction then
				return reject("No response from the server")
			end
			local data = remoteFunction:InvokeServer(query)
			resolve(data)
		end)
	end
end

loadEmpty()
fetchRemoteEvents()

return Strict.Capsule(Net)
