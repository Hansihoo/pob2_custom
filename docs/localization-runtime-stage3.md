# Stage 3: Runtime Capability API

Stage 3 목표는 PoB2 Lua 레이어가 한글 표시 가능 여부를 `_G.utf8`만으로 추정하지 않고, SimpleGraphic 런타임이 제공하는 명시적인 capability API를 기준으로 판단하게 만드는 것이다.

## Result

완료.

- PoB2는 `loc:DetectRuntimeCapabilities()`로 런타임 기능을 감지한다.
- `GetRuntimeFeature("unicodeText")` 또는 `CanRenderText("한글")`가 true일 때만 `ko-KR` 기본 선택을 허용한다.
- 기존 PoeCharm 계열처럼 명시 API가 없고 `_G.utf8`만 있는 경우는 legacy fallback으로 계속 허용한다.
- 명시 API가 존재하지만 CJK 불가를 반환하면 `POB_LANG=ko-KR`가 있어도 영어 `en-US`로 fallback한다.
- SimpleGraphic 변경은 PoB2 저장소에 패치 파일로 보관했다.

## PoB2 Changes

변경 파일:

```text
src/Modules/Localization.lua
src/Modules/Main.lua
tools/verify-localization-smoke.lua
```

핵심 동작:

- `Localization.lua`
  - `DetectRuntimeCapabilities()` 추가
  - `GetRuntimeFeature("unicodeText")` 검사
  - `CanRenderText("한글")` 검사
  - legacy `_G.utf8` 경로는 명시 API가 없을 때만 사용
  - runtime 미지원 상태에서 `SetLanguage("ko-KR")` 요청 시 영어 fallback
  - `POB_LOG_LOCALIZATION=1`일 때 감지 결과와 fallback 이유를 로그로 기록
- `Main.lua`
  - `main:DetectUnicodeSupport()`가 `_G.utf8` 대신 `loc.hasUnicode`를 사용
- `tools/verify-localization-smoke.lua`
  - capability API positive path 검증
  - capability API가 CJK 불가를 반환할 때 `ko-KR` 요청이 `en-US`로 fallback되는지 검증
  - API가 없고 `_G.utf8`만 있는 legacy runtime fallback 검증

## SimpleGraphic Patch

외부 SimpleGraphic 작업공간:

```text
D:\program\PathOfBuilding-SimpleGraphic
```

패치 보관 위치:

```text
patches\simplegraphic\0001-runtime-capability-api.patch
```

추가 API:

```text
supported = GetRuntimeFeature("<featureName>")
supported = CanRenderText("<text>")
```

현재 Stage 3의 SimpleGraphic 구현은 안전한 stub이다.

- `GetRuntimeFeature("bitmapText")`와 `GetRuntimeFeature("asciiText")`는 true
- `GetRuntimeFeature("unicodeText")`, `cjkText`, `ttfText`는 false
- `CanRenderText(text)`는 ASCII 문자열만 true
- 실제 CJK/TTF 렌더링은 Stage 4에서 구현한다.

이 설계 덕분에 현재 기본 런타임은 한글 CSV가 있어도 깨진 한글을 강제로 표시하지 않고 영어로 남는다.

## Review Loop

Stage 3에서 실제로 발생한 검토 이슈와 수정:

- SimpleGraphic `LExpect` 호출 형식이 현재 코드베이스와 맞지 않아 빌드 실패
  - 수정: `ui->LExpect(L, condition, "...")` 형태로 보정
- SimpleGraphic 작업트리의 `core.autocrlf=true` 때문에 기본 `git diff --check`가 CRLF 추가 줄을 trailing whitespace로 오진
  - 수정: 외부 저장소 검토는 `cr-at-eol`을 명시해서 수행
  - PoB2 저장소의 패치 파일은 별도 파일로 저장해 `git diff --check` 대상에 포함
- smoke test가 positive runtime만 검증해 fallback 회귀를 놓칠 수 있음
  - 수정: runtime 미지원 fallback과 legacy `_G.utf8` 경로 검증 추가

## Verification

SimpleGraphic build:

```powershell
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' `
  --build D:\program\build-SimpleGraphic `
  --config RelWithDebInfo `
  --target SimpleGraphic `
  -- /m
```

SimpleGraphic patch check:

```powershell
git -C D:\program\PathOfBuilding-SimpleGraphic `
  -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol `
  diff --check -- ui_api.cpp
```

PoB2 checks:

```powershell
powershell -ExecutionPolicy Bypass -File tools\verify-localization.ps1
python tools\verify-localization-cloud.py
git diff --check
```

## Completion Criteria

- 기본 SimpleGraphic stub runtime에서는 `ko-KR`가 자동 선택되지 않는다.
- capability API가 한글 렌더링 가능을 반환하는 테스트 환경에서는 `ko-KR` 경로가 열린다.
- 명시 API가 한글 렌더링 불가를 반환하면 `POB_LANG=ko-KR`도 영어 fallback된다.
- canonical 영어 데이터는 변경되지 않는다.
- SimpleGraphic 변경은 재현 가능한 patch로 PoB2 저장소에 남는다.

## Next Stage

Stage 4에서 실제 TTF/CJK 렌더러를 구현한다.

다음 단계의 핵심은 Stage 3 API가 true를 반환할 수 있도록 FreeType 기반 glyph load/cache/render path를 추가하고, `DrawString`, `DrawStringWidth`, cursor index 계산이 한글 문자열에서 깨지지 않게 만드는 것이다.
