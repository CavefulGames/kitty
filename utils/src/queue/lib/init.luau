--!strict

--$Packages
local strict = require(script.Parent.roblox_packages.strict)
local Queue = {} :: QueueImpl
Queue.__index = Queue

type QueueImpl = {
	__index: QueueImpl,
	new: (name: string, runningTime: number, useFunctionName: boolean) -> (Queue),
	add: (self: Queue, func: (any) -> any, funcName: string, async: boolean) -> (),
	run: (self: Queue, pra: { any }) -> (),
	remove: (self: Queue) -> ()
}

--$Types
export type Queue = typeof(setmetatable({} :: {
	name: string,
	queue: { any },
	runningTime: number,
	useFunctionName: boolean,
}, {} :: QueueImpl))

--$PrivateVariables
local queueNameList = {} :: { [string]: string }
local base = {
	name = "BaseName" :: string,
	runningTime = 0 :: number,
	useFunctionName = false :: boolean,
}

function Queue.new(name, runningTime, useFunctionName)
	name = if name == nil then base.name else name

	runningTime = if runningTime == nil then base.runningTime else runningTime

	useFunctionName = if useFunctionName == nil then base.useFunctionName else useFunctionName

	strict.Tuple.new()
		:expect(name, "string")
		:expect(runningTime, "number")
		:expect(useFunctionName, "boolean")

	if queueNameList[name] then
		local _i = 1
		for _, v in queueNameList do
			if string.sub(v, 3) == name then
				_i += 1
			end
		end

		name = `{_i}_{name}`
	end

	local self = {
		name = name,
		queue = {},
		runningTime = runningTime,
		useFunctionName = useFunctionName,
	}

	local newQueue = setmetatable(self, Queue)
    queueNameList[name] = name

	return newQueue
end

function Queue.add(self, func, funcName, async)
	local typecheckTuple = strict.Tuple.new()

	typecheckTuple
		:expect(func, "function")
		:skip()
		:expect(async, "boolean")

	if self.useFunctionName then
		typecheckTuple
		:from(2):expect(funcName, "string")

		for _, v in self.queue do
			if v[2] ~= funcName then
				error(`Name '{funcName}' is already in use`, 2)
			end
		end

		return table.insert(self.queue, { func :: any, funcName, async })
	else
		return table.insert(self.queue, { func :: any, nil, async })
	end
end

-- 만든 Queue 안에있는 함수들을 실행
function Queue.run(self, pra: { any })
	-- v -> (함수 , 함수명 , 에이씽크(비동기 유무)) , 함수실행
	for i=1 , #self.queue do
		local value = self.queue[i] :: {}
		if value[3] then
			-- 비동기
			task.spawn(function()
				task.wait(self.runningTime)
				if self.useFunctionName then
					pcall(function()
						value[1](table.unpack(pra[value[2]]))
					end)
				else
					pcall(function()
						value[1]()
					end)
				end
			end)
		else
			task.wait(self.runningTime)
			if self.useFunctionName then
				pcall(function()
					value[1](table.unpack(pra[value[2]]))
				end)
			else
				pcall(function()
					value[1]()
				end)
			end
		end
	end

	self.queue = {}
end

function Queue.remove(self)
	queueNameList[self.name] = nil
end

return strict.module("Queue", Queue)
