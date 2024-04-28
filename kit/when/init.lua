-- TODO: how can i replicate server-sided when using Net

--// depedencies
local Hook = require(script.Parent.hook)
local Flow = require(script.Parent.flow)
local Strict = require(script.Parent.strict)

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
	events.SomeoneSpawns = function()
		local event = Hook()
		When.SomeoneConnects:Bind(function(player:Player)
			player.CharacterAdded:Connect(function(character:Model)
				event:Fire(player)
			end)
		end)
		return event
	end
	events.SomeoneDies = function()
		local event = Hook()
		When.SomeoneSpawns:Bind(function(character:Model)
			local player = Players:GetPlayerFromCharacter(character)
			local humanoid:Humanoid? = character:WaitForChild("Humanoid",5)::any
			if humanoid then
				humanoid.Died:Connect(function()
					event:Fire(player)
				end)
			end
		end)
		return event
	end
else --// shared

end

return Strict.Capsule(When)::{
	SomeoneConnects:Hook.HookedEvent<Player>;
	SomeoneSpawns:Hook.HookedEvent<Player>;
	SomeoneDies:Hook.HookedEvent<Player>;
}
