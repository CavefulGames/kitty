--!strict
local Result = require(script.Parent.Parent.result)
local HandyNet = require(script.Parent.Parent.pesdeModule.handynet)

type Result<T, E> = Result.Result<T, E>

type ConfigImpl<T> = {
    __index: ConfigImpl<T>,
    __call: (self: Config<T>) -> T,
    save: (self: Config<T>) -> (Result<Config<T>, string>)
}

type Gear = {
    defineField: <T>(dataType: T, default: T) -> T,
    defineConfiguration: <T>(name: string, fields: T) -> Config<T>
}

type Config<T> = typeof(setmetatable({} :: {
    
}, {} :: ConfigImpl<T>))

local config = {} :: ConfigImpl<any>
config.__index = config

local gear = {} :: Gear

function gear.defineConfiguration(name, fields)
    return setmetatable({

    }, config)
end

gear.defineConfiguration('w', { apple = ''})