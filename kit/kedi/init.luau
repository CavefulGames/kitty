--// kit
local Strict = require(script.Parent.strict)
local Kedi = {}

--// dependencies
local ReactLua = require(script.Parent.reactlua)
local ReactRoblox = require(script.Parent["react-roblox"])

local Event = ReactLua.Event

function Kedi.Element<T>(class:T):(props:T?)->() --- only works with '--!nocheck' enabled :(
	return function(props:T?)
		if props == nil then
			return ReactLua.createElement(class::any)
		end
		if type(props) ~= "table" then
			error(Strict.ExpectException(props,"table"))
		end
		local children = {}
		for k,v in props do
			if type(k) == "string" and type(v) == "function" then
				props[Event[k]] = v
				props[k] = nil
			elseif type(v) == "number" then
				table.insert(children,v)
				props[k] = nil
			end
		end
		return ReactLua.createElement(class,props,children)
	end
end

--// type casters
function Kedi.Component<T,a,b>(functionalComponent:(props:T)->(ReactLua.ReactElement<a,b>)):T
	return (functionalComponent::any)::T
end

Kedi.Instance = function(className)
	return className
end :: typeof(Instance.new)

return ReactLua::typeof(ReactLua)
