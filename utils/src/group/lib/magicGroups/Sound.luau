local types = require(script.Parent.Parent.types)
local All = require(script.Parent.Parent.All)
local emitter = require(script.Parent.Parent.emitter)
local destroyer = require(script.Parent.Parent.destroyer)
local limesignal = require(script.Parent.Parent.Parent.limesignal)

local SoundGroup = {} :: types.SoundGroupImpl
SoundGroup.__index = SoundGroup

-- local function pushEvent(element: Sound)
-- 	local oldSoundGroup = element.SoundGroup
-- 	if oldSoundGroup then
-- 		if oldSoundGroup == self._soundGroupInstance then
-- 			-- todo: gonna be prettier with `inst.pretty`
-- 			error(`A sound({element}) being inserted to ({self}) is already set.`)
-- 		else
-- 			error(`A sound({element}) being inserted to ({self}) already has a SoundGroup named '{oldSoundGroup.Name}'.`)
-- 		end
-- 	end

-- end

function SoundGroup.new(name)
	local soundGroupInstance = Instance.new("SoundGroup")
	soundGroupInstance.Name = name
	local elements = {}
	local pushEvent = limesignal.ImmutableEvent.from(emitter, destroyer)
	pushEvent:connect(function(element: Sound)
		element.SoundGroup = soundGroupInstance
	end)

	return setmetatable({
		_elements = elements,
		_soundGroupInstance = soundGroupInstance,
		all = All.new(elements) :: any,
		name = name,
		pushEvent = pushEvent
	}, SoundGroup)
end

return nil
