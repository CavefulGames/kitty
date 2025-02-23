local imgizmo = require(script.Parent.roblox_packages.imgizmo)
local RunService = game:GetService("RunService")
local Debugger = require(script.Debugger)
local gt = require(script.Parent.roblox_packages.greentea)

local doRaycast = workspace.Raycast
local doBlockcast = workspace.Blockcast
local doShapecast = workspace.Shapecast
local doSpherecast = workspace.Spherecast
local includingRaycastParams = RaycastParams.new()
includingRaycastParams.FilterType = Enum.RaycastFilterType.Include

export type Caster = typeof(setmetatable(
	{} :: {
		worldRoot: WorldRoot,
		raycastParams: RaycastParams,
		debugger: Debugger.Debugger?,
	},
	{} :: CasterImpl
))

local BaseRaycastConfigType = gt.build(gt.table({
	ignoreWater = gt.opt(gt.boolean()),
	respectCanCollide = gt.opt(gt.boolean()),
	bruteForceAllSlow = gt.opt(gt.boolean()),
}))

type BasePreviousPenetrationInfo = {
	result: RaycastResult,
	n: number
}

type CasterImpl = {
	__index: CasterImpl,
	new: ((
		collisionGroup: string?,
		config: ({ exclude: { Instance } } & typeof(BaseRaycastConfigType:type()))?,
		worldRoot: WorldRoot?
	) -> Caster)
		& ((
		collisionGroup: string?,
		config: ({ include: { Instance } } & typeof(BaseRaycastConfigType:type()))?,
		worldRoot: WorldRoot?
	) -> Caster),
	ray: (self: Caster, origin: Vector3, direction: Vector3) -> (RaycastResult?),
	line: (self: Caster, position1: Vector3, position2: Vector3) -> (RaycastResult?),
	block: (self: Caster, cframe: CFrame, size: Vector3, direction: Vector3) -> (RaycastResult?),
	sphere: (self: Caster, origin: Vector3, radius: number, direction: Vector3) -> (RaycastResult?),
	shape: (self: Caster, part: BasePart, direction: Vector3) -> (RaycastResult?),
	penetrate: (<T...>(self: Caster, maxPenetrationCount: number, computeThickness: true, penetrateThink: (previous: (BasePreviousPenetrationInfo & {
		thickness: number
	})?, direction: Vector3, T...) -> RaycastResult?, direction: Vector3, T...) -> (BasePreviousPenetrationInfo & {
		thickness: number
	})?)
		& (<T...>(self: Caster, maxPenetrationCount: number, computeThickness: false, penetrateThink: (previous: BasePreviousPenetrationInfo?, direction: Vector3, T...) -> RaycastResult?, direction: Vector3, T...) -> BasePreviousPenetrationInfo?),
	withDebugger: (self: Caster, debugger: Debugger.AsDebugger?, debug: boolean?) -> Caster,
	debug: ((self: Caster) -> boolean) & ((self: Caster, debug: boolean) -> ()),
}

local renderingDebuggers: { Debugger.Debugger } = {}
RunService.PostSimulation:Connect(function()
	for _, debugger in renderingDebuggers do
		for i = 1, #debugger do
			local visualized: Debugger.Visualized = debugger[i]
			if visualized then
				if visualized.type == "ray" then
					local hitPosition = visualized.hitPosition
					if hitPosition then
						imgizmo.PushProperty("Color3", debugger.hitColor)
					else
						imgizmo.PushProperty("Color3", debugger.color)
					end
					local origin = visualized.origin
					local position = hitPosition or origin + visualized.direction

					imgizmo.Arrow:Draw(origin, position, debugger.radius, 1, 4)
				elseif visualized.type == "block" then
					local hitPosition = visualized.hitPosition
					if hitPosition then
						imgizmo.PushProperty("Color3", debugger.hitColor)
					else
						imgizmo.PushProperty("Color3", debugger.color)
					end
					local origin = visualized.cframe.Position
					local direction = visualized.direction
					local position = hitPosition or origin + direction
					local distance = vector.magnitude(position - origin :: any)

					imgizmo.Box:Draw(CFrame.new(origin, origin + direction) + vector.normalize(distance :: any) :: any * distance, visualized.size, false)
				elseif visualized.type == "sphere" then
					local hitPosition = visualized.hitPosition
					if hitPosition then
						imgizmo.PushProperty("Color3", debugger.hitColor)
					else
						imgizmo.PushProperty("Color3", debugger.color)
					end
					local origin = visualized.origin
					local direction = visualized.direction
					local position = hitPosition or origin + direction

					imgizmo.Sphere:Draw(CFrame.new(position), visualized.radius, 30, 360)

					local distance = vector.magnitude(position - origin :: any)

					imgizmo.Line:Draw(CFrame.new(origin + (vector.normalize(direction :: any) :: any * distance / 2), position), distance)
				end
			end
		end
	end
end)

local Caster = {} :: CasterImpl
Caster.__index = Caster

local function penetrateWithExcludingCaster<T...>(
	self: Caster,
	maxPenetrationCount: number,
	computeThickness: boolean,
	penetrateThink: (previous: (BasePreviousPenetrationInfo & { thickness: number? })?, direction: Vector3, T...) -> RaycastResult?,
	direction: Vector3,
	...: T...
): (BasePreviousPenetrationInfo & { thickness: number? })?
	local result = penetrateThink(nil, direction, ...)
	if not result then
		return nil
	end
	local previous: BasePreviousPenetrationInfo & { thickness: number? } = {
		result = result,
		n = 1
	}
	local exclude = self.raycastParams.FilterDescendantsInstances
	if computeThickness then
		while true do
			if previous.n >= maxPenetrationCount then
				return previous
			end
			local oldResult = result
			local oldHit = result.Instance
			table.insert(exclude, oldHit)
			result = penetrateThink(previous, direction, ...)
			if result :: RaycastResult? ~= nil then
				local thicknessDistance = (oldResult.Position - result.Position).Magnitude
				includingRaycastParams.FilterDescendantsInstances[1] = oldResult.Instance
				local thicknessMeasuringResult = doRaycast(self.worldRoot, result.Position, direction * -thicknessDistance, includingRaycastParams)
				if thicknessMeasuringResult then
					local thickness = (thicknessMeasuringResult.Position - oldResult.Position).Magnitude
					previous.thickness = thickness
					previous.result = oldResult
					previous.n += 1
					if exclude[#exclude] == oldHit then
						table.remove(exclude)
					else
						table.remove(exclude, table.find(exclude, oldHit))
					end
				else
					return previous
				end
			else
				return previous
			end
		end
	else
		while true do
			if previous.n >= maxPenetrationCount then
				return previous
			end
			local oldHit = result.Instance
			table.insert(exclude, oldHit)
			result = penetrateThink(previous, direction, ...)
			if result :: RaycastResult? ~= nil then
				previous.result = result
				previous.n += 1
				if exclude[#exclude] == oldHit then
					table.remove(exclude)
				else
					table.remove(exclude, table.find(exclude, oldHit))
				end
			else
				return previous
			end
		end
	end
end

local function penetrateWithIncludingCaster<T...>(
	self: Caster,
	maxPenetrationCount: number,
	computeThickness: boolean,
	penetrateThink: (previous: (BasePreviousPenetrationInfo & { thickness: number? })?, direction: Vector3, T...) -> RaycastResult?,
	direction: Vector3,
	...: T...
): (BasePreviousPenetrationInfo & { thickness: number? })?
	local result = penetrateThink(nil, direction, ...)
	if not result then
		return nil
	end
	local previous: BasePreviousPenetrationInfo & { thickness: number? } = {
		result = result,
		n = 1
	}
	local include = self.raycastParams.FilterDescendantsInstances
	if computeThickness then
		while true do
			if previous.n >= maxPenetrationCount then
				return previous
			end
			local oldResult = result
			local oldHit = result.Instance
			table.remove(include, table.find(include, oldHit))
			result = penetrateThink(previous, direction, ...)
			if result :: RaycastResult? then
				local thicknessDistance = (oldResult.Position - result.Position).Magnitude
				includingRaycastParams.FilterDescendantsInstances[1] = oldResult.Instance
				local thicknessMeasuringResult = doRaycast(self.worldRoot, result.Position, direction * -thicknessDistance, includingRaycastParams)
				if thicknessMeasuringResult then
					local thickness = (thicknessMeasuringResult.Position - oldResult.Position).Magnitude
					previous.thickness = thickness
					previous.result = oldResult
					previous.n += 1
					table.insert(include, oldHit)
				else
					return previous
				end
			else
				return previous
			end
		end
	else
		while true do
			if previous.n >= maxPenetrationCount then
				return previous
			end
			local oldHit = result.Instance
			table.remove(include, table.find(include, oldHit))
			result = penetrateThink(previous, direction, ...)
			if result :: RaycastResult? then
				previous.result = result
				previous.n += 1
				table.insert(include, oldHit)
			else
				return previous
			end
		end
	end
end

local optionalStringType = gt.build(gt.opt(gt.string()))
local configType = gt.build(gt.opt(gt.intersection(
	gt.table({
		exclude = gt.opt(gt.array(gt.Instance())),
		include = gt.opt(gt.array(gt.Instance())),
	}),
	BaseRaycastConfigType:type()
)))
local optionalWorldRootType = gt.build(gt.opt(gt.IsA("WorldRoot") :: WorldRoot))
Caster.new = function(
	collisionGroup: typeof(optionalStringType:type()),
	config: typeof(configType:type()),
	worldRoot: typeof(optionalWorldRootType:type())
): Caster
	optionalStringType:assert(collisionGroup)
	configType:assert(config)
	optionalWorldRootType:assert(worldRoot)

	-- selene: allow(shadowing)
	local config = config or {} :: { exclude: { Instance }?, include: { Instance }? } & typeof(BaseRaycastConfigType:type())
	local raycastParams = RaycastParams.new()
	if config.bruteForceAllSlow then
		raycastParams.BruteForceAllSlow = config.bruteForceAllSlow
	end
	if collisionGroup then
		raycastParams.CollisionGroup = collisionGroup
	end
	if config.exclude and config.include then
		error("Casters cannot have both excluding and including filter at the same time")
	end
	if config.exclude then
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = config.exclude
	elseif config.include then
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = config.include
	end
	if config.ignoreWater then
		raycastParams.IgnoreWater = config.ignoreWater
	end
	if config.respectCanCollide then
		raycastParams.RespectCanCollide = config.respectCanCollide
	end

	return setmetatable({
		worldRoot = worldRoot or workspace :: WorldRoot,
		raycastParams = raycastParams,
		show = _G.__DEV__ or false,
		penetrate = if config.exclude then
			penetrateWithExcludingCaster
		else
			penetrateWithIncludingCaster,
	}, Caster)
end :: any

function Caster.ray(self, origin, direction)
	local result = doRaycast(
		self.worldRoot,
		origin,
		direction,
		self.raycastParams
	)
	local debugger = self.debugger
	if debugger then
		debugger:add({
			type = "ray",
			origin = origin,
			direction = direction,
			hitPosition = result and result.Position or nil,
		})
	end
	return result
end

function Caster.line(self, position1, position2)
	local direction = position1 - position2
	local result = doRaycast(
		self.worldRoot,
		position1,
		direction,
		self.raycastParams
	)
	local debugger = self.debugger
	if debugger then
		debugger:add({
			type = "ray",
			origin = position1,
			direction = direction,
			hitPosition = result and result.Position or nil,
		})
	end
	return result
end

function Caster.block(self, cframe, size, direction)
	local result = doBlockcast(self.worldRoot, cframe, size, direction, self.raycastParams)
	local debugger = self.debugger
	if debugger then
		debugger:add({
			type = "block",
			cframe = cframe,
			size = size,
			direction = direction,
			hitPosition = result and result.Position or nil,
		})
	end
	return result
end

function Caster.sphere(self, origin, radius, direction)
	local result = doSpherecast(self.worldRoot, origin, radius, direction, self.raycastParams)
	local debugger = self.debugger
	if debugger then
		debugger:add({
			type = "sphere",
			origin = origin,
			radius = radius,
			direction = direction,
			hitPosition = result and result.Position or nil,
		})
	end
	return result
end

function Caster.shape(self, part, direction)
	local result = doShapecast(self.worldRoot, part, direction, self.raycastParams)
	-- local debugger = self.debugger
	-- if debugger then
	-- 	debugger:add({
	-- 		type = "shape",
	-- 		part = part,
	-- 		direction = direction,
	-- 		hitPosition = result and result.Position or nil,
	-- 	})
	-- end
	return result
end

function Caster.withDebugger(self, debugger, debug)
	if debugger then
		self.debugger = Debugger.from(debugger)
	else
		self.debugger = Debugger.new()
	end
	if _G.__DEV__ or debug then
		self:debug(true)
	end
	return self
end

Caster.debug = function(self: Caster, debug: boolean?): boolean?
	if not self.debugger then
		error("Debugger is not initialized. Use 'withDebugger' method to initialize it.")
	end
	if debug == nil then
		local index = table.find(renderingDebuggers, self.debugger)
		return index ~= nil
	end
	if debug == true then
		renderingDebuggers[#renderingDebuggers + 1] = self.debugger
	else
		local index = table.find(renderingDebuggers, self.debugger)
		if not index then
			return
		end
		table.remove(renderingDebuggers, index)
	end
	return
end :: any

return Caster
