--!strict
local Queue = {}
Queue.RunningList = {}
local QueueNameList = {}
Queue.__index = Queue.RunningList

local setting = {
    TypeSetting = {
        Name = 'string';
        RunningTime = 'number';
        UseFunctionName = 'boolean';
        Add = 'function';
    };
    Base = {
        Name = 'BaseName' :: string;
        RunningTime = 0 :: number;
        UseFunctionName = false :: boolean;
    };
}

function Queue.new(Name:string , RuningTime:number , UseFunctionName:boolean)
    Name = if (Name==nil) then
        setting.Base.Name
    else
        Name
    
    RuningTime = if (RuningTime==nil) then
		setting.Base.RunningTime
    else
        RuningTime

    UseFunctionName = if (UseFunctionName==nil) then
        setting.Base.UseFunctionName
    else
		UseFunctionName
	
    assert(typeof(Name)==setting.TypeSetting.Name,`들어오는 기본값은 무조건 {setting.TypeSetting.Name} 이어야함 , 잘못됀 값 -> {typeof(Name)}`)
    
    assert(typeof(RuningTime)==setting.TypeSetting.RunningTime,`들어오는 기본값은 무조건 {setting.TypeSetting.RunningTime} 이어야함 , 잘못됀 값 -> {typeof(RuningTime)}`)

    assert(typeof(UseFunctionName)==setting.TypeSetting.UseFunctionName,`들어오는 기본값은 무조건 {setting.TypeSetting.UseFunctionName} 이어야함 , 잘못됀 값 -> {typeof(UseFunctionName)}`)
    
    if table.find(QueueNameList , Name) then
        local _i = 1
        for k,v in QueueNameList do
            if string.sub(v,3) == Name then
                _i +=1      
            end
        end

        Name = `{_i}_{Name}`
    end

    local self = {
        Name = Name;
        Queue = {};
        RunningTime = RuningTime;
        UseFunctionName = UseFunctionName;
        Eneble = true;
    }

    local newQueue = setmetatable(self , Queue);
    table.insert(QueueNameList , self.Name)

    return newQueue;
end

function Queue.RunningList:Add(func:(any)->(any) , FuncName : string , 
    async: boolean)
    if not self.Eneble then return end

    assert(type(func)==setting.TypeSetting.Add,`들어오는 기본값은 무조건 {setting.TypeSetting.Add} 이어야함 , 잘못됀 값 -> {type(func)}`);

    assert(type(async)=='boolean',`들어오는 기본값은 무조건 "boolean" 이어야함 , 잘못됀 값 -> {type(async)}`);
    

    if self.UseFunctionName then
        assert(type(FuncName)=='string',`들어오는 기본값은 무조건 "string" 이어야함 , 잘못됀 값 -> {type(FuncName)}`);
        for k,v in self.Queue do
            assert(v[2] ~= FuncName, '중복돼는 이름의 add 는 안됌')
        end

        if FuncName then
            return table.insert(self.Queue, {func, FuncName, async});
        else
            return error('use name')
        end
    else
        return table.insert(self.Queue, {func, nil, async});
    end
end

function Queue.RunningList:RunningList(pra:{any})
    if not self.Eneble then return end

    for k,v in self.Queue do
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

function Queue.RunningList:Remove()
    QueueNameList[self.Name] = nil
    self.Eneble = false
end

return Queue