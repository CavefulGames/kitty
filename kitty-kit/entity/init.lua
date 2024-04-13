local core = script.Parent.Parent

local constants = require(core.common.constants)
local masterkey = require(core.libs.masterkey)

local module = {}

--// dependencies
local Console
local Net
function module.init(deps)
	Console = deps.Console
	Net = deps.Net
end

function module:NetworkVar(valueType,value,variableName)
	-- local setFuncName = "Set"..variableName
	-- if self[setFuncName] then
	-- 	Console.fatalf("(while setting %s) Network var name must be unique",tostring(self.referent.Name))
	-- 	return
	-- end
	-- local netWriteFunc = Net["write"..valueType]
	-- if not netWriteFunc then
	-- 	Console.fatalf("(while setting %s) Invalid value type",tostring(self.referent.Name))
	-- 	return
	-- end
	-- local uniqueName = "KolloidNetworkVar_"..variableName

	-- self[setFuncName] = function(self,newValue)
	-- 	rawset(self,uniqueName,value)
	-- 	Net.start(constants.coreNetworkString)
	-- 	Net.writeReferent(self.referent)
	-- 	netWriteFunc(newValue)
	-- 	Net.writeString(variableName)
	-- 	Net.broadcast()
	-- end
	-- local getFuncName = "Get"..variableName
	-- self[getFuncName] = function(self,newValue)
	-- 	return rawget(self,privateName)
	-- end
	-- Net.onReceive(constants.coreNetworkString,function()

	-- end)
end

function module:ToInstance():Instance
	return self[masterkey]
end

function module:__index(k)

end

function module:__newindex(k,v)

end

function module.new(instance:Instance)
	local this = {
		[masterkey] = instance
	}
	setmetatable(this,module)
	return this
end

return module
