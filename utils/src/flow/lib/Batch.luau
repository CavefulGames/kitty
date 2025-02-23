-- credits to

export type Batch<T> = typeof(setmetatable(
	{} :: {
		_queue: { T },
		_flushing: boolean,
		_scheduled: thread?,
		_onFlush: ({ T }) -> ()
	},
	{} :: BatchImpl
))

type BatchImpl = {
	__index: BatchImpl,
	new: <T>(onFlush: ({ T }) -> ()) -> (Batch<T>),
	add: <T>(self: Batch<T>, object: T) -> (),
	clear: <T>(self: Batch<T>) -> ()
}

local Batch = {} :: BatchImpl
Batch.__index = Batch

function Batch.new(onFlush)
	return setmetatable({
		_queue = {},
		_flushing = false,
		_scheduled = nil,
		_onFlush = onFlush
	}, Batch)
end

function Batch.add<T>(self: Batch<T>, object: T)
	table.insert(self._queue, object)

	if self._scheduled == nil then
		self._scheduled = task.defer(function()
			self._flushing = true
			self._onFlush(self._queue)
			table.clear(self._queue)
			self._flushing = false
			self._scheduled = nil
		end)
	end
end

function Batch.clear<T>(self: Batch<T>)
	if self._flushing then
		return
	end

	if self._scheduled ~= nil then
		task.cancel(self._scheduled)
		self._scheduled = nil
	end

	table.clear(self._queue)
end

return Batch
