--// kit
local Strict = require(script.Parent.strict)
local React = {}

--// dependencies
local ReactLua = require(script.Parent.reactlua)
local ReactRoblox = require(script.Parent["react-roblox"])

local Event = ReactLua.Event

React.Roblox = ReactRoblox

function React.Element<T>(class:T):(props:T)->() --- only works with '--!nocheck' enabled
	return function(props:T)
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
function React.Component<T,a,b>(functionalComponent:(props:T)->(ReactLua.ReactElement<a,b>)):T
	return (functionalComponent::any)::T
end

React.Class = function(className)
	return className
end::typeof(Instance.new)

--// move methods into ReactLua
for k,v in React do
	ReactLua[k] = v
	React[k] = nil
end

return ReactLua::typeof(ReactLua)&typeof(React)
