# Flow
스크립트 시간과 흐름, 제어, 코루틴에 관련된 유틸리티 모음

## 특징
- 레몬시그널을 개조하여 만든 시그널(`limesignal`) 포함

## 사용 예시
```lua
-- time, os.clock, time 라벨링
Flow.getGameTime() -- time
Flow.getLuaTime() -- os.clock
Flow.getUTCTime() -- time
Flow.getServerTime() -- workspace:GetServerTimeNow()

-- sleep, wakeUp, sleepUntil
task.delay(5, function()
	Flow.wakeUp("깨우지마")
end)
Flow.sleep("깨우지마", 100)
-- oop
local sleep = Flow.Sleep.new(100) -- 테이블에 넣어서 사용하면 타입 체킹 가능
task.delay(5, function()
	sleep:wakeUp()
end)
sleep:start()

Flow.sleepUntil(Flow.getServerTime, 10) -- 함수가 반환하는 숫자 >= 함수가 반환하는 숫자 + 10이 될 때 까지 기다림

-- signal
Flow.Signal.new()
Flow.Bindable.new()

-- threadpool
Flow.spawn(function()
	-- do something
end)
```

## TODO
- ~~레몬시그널을 개조한 시그널 기능 구현 (named LimeSignal)~~
- TaskQueue 기능 추가
- Net 관련, 동기화 관련 기능 추가
- sleep 구현 개선 (`task.wait` vs `task.cancel` + `coroutine`)
- Sleep 클래스 추가
