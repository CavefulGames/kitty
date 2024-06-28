--- Option & Result credit to https://github.com/lukadev-0/util.luau
--- removed Option.join

--# selene: allow(mixed_table)

export type Option<T...> = typeof(setmetatable(
	{} :: {
		-- value to "store" T...
		-- this value doesn't exist at runtime, and is only used for typechecking
		_T: (T...) -> (),
		_n: number,
	},
	{} :: OptionImpl
))

export type OptionImpl = {
	__index: OptionImpl,
	__tostring: <T...>(self: Option<T...>) -> string,
	__eq: <T...>(self: Option<T...>, other: Option<T...>) -> boolean,

	None: Option<...any>,
	Some: <T...>(T...) -> Option<T...>,
	from: <T>(value: T?) -> Option<T>,
	is: (value: unknown) -> boolean,
	isSome: <T...>(self: Option<T...>) -> boolean,
	isSomeAnd: <T...>(self: Option<T...>, f: (T...) -> boolean) -> boolean,
	isNone: <T...>(self: Option<T...>) -> boolean,
	expect: <T...>(self: Option<T...>, message: string) -> T...,
	unwrap: <T...>(self: Option<T...>) -> T...,
	unwrapOr: <T...>(self: Option<T...>, T...) -> T...,
	unwrapOrElse: <T...>(self: Option<T...>, f: () -> T...) -> T...,
	unwrapOrNil: <T...>(self: Option<T...>) -> T...?,
	map: <T..., U...>(self: Option<T...>, f: (T...) -> U...) -> Option<U...>,
	mapOr: <U, T...>(self: Option<T...>, default: U, f: (T...) -> U) -> U,
	mapOrRest: <T..., U...>(self: Option<T...>, f: (T...) -> U..., U...) -> U...,
	mapOrElse: <T..., U...>(self: Option<T...>, default: () -> U..., f: (T...) -> U...) -> U...,
	andOpt: <T..., U...>(self: Option<T...>, other: Option<U...>) -> Option<U...>,
	andThen: <T..., U...>(self: Option<T...>, f: (T...) -> Option<U...>) -> Option<U...>,
	filter: <T...>(self: Option<T...>, f: (T...) -> boolean) -> Option<T...>,
	orOpt: <T...>(self: Option<T...>, other: Option<T...>) -> Option<T...>,
	orElse: <T...>(self: Option<T...>, f: () -> Option<T...>) -> Option<T...>,
	xor: <T...>(self: Option<T...>, other: Option<T...>) -> Option<T...>,
	match: <T..., U...>(self: Option<T...>, f: { Some: (T...) -> U..., None: () -> U... }) -> U...,
}

--[=[
	@class Option

	Represents an optional value: `Some` and contains a value, or `None`
	and does not contain a value.

	Options can be used as an alternative to `nil` to represent the
	absence of a value. They help you avoid bugs by requiring you to
	handle the case where a value might be missing.
]=]
local Option = {} :: OptionImpl
Option.__index = Option

--[=[
	The `Option` that does not contain a value.
]=]
Option.None = table.freeze(setmetatable({ _n = 0 }, Option) :: any)

--[=[
	Creates a new `Some` with the given value.
]=]
function Option.Some(...)
	local n = select("#", ...)
	if n == 0 then
		error("Option.Some() called with no arguments", 2)
	end
	local self = setmetatable({ _n = n, ... }, Option)
	return table.freeze(self) :: any
end

--[=[
	Converts the given value to an `Option`, returning `None` if the
	value is `nil`.
]=]
function Option.from(value)
	if value == nil then
		return Option.None
	else
		return Option.Some(value) :: any
	end
end

--[=[
	Returns `true` if the given value is an `Option`.
]=]
function Option.is(value)
	return typeof(value) == "table" and getmetatable(value :: any) == Option
end

--[=[
	Returns `true` if the option is a `Some` value.
]=]
function Option.isSome(self)
	return self._n ~= 0
end

--[=[
	Returns `true` if the option is a `Some` value and the value
	satisfies the given predicate.
]=]
function Option.isSomeAnd(self, f)
	return self._n ~= 0 and f(unpack(self :: any))
end

--[=[
	Returns `true` if the option is a `None` value.
]=]
function Option.isNone(self): boolean
	return self._n == 0
end

--[=[
	Returns the value of the option if it is `Some`, otherwise throws
	an error with the given message.
]=]
function Option.expect(self, message)
	if self._n == 0 then
		error(message, 2)
	end
	return unpack(self :: any)
end

--[=[
	Returns the value of the option if it is `Some`, otherwise throws
	an error.
]=]
function Option.unwrap(self)
	if self._n == 0 then
		error("called `Option.unwrap()` on a `None` value", 2)
	end
	return unpack(self :: any)
end

--[=[
	Returns the value of the option if it is `Some`, otherwise returns
	the given default value.
]=]
function Option.unwrapOr(self, ...)
	if self._n == 0 then
		return ...
	end
	return unpack(self :: any)
end

--[=[
	Returns the value of the option if it is `Some`, otherwise returns
	the result of calling the given function.
]=]
function Option.unwrapOrElse(self, f)
	if self._n == 0 then
		return f()
	end
	return unpack(self :: any)
end

--[=[
	Returns the value of the option if it is `Some`, otherwise returns
	`nil`. Only works with `Option`s that contain a single value.
]=]
function Option.unwrapOrNil(self)
	return self[1]
end

--[=[
	Returns the result of the given function wrapped in an `Option` if
	the option is `Some`, otherwise returns `None`.
]=]
function Option.map(self, f)
	if self._n == 0 then
		return Option.None
	end
	return Option.Some(f(unpack(self :: any)))
end

--[=[
	Returns the result of the given function if the option is `Some`,
	otherwise returns the given default value.
]=]
function Option.mapOr(self, default, f)
	if self._n == 0 then
		return default
	end
	return f(unpack(self :: any))
end

--[=[
	Returns the result of the given function if the option is `Some`,
	otherwise returns the rest of the arguments.
]=]
function Option.mapOrRest(self, f, ...)
	if self._n == 0 then
		return ...
	end
	return f(unpack(self :: any))
end

--[=[
	Returns the result of the given function if the option is `Some`,
	otherwise returns the result of calling the default function.
]=]
function Option.mapOrElse(self, default, f)
	if self._n == 0 then
		return default()
	end
	return f(unpack(self :: any))
end

--[=[
	Returns `None` if the option is `None`, otherwise returns the other option.
]=]
function Option.andOpt(self, other)
	if self._n == 0 then
		return Option.None
	end
	return other
end

--[=[
	Returns `None` if the option is `None`, otherwise calls the given
	function with the value of the option and returns the result.
]=]
function Option.andThen(self, f)
	if self._n == 0 then
		return Option.None
	end
	return f(unpack(self :: any))
end

--[=[
	Returns `None` if the option is `None`, otherwise calls the given
	function with the value:
	- if the function returns `true`, returns the original option
	- if the function returns `false`, returns `None`
]=]
function Option.filter(self, f)
	if self._n == 0 then
		return Option.None
	end
	if f(unpack(self :: any)) then
		return self
	end
	return Option.None
end

--[=[
	Returns the option if it is `Some`, otherwise returns
	the other option.
]=]
function Option.orOpt(self, other)
	if self._n ~= 0 then
		return self
	end
	return other
end

--[=[
	Returns the option if it is `Some`, otherwise returns
	the result of calling the given function.
]=]
function Option.orElse(self, f)
	if self._n ~= 0 then
		return self
	end
	return f()
end

--[=[
	Returns `Some` if exactly one of the options is `Some`, otherwise
	returns `None`.
]=]
function Option.xor(self, other)
	if self._n == 0 then
		return other
	end
	if other._n == 0 then
		return self
	end
	return Option.None
end

--[=[
	Takes a table containing a `Some` and `None` function. If the option
	is a `Some`, calls the `Some` function with the value of the option,
	otherwise calls the `None` function. The result of the function call
	is returned.
]=]
function Option.match(self, f)
	if self._n ~= 0 then
		return f.Some(unpack(self :: any))
	end
	return f.None()
end

--[=[
	Converts the given option to a string.
]=]
function Option.__tostring(self)
	if self._n ~= 0 then
		local s = ""
		for i = 1, self._n do
			if i > 1 then
				s ..= ", "
			end

			local v = self[i]
			if typeof(v) == "string" then
				s ..= string.format("%q", v)
			else
				s ..= tostring(v)
			end
		end

		return `Option::Some({s})`
	else
		return "Option::None"
	end
end

--[=[
	Returns `true` if the given value is an `Option` and contains the
	same value as this option, `false` otherwise.
]=]
function Option.__eq(self, other)
	if Option.is(other) then
		if self._n == 0 and other._n == 0 then
			return true
		elseif self._n == 1 and other._n == 1 then
			return self[1] == other[1]
		elseif self._n == other._n then
			for i = 1, self._n do
				if self[i] ~= other[i] then
					return false
				end
			end
			return true
		end
	end
	return false
end

local Future = {}

local Strict = require(script.Parent.strict)

return {
	Option = Option,
	Result = require(script.Parent.result),
	Future = Future,
}
