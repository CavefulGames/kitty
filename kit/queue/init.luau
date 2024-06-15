--!strict

--// $Packages
local Strict = require(script.Parent.strict)
type QueueImpl = {
	__index: QueueImpl,
	new: (name: string, runningTime: number, useFunctionName: boolean) -> (),
	Add: (self: Queue, func: (any) -> any, FuncName: string, async: boolean) -> (),
	RunningList: (self: Queue, pra: { any }) -> (),
	Destroy: (self: Queue) -> ()
}
local Queue = {} :: QueueImpl
Queue.__index = Queue

--// $Types
export type Queue = typeof(setmetatable({} :: {
	Name: string,
	Queue: { any },
	RunningTime: number,
	UseFunctionName: boolean,
	Enabled: boolean
}, {} :: QueueImpl))

--// $PrivateVariables
local queueNameList = {}
local base = {
	name = "BaseName" :: string,
	runningTime = 0 :: number,
	useFunctionName = false :: boolean,
}

function Queue.new(name, runningTime, useFunctionName)
	name = if name == nil then base.name else name

	runningTime = if runningTime == nil then base.runningTime else runningTime

	useFunctionName = if useFunctionName == nil then base.useFunctionName else useFunctionName

	Strict.Tuple.new()
	:expect(name, "string")
	:expect(runningTime, "number")
	:expect(useFunctionName, "boolean")

	if table.find(queueNameList, name) then
		local _i = 1
		for k, v in queueNameList do
			if string.sub(v, 3) == name then
				_i += 1
			end
		end

		name = `{_i}_{name}`
	end

	local self = {
		Name = name,
		Queue = {},
		RunningTime = runningTime,
		UseFunctionName = useFunctionName,
		Enabled = true,
	}

	local newQueue = setmetatable(self, Queue)
	table.insert(queueNameList, name)

	return newQueue
end

function Queue:Add(func, FuncName, async)
	if not self.Enabled then
		return
	end

	local TypecheckingTuple = Strict.Tuple.new()

	TypecheckingTuple
	:expect(func, "function")
	:skip()
	:expect(async, "boolean")

	if self.UseFunctionName then
		TypecheckingTuple
		:from(2):expect(FuncName, "string")

		for k, v in self.Queue do
			assert(v[2] ~= FuncName, "중복돼는 이름의 add 는 안됌")
		end

		if FuncName then
			return table.insert(self.Queue, { func :: any, FuncName, async })
		else
			return error("use name")
		end
	else
		return table.insert(self.Queue, { func :: any, nil, async })
	end
end

function Queue:RunningList(pra: { any })
	if not self.Enabled then
		return
	end

	for k, v in self.Queue do
		if v[3] then
			task.spawn(function()
				task.wait(self.RunningTime)
				if self.UseFunctionName then
					pcall(function()
						v[1](table.unpack(pra[v[2]]))
					end)
				else
					pcall(function()
						v[1]()
					end)
				end
			end)
		else
			task.wait(self.RunningTime)
			if self.UseFunctionName then
				pcall(function()
					v[1](table.unpack(pra[v[2]]))
				end)
			else
				pcall(function()
					v[1]()
				end)
			end
		end
		Queue[k] = nil
	end
end

function Queue:Destroy()
	queueNameList[self.Name] = nil
	self.Enabled = false
end

return Queue
