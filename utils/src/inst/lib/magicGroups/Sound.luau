local types = require(script.Parent.Parent.types)
local sharedImpl = require(script.Parent.Parent.Group.sharedImpl)
local inext = require(script.Parent.Parent.inext)

type SoundController = typeof(setmetatable(
	{} :: {
		soundGroup: SoundGroup,
		volume: number,
		_group: types.Group<Sound>
	},
	{} :: SoundControllerImpl
))

type SoundControllerImpl = {
	__index: SoundControllerImpl,
	setVolume: (self: SoundController, newVolume: number) -> ()
}

local SoundController = {} :: SoundControllerImpl

function SoundController.setVolume(self, newVolume)
	self.volume = newVolume
	for _, element in inext, self._group, 0 do
		element.Volume = newVolume
	end
end

local SoundGroup = {} :: types.Group<Sound, SoundController>
SoundGroup.__index = SoundGroup

function SoundGroup.new(className, name)
	local group = {
		name = name,
		n = 0,
		className = className
	}
	local soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = name
	soundGroup.Volume = 1
	group.all = {
		soundGroup = soundGroup,
		_props = {
			n = 0
		}
	}
	return setmetatable(group, SoundGroup) :: any
end

SoundGroup.with = sharedImpl.with :: any

function SoundGroup.add(self, element)
	local index = sharedImpl.add(self :: any, element)
	element.SoundGroup = self.all.soundGroup
	element:GetPropertyChangedSignal("SoundGroup"):Once(function()
		if element.SoundGroup ~= self.all.soundGroup and self[index] == element then
			self:remove(index)
		end
	end)
	return index
end

function SoundGroup.remove(self, index)
	local removedSound = sharedImpl.remove(self :: any, index) :: Sound?
	if removedSound then
		removedSound.SoundGroup = nil :: any
	end
	return
end

function SoundGroup.clear(self)
	for i = self.n, 1, -1 do
		self:remove(i)
	end
	self.n = 0
end

SoundGroup.iter = sharedImpl.iter :: any

function SoundGroup.destroy(self)
	self:clear()
	self.all.soundGroup:Destroy()
end

return {
	new = function(name: string): typeof(SoundGroup)
		return SoundGroup.new("Sound", name)
	end
}
