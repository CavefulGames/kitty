local core = script.Parent.Parent
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local masterkey = require(core.libs.masterkey)
local transition = 1
local slots = {}
local modes = {}
local currentMode = "Legacy"

local module = {}

--// dependencies
local Hook
function module:KolloidInit(deps)
	Hook = deps.Hook
end

type Mode = {
	Name:string;
	OnUpdateFunction:()->();
}
local Mode = {}
Mode.__index = Mode

function Mode:Activate(callback:()->())
	self.hook = Hook.add("AfterRender"):Connect(function()
		callback()
	end)
end

function Mode:Deactivate()
	self.hook:Disconnect()
	self.hook = nil
end

function Mode.new(modeName:string)
	local this = {
		Name = modeName;
	}
	setmetatable(this,Mode)
	return this
end

function module.newMode(modeName:string):Mode
	local mode = Mode.new(modeName)
	modes[modeName] = mode
	return mode
end

do
	local mode = module.newMode("FirstPerson")
	local angleX = 0
	local angleY = 0
	mode.OnUpdateFunction = function()
		local mouseDelta = UserInputService:GetMouseDelta()
		angleX -= mouseDelta.X*sensitivity*delta
		angleY = math.clamp(angleY - mouseDelta.Y*sensitivity*delta, -80, 80)
		local hrp = script.Parent:FindFirstChild("HumanoidRootPart")
		if hrp then
			local StartPosition = hrp.CFrame * Vector3.new(0, 1.85, 0)
			local StartOrientation = CFrame.Angles(0, math.rad(angleX), 0) * CFrame.Angles(math.rad(angleY), 0, 0) + StartPosition

			local CameraFocus = StartOrientation + StartOrientation:VectorToWorldSpace(Vector3.new(0, 0, -5))

			hrp.CFrame = CFrame.Angles(0, math.rad(angleX), 0) + hrp.Position

			Camera.CFrame = CFrame.Angles(0, math.rad(angleX), 0) * CFrame.Angles(math.rad(angleY), 0, 0) + StartPosition
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		Camera.CameraType = Enum.CameraType.Scriptable
	end
end

function module.setMode(modeName:string)

end

function module.setTransition(newTransition:number)
	transition = newTransition
end

function module.offset(slot:string)

end

function module.newOffset()

end

function module.addOffset(slot:string,initialOffset:CFrame,callback:()->())

end

function module.coordinate(slot:string)

end

function module.newCoordinator()

end

function module.addCoordinator()

end

-- View.addOffset("Recoil",CFrame.new(),function(offset:CFrame)
-- 	return offset:Lerp(CFrame.Angles(math.rad(-punchAngle.x),math.rad(-punchAngle.y),math.rad(punchAngle.z)),0.9)
-- end)

-- local offset = View.newOffset()
-- offset(offset():Lerp())

-- View.offset("Recoil",View.offset("Recoil"):Lerp())
