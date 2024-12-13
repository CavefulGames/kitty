--!strict
--TODO: DataType 만들기
local RunService = game:GetService('RunService')

local Result = require(script.Parent.Parent.result)
local HandyNet = require(script.Parent.Parent:WaitForChild('pesdeModule'):WaitForChild('handynet'))
local DataStoreLight = require(script.Parent.Parent:WaitForChild('datastore-light'))

local onServer = false

type Result<T, E> = Result.Result<T, E>

type ConfigImpl<T> = {
    __index: ConfigImpl<T>,
    __call: (self: Config<T>) -> T & { [string]: any },
    save: (self: Config<T>) -> (Result<Config<T>, string>),
}

type gearDefineField<T> = T & { __brand: 'gearField' }

type dataTypes = 
    | "boolean"
    | "string"
    | "char"
    | "array"
    | "u8"
    | "u16"
    | "u32"
    | "i8"
    | "i16"
    | "i32"
    | "f32"
    | "f64" 

type Gear = {
    defineField: <T>(data: T, dataType: dataTypes?) -> gearDefineField<T>,
    defineConfiguration: <T>(name: string, fields: T & { [string]: gearDefineField<T> }) -> { load: (player: Player?) -> (Config<T>) },
    startServer: () -> (),
}

type Config<T> = typeof(setmetatable({} :: {
    config: T & { [string]: gearDefineField<T> },
    player: Player,
    name: string,
    datastore: typeof(DataStoreLight.new(0 :: any))?,
}, {} :: ConfigImpl<T>))

local savePacket = HandyNet.defineNamespace('userconfig-save',function() 
    return { 
        onSave = HandyNet.definePacket(
            "client->server",
            HandyNet.struct { name = HandyNet.unknown, config = HandyNet.unknown }
        )
    }
end)

local config = {} :: ConfigImpl<any>
config.__index = config

function config.__call(self)
    return self.config
end

function config.save(self)
    if RunService:IsClient() then
        savePacket.onSave.send { 
            name = self.name, 
            config = self() 
        }
    else
        local ds = self.datastore :: typeof(DataStoreLight.new(0 :: any))
        ds:set(self.name, self());
        ds:save()
    end

    return self()
end

local gear = {} :: Gear

function gear.defineField(data, dataType)
    if dataType == nil then
        
    end
    return dataType :: any & { __brand: "gearField" }
end

function gear.defineConfiguration(name, fields)
    return { 
        load = function(player: Player?)
            if not player then
                player = game:GetService('Players').LocalPlayer
            end
            if RunService:IsServer() then
                local datastore = DataStoreLight.new((player :: Player).UserId)
                local data = datastore:get(name)
                if not data then
                    datastore:set(name, fields)
                    data = fields  
                end
                return setmetatable({
                  datastore=datastore,
                  player=player :: Player,
                  name=name,
                  config=data,
                }, config)
            else
                return setmetatable({
                  player=player :: Player,
                  name=name,
                  config=fields,
                }, config)
            end
        end 
    }
end

function gear.startServer()
    if RunService:IsClient() then
        error('start server is only server')
    else
        if onServer then
            return
        end 

        savePacket.onSave.event:connect(function(data, player)
              local saveDataStore =  DataStoreLight.new(player.UserId)
              saveDataStore:set(data.name :: string, data.config)
              saveDataStore:save()
        end)
    end
end

local t = gear.defineField('char', 'char')

-- gear.defineConfiguration('test', { a = t }).load().config.a

return gear