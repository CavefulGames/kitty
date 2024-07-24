# Debugger
버그 제거에 도움을 주는 디버깅 라이브러리

## 특징
- 개발자 모드 글로벌(`_G.__DEV__`)이 참일때만 대부분의 기능이 동작합니다.
- `nodejs/node`의 `console` 내장 라이브러리와 닷넷 프레임워크의 Debug에서 영감을 얻었습니다.
- 디버그 모드는 `Debugger.enabled`가 참이거나 스튜디오에서 실행(기본으로 Debugger.enabled가 참)하거나 `_G.__DEV__`가 참일 때 활성화됩니다.
- 디버그 모드에서 출력을 쉽게할 수 있도록 도와줍니다.
- 모듈의 버그를 예방할 수 있는 기능이 있습니다.
- 디버그 용도에서만 사용하고 코드에 직접적인 영향을 주어서는 안됩니다.

## 사용 예시
```lua
Debugger.log("Hello, developer!")
Debugger.warn("Oops, something went wrong!")

local module = {}

return Debugger.Module(module) -- 모듈의 버그 체크

```

## TODO
- 구현
