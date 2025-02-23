-- Credits to https://github.com/Roblox/rodux/blob/master/src/NoYield.lua

local function resultHandler(co: thread, ok: boolean, ...)
	if not ok then
		local err = (...)
		if typeof(err) == "string" then
			error(debug.traceback(co, err), 2)
		else
			-- If the error is not of type string, just assume it has some
			-- meaningful information and rethrow it with a `tostring` so that
			-- top-level error handlers can process it
			error(tostring(err), 2)
		end
	end

	if coroutine.status(co) ~= "dead" then
		error(debug.traceback(co, "Unexpected yield on a function that is being called with 'flow.noYield'"), 2)
	end

	return ...
end

local function noYield<T..., U...>(callback: (T...) -> U..., ...: T...): U...
	local co = coroutine.create(callback)

	return resultHandler(co, coroutine.resume(co, ...))
end

return noYield
