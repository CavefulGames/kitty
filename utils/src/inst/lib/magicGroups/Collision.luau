local types = require(script.Parent.Parent.types)
local sharedImpl = require(script.Parent.Parent.Group.sharedImpl)
local PhysicsService = game:GetService("PhysicsService")
local utils = require(script.Parent.Parent.utils)

type PhysicsController = typeof(setmetatable(
	{} :: {
		collisionGroup: string
	},
	{} :: PhysicsControllerImpl
))

type PhysicsControllerImpl = {
	__index: PhysicsControllerImpl,
	canCollide:
		((self: PhysicsController, other: types.Group<BasePart, PhysicsController>, newCollidableSetting: boolean) -> ())
		& ((self: PhysicsController, other: types.Group<BasePart, PhysicsController>) -> boolean)
}

local PhysicsController = {} :: PhysicsControllerImpl
PhysicsController.__index = PhysicsController

PhysicsController.canCollide = function(self: PhysicsController, other: types.Group<BasePart, PhysicsController>, newCollidableSetting: boolean?): boolean?
	local name1, name2 = self.collisionGroup, other.all.collisionGroup
	if newCollidableSetting ~= nil then
		PhysicsService:CollisionGroupSetCollidable(name1, name2, newCollidableSetting)
		return
	end
	return PhysicsService:CollisionGroupsAreCollidable(name1, name2)
end :: any

local CollisionGroup = {} :: types.Group<BasePart, PhysicsController>
CollisionGroup.__index = CollisionGroup

function CollisionGroup.new(className, name)
	if PhysicsService:IsCollisionGroupRegistered(name) then
		error(`Attempt to create a collision group named '{name}' that already has been registered.`)
	end
	local group = {
		name = name,
		n = 0,
		className = className
	}
	group.all = setmetatable({
		collisionGroup = name
	}, PhysicsController)
	table.freeze(group.all)
	PhysicsService:RegisterCollisionGroup(name)
	return setmetatable(group, CollisionGroup) :: any
end

CollisionGroup.with = sharedImpl.with :: any

function CollisionGroup.add(self, element)
	local index = sharedImpl.add(self :: any, element)
	if element.CollisionGroup then
		error(`Attempt to add an instance('{utils.print(element)}') that already has been assigned/added to another collision group named '{element.CollisionGroup}'`)
	end
	element.CollisionGroup = self.name
	element:GetPropertyChangedSignal("CollisionGroup"):Once(function()
		if element.CollisionGroup ~= self.name and self[index] == element then
			self:remove(index)
		end
	end)
	return index
end

function CollisionGroup.remove(self, index)
	local removedPart = sharedImpl.remove(self :: any, index) :: BasePart?
	if removedPart then
		removedPart.CollisionGroup = nil :: any
	end
	return
end

function CollisionGroup.clear(self)
	for i = self.n, 1, -1 do
		self:remove(i)
	end
	self.n = 0
end

CollisionGroup.iter = sharedImpl.iter :: any

function CollisionGroup.destroy(self)
	self:clear()
	PhysicsService:UnregisterCollisionGroup(self.name)
end

return {
	new = function(name: string): typeof(CollisionGroup)
		return CollisionGroup.new("BasePart", name)
	end,
	getCollisionGroup = function(asCollisionGroup: string | typeof(CollisionGroup)): string
		if type(asCollisionGroup) == "string" then
			return asCollisionGroup
		end
		return asCollisionGroup.all.collisionGroup
	end
}
