# Queue
파라미터를 사용할수있는 자료구조!

## 특징
- 자료구조인대 파라미터를 사용할수있습니다!
- 비동기 , 동기 지정을 할수 있습니다!

## 사용 예시
```lua
local NameList = { "Minsoo", "Minjun" }

local NewQueue = queue.new("NewQueue", .2, true)
for _,v in NameList do
    NewQueue:add(function(Name: string)
        print(`Hello!, {Name}`)
    end, `PrintName_{v}`, false)
end

local p = {}
for i, v in NameList do
    p[`PrintName_{v}`] = { v }
end
NewQueue:run(p)
NewQueue:remove()
```
