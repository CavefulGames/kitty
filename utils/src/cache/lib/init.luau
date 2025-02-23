--!native

local types = require(script.types)
local gt = require(script.Parent.roblox_packages.greentea)
local managers = require(script.managers)

local FAR_AWAY_CFRAME = CFrame.new(2^24, 2^24, 2^24)
local BULK_MOVE_MODE = Enum.BulkMoveMode.FireCFrameChanged

local defaultHolder: Instance = workspace
local defaultPrefix = "Cached"
local movingParts = table.create(10_000)
local movingCFrames = table.create(10_000)
local cloneInstance = game.Clone
local bulkMoveTo = workspace.BulkMoveTo

local scheduledUpdate = false
local function updateMovement()
	while true do
		bulkMoveTo(workspace, movingParts, movingCFrames, BULK_MOVE_MODE)

		table.clear(movingParts)
		table.clear(movingCFrames)

		scheduledUpdate = false
		coroutine.yield()
	end
end
local updateMovementThread = coroutine.create(updateMovement)

local function delete<T>(self: types.InstanceCache<T> | types.PartCache<T> | types.ModelCache<T>)
	self.holder:Destroy()
	setmetatable(self, nil) -- TODO: Replace nil with a metatable that throws an error when trying to access any field
end

local InstanceCache = {} :: types.InstanceCacheImpl
InstanceCache.__index = InstanceCache
InstanceCache.delete = delete

function InstanceCache.spawn<T>(self: types.InstanceCache<T>): T
	local object = self.manager.get(self)
	self.spawned[object] = true
	return object
end

function InstanceCache.despawn(self, object, resetParent)
	if not self.spawned[object] then
		return
	end

	local free = self.manager.free
	if free then
		free(self, object)
	end

	if resetParent then
		local holder = self.holder
		if object.Parent ~= holder then
			object.Parent = holder
		end
	end
	self.spawned[object] = nil
end

function InstanceCache.expand(self, amount)
	local initialLength = #self
	local holder = self.holder
	local template = self.template
	local size = self.size
	for i = initialLength + 1, initialLength + amount do
		size += 1
		local object = cloneInstance(template) :: typeof(template)
		object.Parent = holder
		self[i] = object
	end
	self.size = size
end

local PartCache = {} :: types.PartCacheImpl
PartCache.__index = PartCache
PartCache.delete = delete

function PartCache.spawn<T>(self: types.PartCache<T>, partCFrame: CFrame?): T
	local object = self.manager.get(self)
	if partCFrame then
		table.insert(movingParts, object)
		table.insert(movingCFrames, partCFrame)
		if not scheduledUpdate then
			scheduledUpdate = true
			task.defer(updateMovementThread)
		end
	end
	self.spawned[object] = true
	return object
end

function PartCache.despawn(self, object, resetParent)
	if not self.spawned[object] then
		return
	end

	local free = self.manager.free
	if free then
		free(self, object)
	end

	table.insert(movingParts, object)
	table.insert(movingCFrames, FAR_AWAY_CFRAME)
	if not scheduledUpdate then
		scheduledUpdate = true
		task.defer(updateMovementThread)
	end

	if resetParent then
		local holder = self.holder
		if object.Parent ~= holder then
			object.Parent = holder
		end
	end

	self.spawned[object] = nil
end

function PartCache.expand(self, amount)
	local initialLength = #self
	local holder = self.holder
	local template = self.template
	local newSize = self.size

	local targetParts: { BasePart } = table.create(amount)
	local targetCFrames: { CFrame } = table.create(amount)
	for i = initialLength + 1, initialLength + amount do
		newSize += 1
		local object = cloneInstance(template) :: typeof(template)
		self[i] = object

		local offset = i - initialLength
		targetParts[offset] = object
		targetCFrames[offset] = FAR_AWAY_CFRAME
	end

	bulkMoveTo(workspace, targetParts, targetCFrames, Enum.BulkMoveMode.FireCFrameChanged)

	for _, object in targetParts do
		object.Parent = holder
	end

	self.size = newSize
end

local ModelCache = {} :: types.ModelCacheImpl
ModelCache.__index = ModelCache
ModelCache.delete = delete

function ModelCache.spawn<T>(self: types.ModelCache<T>, partCFrame: CFrame): Model
	local object = self.manager.get(self)
	if partCFrame then
		if self.primaryPartExists then
			table.insert(movingParts, object.PrimaryPart :: BasePart)
			table.insert(movingCFrames, partCFrame)

			if not scheduledUpdate then
				scheduledUpdate = true
				task.defer(updateMovementThread)
			end
		else
			object:PivotTo(partCFrame)
		end
	end
	self.spawned[object] = true
	return object
end

function ModelCache.despawn(self, object, resetParent)
	if not self.spawned[object] then
		return
	end

	local free = self.manager.free
	if free then
		free(self, object)
	end

	if self.primaryPartExists then
		table.insert(movingParts, object.PrimaryPart :: BasePart)
		table.insert(movingCFrames, FAR_AWAY_CFRAME)
		if not scheduledUpdate then
			scheduledUpdate = true
			task.defer(updateMovementThread)
		end
	else
		object:PivotTo(FAR_AWAY_CFRAME)
	end

	if resetParent then
		local holder = self.holder
		if object.Parent ~= holder then
			object.Parent = holder
		end
	end

	self.spawned[object] = nil
end

function ModelCache.expand(self, amount)
	local initialLength = #self
	local holder = self.holder
	local template = self.template
	local newSize = self.size

	if self.primaryPartExists then
		local targetParts: { BasePart } = table.create(amount)
		local targetCFrames: { CFrame } = table.create(amount)
		local addedObjects: { Model } = table.create(amount)
		for i = initialLength + 1, initialLength + amount do
			newSize += 1
			local object = cloneInstance(template) :: typeof(template)
			self[i] = object

			local offset = i - initialLength
			targetParts[offset] = object.PrimaryPart :: BasePart
			targetCFrames[offset] = FAR_AWAY_CFRAME
			addedObjects[offset] = object
		end

		bulkMoveTo(workspace, targetParts, targetCFrames, BULK_MOVE_MODE)

		for _, object in addedObjects do
			object.Parent = holder
		end
	else
		for i = initialLength + 1, initialLength + amount do
			newSize += 1
			local object = cloneInstance(template) :: typeof(template)
			object:PivotTo(FAR_AWAY_CFRAME)
			object.Parent = holder
			self[i] = object
		end
	end

	self.size = newSize
end

local cache = {}
cache.managers = managers

function cache.update()
	task.spawn(updateMovementThread)
end

local InstanceType = gt.build(gt.Instance())
local numberType = gt.build(gt.number())
local optionalStringType = gt.build(gt.opt(gt.string()))
local optionalInstanceType = gt.build(gt.opt(gt.Instance()))
cache.create = (function<T, M>(
	template: typeof(InstanceType:type()),
	size: typeof(numberType:type()),
	cacheManager: types.BaseCacheManager<T, M>,
	cacheManagerConfig: M?,
	debugName: typeof(optionalStringType:type()),
	parent: typeof(optionalInstanceType:type())
): types.InstanceCache<T> | types.PartCache<T> | types.ModelCache<T>
	InstanceType:assert(template)
	numberType:assert(size)
	optionalStringType:assert(debugName)
	optionalInstanceType:assert(parent)

	local holder = Instance.new("Folder")
	holder.Name = if debugName then `{defaultPrefix}_{debugName}` else defaultPrefix
	local this = table.create(size) :: types.BaseCache<any>
	this.holder = holder
	this.template = template
	this.spawned = {}
	this.size = size
	this.manager = cacheManager

	if template:IsA("BasePart") then
		for i = 1, size do
			local object = cloneInstance(template) :: typeof(template)
			this[i] = object
			object.CFrame = FAR_AWAY_CFRAME
			object.Parent = holder
		end
		holder.Parent = parent or defaultHolder

		local partCache = setmetatable(this, PartCache)
		local init = cacheManager.init
		if init then
			init(partCache :: any, cacheManagerConfig)
		end
		return partCache
	elseif template:IsA("Model") then
		this.primaryPartExists = if template.PrimaryPart then true else nil
		for i = 1, size do
			local object = cloneInstance(template) :: typeof(template)
			this[i] = object
			object:PivotTo(FAR_AWAY_CFRAME)
			object.Parent = holder
		end
		holder.Parent = parent or defaultHolder

		local modelCache = setmetatable(this, ModelCache)
		local init = cacheManager.init
		if init then
			init(modelCache :: any, cacheManagerConfig)
		end
		return modelCache
	end

	for i = 1, size do
		local object = cloneInstance(template)
		this[i] = object
		object.Parent = holder
	end
	holder.Parent = parent or defaultHolder

	local instanceCache = setmetatable(this, InstanceCache)
	local init = cacheManager.init
	if init then
		init(instanceCache :: any, cacheManagerConfig)
	end
	return instanceCache
end :: any) :: types.CreateCacheFn

function cache.setDefault(holder: Instance?, prefix: string?)
	if holder then
		defaultHolder = holder
	end
	if prefix then
		defaultPrefix = prefix
	end
end

return cache
