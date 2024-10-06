# Group
유연한 로블록스 클래스 그루핑 유틸

## 사용 예시
```lua
-- Magic groups: Sound, Collision
-- usage: Group.new(className)
local soundGroup = Group.new("Sound") -- It's a magic group! uses SoundGroup instance internally
-- temp idea: local soundGroup = Group.Sound.new()
soundGroup:identify("general")
soundGroup:insert(soundInstance)
Group.insert(soundGroup, soundInstance)
Group.insert("general", soundInstance) -- You can also use the group identifier instead of self, Flexible as fuck
soundGroup.Volume = 0.5
soundInstance.SoundGroup = soundGroup -- Error: Group is not a SoundGroup nor an Instance
for i, v in Group do -- Supports generalized iteration with groups
	print(i, v) -- prints "1,
end
local elements = soundGroup:collect()
local soundGroup = Group.get("general")
-- temp idea: local soundGroup = Group.Sound.getByIdentifier("general"), reason: get이 group에서 element를 가져온다라고 해석될 수 있어서
Group.deidentify(soundGroup) -- or Group.deidentify("general")

local collisionGroup = Group.new("Collision") -- It's a magic group! you can use this as CollisionGroup! (Typechecks with BasePart)
-- temp idea: local collisionGroup = Group.Collision.new()
collisionGroup:insert(part) -- Its part.CollisionGroup will be applied like "0x000001b0b6867e78" (table memory address) if this group is not identified yet
collisionGroup:identify("MyCollisionGroup") -- This will update inserted elements' CollisionGroup to "MyCollisionGroup" from "0x000001b0b6867e78"
collisionGroup:setCollidable()

local instanceGroup = Group.new("Part", "identifier") -- Identify with new function
-- temp idea: local instanceGroup = Group.Instance.new("Part", "identifier")
instanceGroup:insert(part)
instanceGroup.CanCollide = false
```
