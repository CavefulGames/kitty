# Rusty
러스트의 `Option`, `Result`, `Future`, `tokio` 에서 영감을 얻은 오류 핸들링(Result), 선택적 값 핸들링(Option), 비동기 작업(Future)에 유용한 유틸리티 모음

## 특징
- 오리지널 소스는 [util.luau](https://github.com/lukadev-0/util.luau)
- Option은 오리지널 소스에서 조금 수정함, Future는 레몬시그널을 개조한 Flow.Signal을 통해 스레드 재사용(레몬시그널에 있던)을 활용하여 다시 제작

## TODO
- ~~Future 구현~~
- Future.try 추가
- 테스트

# License
## util.luau
Original sources are from [util.luau](https://github.com/lukadev-0/util.luau) by LukaDev
```md
Copyright (c) 2024-present LukaDev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
