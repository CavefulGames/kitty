local core = script.Parent.Parent
local MsgPack = require(core.libs.msgpack)
local MMH3 = require(core.libs.mmh3)
local HttpService = game:GetService"HttpService"

--// pre-index
local decodeJSON = HttpService.JSONDecode -- Roblox
local encodeJSON = HttpService.JSONEncode -- Roblox
local generateGUID = HttpService.GenerateGUID -- Roblox
local hashMMH3 = MMH3.hash32 -- Net

local module = {}

module.decodeMessagePack = MsgPack.unpack
module.encodeMessagePack = MsgPack.pack
module.hashMurmur = hashMMH3

function module.decodeJSON(jsonSource:string)
	return decodeJSON(HttpService,jsonSource)
end

function module.encodeJSON(data:{})
	return encodeJSON(HttpService,data)
end

function module.randomInt(min:number,max:number)
	return Random.new():NextInteger(min,max)
end

function module.randomFloat(min:number,max:number)
	return Random.new():NextNumber(min,max)
end

function module.trueRandomIntAsync()

end

function module.trueRandomFloatAsync()

end

function module.generateGUID()
	return generateGUID(HttpService,false)
end

return module
