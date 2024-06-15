local Queue = {}
Queue.RunningQueues = {}
Queue.__index = Queue.RunningQueues

local Cache = {}

--> Functions
function Queue.New(Name : string, RefreshRate : number, MassRun : boolean)
    assert(type(Name) == "string", "Argument #1 of Queue.New must be a string.")
    assert(type(RefreshRate) == "number", "Argument #2 of Queue.New must be a number.")
    assert(type(MassRun) == "boolean", "Argument #3 of Queue.New must be a boolean.")

    local self = {
        Name = Name,
        Queue = {},
        RefreshRate = RefreshRate,
        MassRun = MassRun,
        Paused = false,
    }

    local Metatable = setmetatable(self, Queue)
    table.insert(Cache, Metatable)

    return Metatable
end

function Queue.Fetch(Name : string)
    assert(type(Name) == "string", "Argument #1 of Queue.Fetch must be a string.")

    for Key, Value in ipairs(Cache)do
        if(Value.Name == Name)then
            return Value
        end
    end

    return {}
end

function Queue.RunningQueues:Add(Function : any)
    assert(type(Function) == "function", "Argument #1 of Queue:Add must be a function.")
    
        print(self)
    return table.insert(self.Queue, Function)
end

function Queue.RunningQueues:Run()
    coroutine.wrap(function()
        while(task.wait(self.RefreshRate))do
            if not(self.Paused)then
                if(#self.Queue > 0)then
                    if(self.MassRun)then
                        for Key, Value in pairs(self.Queue)do
                            pcall(function()
                                Value()
                            end)
                            self.Queue[Key] = nil

                            repeat
                                task.wait()
                            until self.Queue[Key] == nil
                        end
                    elseif not(self.MassRun)then
                        local Key, Value = next(self.Queue)
                        pcall(function()
                            Value()
                        end)
                        self.Queue[Key] = nil

                        repeat
                            task.wait()
                        until self.Queue[Key] == nil
                    end
                end
            end
        end
    end)()
end

function Queue.RunningQueues:Clear(RunFunctions : boolean)
    assert(type(RunFunctions) == "boolean", "Argument #1 of Queue.Clear must be a boolean.")

    if(RunFunctions)then
        for Key, Value in pairs(self.Queue)do
            pcall(function()
                Value()
            end)
            self.Queue[Key] = nil
        end

        self.Queue = {}
    else
        self.Queue = {}
    end
end

function Queue.RunningQueues:Pause()
    self.Paused = true
end

function Queue.RunningQueues:Resume()
    self.Paused = false
end

return Queue