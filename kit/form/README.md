# Form
테이블 확장 유틸

# 사용 예시
```lua
--- myForm
return Form.new({
  myEnum = Form.Enum,
  orderedKey = Form.Order(1),
  valueIsEqualToKey = Form.Self(),
  computedSelf = Form.Self(function(self)
    return #self
  end),
  mySource = Form.Source("Source!")
})

--- anotherForm
local myForm = require(script.Parent)
return Form.from(myForm, {
  [myForm.myEnum] = 2, -- type error, Enum cannot be key
  [myForm.mySource] = "LOL" -- you can edit sources
})

--- script
print(Form.getLength(myForm)) -- 4
```
