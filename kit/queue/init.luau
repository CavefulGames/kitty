--!strict

--// $Packages
local Strict = require(script.Parent.strict)

local Queue = {}
Queue.__index = Queue

type QueueImpl = {
	__index: QueueImpl,
	new: (name: string, runningTime: number, useFunctionName: boolean) -> (),
	Add: (self: Queue, func: (any) -> any, FuncName: string, async: boolean) -> (),
	RunningList: (self: Queue, pra: { any }) -> (),
	Destroy: (self: Queue) -> ()
}

--// $Types
export type Queue = typeof(setmetatable({} :: {
	Name: string,
	Queue: { any },
	RunningTime: number,
	UseFunctionName: boolean,
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
		Name = name,
		Queue = {},
		RunningTime = runningTime,
		UseFunctionName = useFunctionName,
	}

	local newQueue = setmetatable(self, Queue)
    queueNameList[name] = name

	return newQueue
end

function Queue:Add(func, FuncName, async)
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

		return table.insert(self.Queue, { func :: any, FuncName, async })
	else
		return table.insert(self.Queue, { func :: any, nil, async })
	end
end

--// 만든 Queue 안에있는 함수들을 실행 
function Queue:RunningList(pra: { any })
	--// v -> (함수 , 함수명 , 에이씽크(비동기 유무)) , 함수실행
	for i=1 , #self.Queue do
		local value = self.Queue[i] :: {}
		if value[3] then
			--// 비동기
			task.spawn(function()
				task.wait(self.RunningTime)
				if self.UseFunctionName then
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
			task.wait(self.RunningTime)
			if self.UseFunctionName then
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
	
	self.Queue = {}
end

function Queue:Destroy()
	queueNameList[self.Name] = nil
end

return Queue