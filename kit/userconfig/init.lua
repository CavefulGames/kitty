--// kit
local Strict = require(script.Parent.strict)

type ConfigImpl<T={[string]:any}> = {
	__index:ConfigImpl<T>;
	SaveChanges:(self:ConfigImpl<T>)->();
	GetChanges:(self:ConfigImpl<T>)->();
	DiscardChanges:(self:ConfigImpl<T>)->();
	Reset:(self:ConfigImpl<T>)->();
	RawSet:(self:ConfigImpl<T>)->();
	RawGet:(self:ConfigImpl<T>)->();
}
type Config<T> = typeof(setmetatable({}::{},{}::ConfigImpl<T>))

local Config = {}::ConfigImpl

function Config:SaveChanges()

end

function Config:GetChanges()

end

function Config:DiscardChanges()

end

function Config:Reset()

end

function Config:RawSet()

end

function Config:RawGet()

end

function Config:__index(k)

end

function Config:__newindex(k,v)

end

return setmetatable({},Config)::Config<typeof(require(script.Parent))>
