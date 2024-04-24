--// depedencies
local Hook = require(script.Parent.hook)
local Flow = require(script.Parent.flow)

--// services
local RunService = game:GetService("RunService")

local events = {}
local When = setmetatable({}, {
	__index = function(self,k)
		local event = events[k]
		if event then
			if type(event) == "function" then
				event = event()
				events[k] = event
			end
			return event
		else
			error(`'When {k}' is not valid`)
		end
	end
})

if RunService:IsServer() then --// server
	local Players = game:GetService("Players")
	events.SomeoneConnects = function()
		return Hook(Players.PlayerAdded)
	end
	events.SomeoneSpawn = function()
		local event = Hook()
		When.SomeoneConnects:Bind(function(player:Player)
			player.CharacterAdded:Connect(function(character:Model)
				event:Trigger(character)
			end)
		end)
		Context.
		return event
	end
	events.SomeoneDies = function()
		local event = Hook()
		When.SomeoneSpawn:Bind(function(character:Model)
			player.CharacterAdded:
		end)
		return event
	end
else --// shared

end

return
