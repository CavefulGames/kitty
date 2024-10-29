--!strict
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

type Gear = {
    defineField: <T>(dataType: T, default: T) -> T,
    defineConfiguration: <T>(name: string, fields: T & { [string]: any }) -> { load: (player: Player?) -> (Config<T>) },
    startServer: () -> (),
}

type Config<T> = typeof(setmetatable({} :: {
    config: T,
    player: Player,
    name: string,
    datastore: typeof(DataStoreLight.new(0 :: any))?,
}, {} :: ConfigImpl<T>))

local savePacket = HandyNet.defineNamespace('userconfig-save',function() 
    return { 
        onSave = HandyNet.definePacket(
            "client->server",
            HandyNet.struct { name = HandyNet.unknown, config = HandyNet.nothing }
        )
    }
end)

-- local getOnServer = HandyNet.defineNamespace('userconfig-getOnServer',function() 
--   return { 
--       get = HandyNet.definePacket(
--           "client->server",
--           HandyNet.struct {}
--       )
--   }
-- end)

-- local getOnClient = HandyNet.defineNamespace('userconfig-getOnClient',function() 
--   return { 
--       get = HandyNet.definePacket(
--           "server->client",
--           HandyNet.struct {}
--       )
--   }
-- end)

local config = {} :: ConfigImpl<any>
config.__index = config

function config.__call(self)
    return self.config
end

function config.save(self)
    if RunService:IsClient() then
        -- if not onServer then
        --     getOnServer.get.send({})
        -- end
        if not onServer then
            error('Please require it from the server.')
        end
        
        savePacket.onSave.send { 
            name = self.name, 
            config = self() 
        }
    else
        print(self.name);
        local ds = self.datastore :: typeof(DataStoreLight.new(0 :: any))
        ds:set(self.name, self());
        ds:save()
    end

    return self()
end

local gear = {} :: Gear

function gear.defineConfiguration(name, fields)
    return { 
        load = function(player)
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
                -- getOnClient.get.event:connect(function(data)
                --     onServer = true
                -- end)
                -- if not onServer then
                --     getOnServer.get.send({})
                -- end
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

        -- getOnServer.get.event:connect(function(_, player)
        --     getOnClient.get.send({}, player)
        -- end)

        savePacket.onSave.event:connect(function(data, player)
              local saveDataStore =  DataStoreLight.new(player.UserId)
              print(data.name)
              saveDataStore:set(data.name :: string, data.config)
              saveDataStore:save()
        end)
    end
end

-- gear.defineConfiguration('w', { apple='' }):load((0 :: any) :: Player)

return gear