local All = require(script.All)
local types = require(script.Parent.types)
local magicGroups = require(script.Parent.magicGroups)
local sharedImpl = require(script.sharedImpl)

export type CollisionGroup = typeof(magicGroups.Collision.new(""))
export type SoundGroup = typeof(magicGroups.Sound.new(""))

local Group = {} :: types.Group<any>
Group.__index = Group

function Group.new(className, name)
	local MagicGroup: { new: (name: string) -> types.Group<Instance, Instance> } = magicGroups[className]
	if MagicGroup then
		return MagicGroup.new(name)
	end
	local group = {
		name = name,
		n = 0,
		className = className
	}
	group.all = All.new(group) :: any
	table.freeze(group.all)
	return setmetatable(group, Group) :: any
end

Group.with = sharedImpl.with
Group.add = sharedImpl.add
Group.remove = sharedImpl.remove
Group.clear = sharedImpl.clear
Group.iter = sharedImpl.iter
Group.destroy = sharedImpl.clear

return Group
