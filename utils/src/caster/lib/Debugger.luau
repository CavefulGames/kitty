export type Visualized = {
	type: "ray",
	origin: Vector3,
	direction: Vector3,
	hitPosition: Vector3?,
} | {
	type: "block",
	cframe: CFrame,
	size: Vector3,
	direction: Vector3,
	hitPosition: Vector3?,
} | {
	type: "shape",
	part: BasePart,
	direction: Vector3,
	hitPosition: Vector3?,
} | {
	type: "sphere",
	origin: Vector3,
	radius: number,
	direction: Vector3,
	hitPosition: Vector3?,
}

export type Debugger = typeof(setmetatable(
	{} :: {
		maxDrawCount: number,
		color: Color3,
		hitColor: Color3,
		radius: number,
		index: number,
	},
	{} :: DebuggerImpl
)) & {
	[number]: Visualized,
}

export type AsDebugger = Debugger | {
	maxDrawCount: number?,
	color: Color3?,
	hitColor: Color3?,
	radius: number?,
}

type DebuggerImpl = {
	__index: DebuggerImpl,
	is: (value: any) -> boolean,
	from: (asDebugger: AsDebugger) -> Debugger,
	new: (maxDrawCount: number?, color: Color3?, hitColor: Color3?, radius: number?) -> Debugger,
	add: (self: Debugger, visualized: Visualized) -> (),
}

local Debugger = {} :: DebuggerImpl
Debugger.__index = Debugger

function Debugger.is(value)
	return type(value) == "table" and getmetatable(value) == Debugger
end

function Debugger.from(asDebugger)
	if Debugger.is(asDebugger) then
		return asDebugger :: any
	end
	return Debugger.new(asDebugger.maxDrawCount, asDebugger.color, asDebugger.hitColor, asDebugger.radius)
end

function Debugger.new(maxDrawCount, color, hitColor, radius)
	return setmetatable({
		maxDrawCount = maxDrawCount or 32,
		color = color or Color3.new(0, 0, 1),
		hitColor = hitColor or Color3.new(1, 0, 0),
		radius = radius or 0.5,
		index = 1,
	}, Debugger) :: Debugger
end

function Debugger.add(self, visualized)
	local newIndex = self.index % self.maxDrawCount + 1
	self[newIndex] = visualized
	self.index = newIndex
end

return Debugger
