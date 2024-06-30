--!strict
--# selene: allow(mixed_table)

--- $Kit
local Strict = require(script.Parent.strict)
local ThreadPool = require(script.Parent.threadpool)
-- @class Rusty
local Rusty = {}

--- $Packages
local Option = require(script.Parent.option)
local Result = require(script.Parent.result)

export type Future<T...> = typeof(setmetatable(
	{} :: {
		_v: {
			n: number
		}?,
		_w: { thread },
		_c: { (T...) -> () },
	},
	{} :: FutureImpl
))

type FutureImpl = {
	__index: FutureImpl,

	ready: <T0...>(T0...) -> Future<T0...>,
	never: () -> Future<...any>,
	spawn: <T1..., U0...>(f: (U0...) -> T1..., U0...) -> Future<T1...>,
	pending: <T2...>() -> (Future<T2...>, (T2...) -> ()),

	join: FutureJoin,
	joinAll: (futures: { Future<...any> }) -> Future<{ any }>,
	race: (futures: { Future<...any> }) -> Future<...any>,

	isReady: <T3...>(self: Future<T3...>) -> boolean,
	isPending: <T4...>(self: Future<T4...>) -> boolean,
	now: <T5...>(self: Future<T5...>) -> Option.Option<T5...>,
	await: <T6...>(self: Future<T6...>) -> T6...,
	after: <T>(self: Future<T>, f: (T) -> ()) -> (),
}

type FutureJoin =
			(<T1, U1...>(future1: Future<T1>, future2: Future<U1...>) -> Future<(T1, U1...)>)
		& (<T1, T2, U2...>(future1: Future<T1, T2>, future2: Future<U2...>) -> Future<(T1, T2, U2...)>)
		& (<T1, T2, T3, U3...>(future1: Future<T1, T2, T3>, future2: Future<U3...>) -> Future<(T1, T2, T3, U3...)>)
		& (<T1, T2, T3, T4, U4...>(future1: Future<T1, T2, T3, T4>, future2: Future<U4...>) -> Future<(T1, T2, T3, T4, U4...)>)
		& (<T1, T2, T3, T4, T5, U5...>(future1: Future<T1, T2, T3, T4, T5>, future2: Future<U5...>) -> Future<(T1, T2, T3, T4, T5, U5...)>)
		& (<T1, T2, T3, T4, T5, T6, U6...>(future1: Future<T1, T2, T3, T4, T5, T6>, future2: Future<U6...>) -> Future<(T1, T2, T3, T4, T5, T6, U6...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, U7...>(future1: Future<T1, T2, T3, T4, T5, T6, T7>, future2: Future<U7...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, U7...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, U8...>(future1: Future<T1, T2, T3, T4, T5, T6, T7, T8>, future2: Future<U8...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, T8, U8...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, U9...>(future1: Future<T1, T2, T3, T4, T5, T6, T7, T8, T9>, future2: Future<U9...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, T8, T9, U9...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, U10...>(future1: Future<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>, future2: Future<U10...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, U10...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, U11...>(future1: Future<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>, future2: Future<U11...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, U11...)>)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, U12...>(future1: Future<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>, future2: Future<U12...>) -> Future<(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, U12...)>)

--[=[
	@class Future

	A future represents a value that does not exist yet, but will exist at some
	point in the future.

	Futures allow you to more easily compose asynchronous operations.
]=]
local Future = {} :: FutureImpl
Future.__index = Future

--[=[
	Creates a finished future with the given value.
]=]
function Future.ready(...)
	local self = setmetatable({ _f = true, _v = table.pack(...), _w = {}, _c = {} }, Future)
	return self
end

--[=[
	Creates a future that will never finish.
]=]
function Future.never()
	return setmetatable({ _w = {}, _c = {} }, Future)
end

local function finish<T...>(fut: Future<T...>, ...: T...)
	fut._v = table.pack(...)

	for _, thread in fut._w do
		if coroutine.status(thread) == "suspended" then
			coroutine.resume(thread, ...)
		end
	end

	for _, callback in fut._c do
		ThreadPool.spawn(callback, ...)
	end
end

--[=[
	Creates a future and spawns the given function in a new thread, once the
	function finishes, the future resolves with the result of the function.
]=]
function Future.spawn(f, ...)
	local function inner(self: Future<any>, fn: (...any) -> any, ...)
		finish(self, fn(...))
	end
	local self = Future.never()
	ThreadPool.spawn(inner, self, f :: any, ...)

	return self
end

--[=[
	Creates a future that is pending, and returns the future and a function that
	can be used to resolve the future with a value.
]=]
function Future.pending()
	local fut = Future.never()
	return fut, function(...)
		finish(fut, ...)
	end
end

Future.join = function(future1, future2)
	local function inner(fut1, fut2)
		return fut1:await(), fut2:await()
	end
	return Future.spawn(inner, future1, future2) :: any
end :: any

--[=[
	Takes an array of futures and returns a new future that will finish once all
	of the given futures have finished. The future will resolve with an array
	containing the results of the given futures.
]=]
function Future.joinAll(futures)
	local function inner(futs: { Future<any> })
		local result = table.create(#futs)
		for _, fut: any in futs do
			table.insert(result, fut:await())
		end
		return result
	end
	return Future.spawn(inner, futures) :: any
end

--[=[
	Takes an array of futures and returns a new future that will finish once any
	of the given futures have finished. The future will resolve with the result
	of the first future to finish.

	The result of the other futures will be discarded.
]=]
function Future.race(futures)
	local self = Future.never()
	local done = false

	for _, fut: any in futures do
		fut:after(function(val)
			if done then
				return
			end

			done = true
			finish(self, val)
		end)
	end

	return self
end

--[=[
	Returns `true` if the future has finished, `false` otherwise.
]=]
function Future.isReady(self)
	return self._v ~= nil
end

--[=[
	Returns `true` if the future is still pending, `false` otherwise.
]=]
function Future.isPending(self)
	return self._v == nil
end

--[=[
	Returns the value of the future, if it has finished. If the future is still
	pending, the function will return `None`.
]=]
function Future.now(self)
	if self._v then
		return Option.Some(table.unpack(self._v)) :: any
	else
		return Option.None
	end
end

--[=[
	Yields the current thread until the future has finished, then returns the
	value of the future.

	If the future has already finished, the function will return immediately.
]=]
Future.await = function(self)
	if self._v then
		return table.unpack(self._v)
	end

	local thread = coroutine.running()
	table.insert(self._w, thread)
	return coroutine.yield()
end :: any

--[=[
	Calls the given callback once the future has finished. If the future has
	already finished, the callback will be called immediately.
]=]
function Future.after(self, f)
	if self._v then
		f(table.unpack(self._v :: any))
	else
		table.insert(self._c, f)
	end
end

Rusty.Ok = Result.Ok
;(Result :: any).Ok = nil
Rusty.Err = Result.Err
;(Result :: any).Err = nil
Rusty.async = function(f)
	return function(...)
		return Future.spawn(f, ...)
	end
end :: <T, V...>(f: (V...) -> T) -> (V...) -> Future<T>
Rusty.Option = Option
Rusty.Result = Result
Rusty.Future = Future

return Strict.Capsule(Rusty)
