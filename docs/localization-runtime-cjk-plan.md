# PoB2 Korean Runtime Development Plan

이 문서는 CSV 기반 한국어 번역 레이어 다음 단계인 **한글 런타임 표시 지원**을 개발하기 위한 진행 기준이다.
목표는 Codex가 여러 번 이어서 작업하더라도 방향을 잃지 않도록, 단계별 개발 범위와 산출물, 검증 기준을 고정하는 것이다.

## Goal

- PoB2 계산 엔진, 저장 파일, 아이템/모드 파싱은 계속 영어 canonical 값을 사용한다.
- 한국어는 `loc` 번역 레이어가 만든 display/search 필드에만 적용한다.
- 기본 런타임이 한글을 그릴 수 없을 때는 영어 fallback으로 깨지지 않게 실행한다.
- 유니코드/TTF/CJK 렌더링이 가능한 SimpleGraphic 런타임에서는 `ko-KR` CSV가 실제 UI에 표시된다.
- 시즌 업데이트 때는 PoB 본체를 크게 수정하지 않고 CSV 갱신과 누락 검증으로 대응한다.

## Current State

- PoB2 저장소에는 Lua 번역 레이어가 있다.
  - `src/Modules/Localization.lua`
  - `src/Data/Translations/ko-KR/*.csv`
  - `tools/update-localization-csv.ps1`
  - `tools/verify-localization.ps1`
- Lua 레이어는 display/search 필드를 붙이고 canonical 영어 필드는 바꾸지 않는다.
- 현재 bundled `runtime/SimpleGraphic.dll`은 한글 TTF 렌더링을 지원하지 않는다.
- 따라서 실제 한글 표시 완료를 위해서는 PoB2 Lua 코드만으로는 부족하고, SimpleGraphic 런타임 패치가 필요하다.

## External References

- SimpleGraphic upstream: https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic
- Unicode reference PR: https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic/pull/24
- PoeCharm reference only: https://github.com/Chuanhsing/PoeCharm
- Noto font usage/license reference: https://notofonts.github.io/noto-docs/website/use/

주의: PoeCharm은 GPLv3 계열이므로 코드, 바이너리, 번역 데이터를 그대로 복사하지 않는다. 구조와 방향 참고용으로만 본다.

## Development Rules

- PoB2 내부 canonical 값은 영어로 유지한다.
- 한글 아이템 붙여넣기/역파싱은 이번 단계 범위에 넣지 않는다.
- `POB_LANG=ko-KR` 디버그 override가 있어도 런타임이 한글 렌더링을 못 하면 영어 fallback을 우선한다.
- 런타임 기능 판단은 `_G.utf8` 존재 여부만으로 끝내지 않는다. 가능하면 명시적 runtime capability API를 사용한다.
- 새 시즌 대응은 `tools/update-localization-csv.ps1`와 `tools/verify-localization.ps1`로 검증 가능한 형태를 유지한다.

## Phase 0: Baseline Lock

목적: 현재 Lua 번역 레이어가 런타임 작업 전에도 깨지지 않는 기준선을 고정한다.

개발 내용:

- 현재 PoB2 저장소에서 localization smoke test를 통과시키고 결과를 기록한다.
- `docs/localization.md`와 이 문서를 기준 문서로 둔다.
- 현재 변경 범위를 확인하고, 런타임 작업과 Lua 번역 레이어 작업을 구분한다.

산출물:

- `tools/verify-localization.ps1` 통과 결과
- 현재 CSV 동기화 상태 확인
- 필요하면 `docs/localization.md`에 운영 흐름 보강

검증:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
```

완료 기준:

- CSV 파싱, fallback, display/search smoke test가 통과한다.
- `Ice Nova` 같은 샘플에서 `gem.name`은 영어, `gem.displayName/searchText`는 한국어 포함 상태를 유지한다.

## Phase 1: SimpleGraphic Runtime Workspace

목적: PoB2 저장소와 분리된 SimpleGraphic 개발 공간을 만들고, 패치 전 baseline 빌드를 확보한다.

개발 내용:

- `PathOfBuilding-SimpleGraphic` upstream을 별도 작업 폴더에 clone한다.
- 현재 bundled `runtime/SimpleGraphic.dll` 버전과 upstream commit/release를 비교한다.
- Windows 빌드 도구 상태를 확인한다.
- 패치 전 SimpleGraphic을 빌드하고 PoB2가 기존처럼 실행되는지 확인한다.

권장 위치:

```text
D:\program\PathOfBuilding-SimpleGraphic
```

산출물:

- SimpleGraphic 별도 git worktree
- 빌드 가능한 baseline 런타임
- 빌드 명령과 의존성 기록

검증:

```powershell
git --version
cmake --version
ninja --version
cl
```

완료 기준:

- 패치 전 SimpleGraphic을 로컬에서 빌드할 수 있다.
- 빌드 산출물로 PoB2가 기존 영어 UI 상태로 실행된다.

## Phase 2: Font Packaging Decision

목적: 재배포 가능한 한국어 폰트를 선택하고, 런타임이 찾을 수 있는 위치/이름을 확정한다.

개발 내용:

- OFL 1.1 계열 폰트를 사용한다.
- 우선 후보는 Noto Sans KR 또는 Noto Sans CJK KR이다.
- Windows 기본 폰트인 Malgun Gothic은 시스템 fallback으로만 사용하고, PoB2 배포물에 직접 포함하지 않는다.
- 런타임 폰트 탐색 경로와 파일명을 확정한다.

산출물:

- `runtime/SimpleGraphic/Fonts/` 또는 SimpleGraphic 런타임이 요구하는 폰트 경로에 들어갈 TTF/OTF 파일 목록
- 폰트 라이선스 문서 또는 출처 링크
- `manifest.xml`에 추가해야 할 파일 목록 초안

완료 기준:

- 한국어 글리프가 포함된 재배포 가능 폰트가 확정된다.
- 런타임이 폰트를 찾지 못할 때도 영어 fallback이 동작한다.

## Phase 3: Runtime Capability API

목적: Lua가 런타임의 한글 표시 가능 여부를 안전하게 알 수 있게 한다.

개발 내용:

- SimpleGraphic에 명시적 기능 조회 API를 추가한다.
- 권장 API:
  - `GetRuntimeFeature("unicodeText")`
  - `CanRenderText("한글")`
- 필요하면 기존 호환성을 위해 `_G.utf8`도 제공하되, PoB2의 최종 판단은 capability API를 우선한다.

PoB2 변경 내용:

- `src/Modules/Localization.lua`의 언어 선택 로직을 capability API 기반으로 보강한다.
- capability가 없으면 `POB_LANG=ko-KR`가 있어도 기본 UI 언어는 `en-US`로 둔다.
- `POB_LOG_LOCALIZATION=1`일 때 선택 사유를 로그로 출력한다.

산출물:

- SimpleGraphic runtime API 구현
- PoB2 localization runtime detection 보강
- runtime capability smoke test

완료 기준:

- 기존 런타임에서는 영어 fallback이 선택된다.
- 새 런타임에서는 `ko-KR`이 선택된다.
- 로그로 선택 이유를 확인할 수 있다.

## Phase 4: TTF/CJK Text Renderer

목적: SimpleGraphic이 UTF-8 한국어 문자열을 실제 글리프로 렌더링하게 만든다.

개발 내용:

- FreeType 기반 동적 글리프 캐시를 구현하거나 upstream Unicode PR의 구조를 현재 SimpleGraphic에 맞게 포팅한다.
- 현재 SimpleGraphic의 UTF-8 to UTF-32 처리 흐름을 유지하고, 글리프 단계만 확장한다.
- ASCII 기존 폰트 렌더링과 CJK TTF fallback의 폭 계산, 커서 인덱스, 줄바꿈이 일관되게 동작하게 한다.
- 컬러 코드, tooltip, edit control, search input에서 문자열 폭 계산이 깨지지 않게 한다.

산출물:

- SimpleGraphic C++ 변경
- FreeType dependency 설정
- 동적 글리프 atlas/cache
- CJK 폰트 fallback 경로

검증할 동작:

- `DrawString("한글 테스트")`가 tofu placeholder나 `[U+XXXX]`가 아니라 실제 글리프로 보인다.
- `DrawStringWidth("한글 테스트")`가 0보다 크고, UI 배치에 사용할 수 있다.
- mixed string인 `Ice Nova 얼음 폭발`의 영어/한국어 폭 계산이 모두 정상이다.

완료 기준:

- 새 SimpleGraphic DLL로 PoB2를 실행했을 때 한글 텍스트가 표시된다.
- 검색창 입력, tooltip, 리스트 아이템에서 한글이 깨지지 않는다.

## Phase 5: PoB2 Runtime Integration

목적: 새 SimpleGraphic 산출물을 PoB2 런타임에 연결하고 업데이트 대상 파일을 명확히 한다.

개발 내용:

- 새 `SimpleGraphic.dll`과 필요한 DLL/font 파일을 PoB2 `runtime/` 아래에 배치한다.
- `manifest.xml`에 새/변경 런타임 파일을 반영한다.
- 필요하면 `update_manifest.py` 또는 동등한 절차로 hash를 갱신한다.
- `docs/localization.md`에 런타임 요구사항을 연결한다.

산출물:

- 업데이트된 `runtime/SimpleGraphic.dll`
- 추가 runtime dependency/font 파일
- 갱신된 `manifest.xml`
- PoB2 localization runtime detection 최종 버전

검증:

```powershell
$env:POB_LANG = "ko-KR"
$env:POB_LOG_LOCALIZATION = "1"
.\PathOfBuilding.exe
```

완료 기준:

- 새 런타임에서는 gem/item/tree 검색과 tooltip이 한국어로 표시된다.
- 기존 canonical 영어 import/save/load 흐름은 변하지 않는다.

## Phase 6: Automated Verification

목적: 개발자가 눈으로만 확인하지 않아도 한글 지원이 깨졌는지 알 수 있게 만든다.

개발 내용:

- 기존 `tools/verify-localization.ps1`에 runtime capability 확인 단계를 추가한다.
- 가능하면 SimpleGraphic에 작은 render smoke mode를 추가한다.
- 최소 테스트 문자열:
  - `한글 테스트`
  - `Ice Nova 얼음 폭발`
  - `Wooden Club 나무 몽둥이`
- screenshot 또는 render output 기반으로 `[U+XXXX]` placeholder가 나오지 않는지 확인한다.

산출물:

- runtime smoke test
- localization verify script 보강
- 실패 시 원인을 알려주는 로그

완료 기준:

- 기본 런타임에서는 "runtime does not support Korean rendering, falling back to en-US"가 확인된다.
- 새 런타임에서는 "runtime supports Korean rendering, using ko-KR"가 확인된다.
- CSV sync, Lua smoke, runtime smoke가 한 명령으로 확인 가능하다.

## Phase 7: Seasonal Maintenance Workflow

목적: 시즌 변경 때 코드 수정량을 CSV 갱신 중심으로 줄인다.

개발 내용:

- 새 시즌 PoB 데이터 반영 후 CSV 후보를 재생성한다.
- stale/missing/orphan/blank/duplicate 리포트를 보고 CSV만 정리한다.
- UI에 새 데이터 영역이 생긴 경우에만 `loc` 적용 범위를 추가한다.

시즌 업데이트 절차:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Refresh
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
```

완료 기준:

- 새 시즌 추가 젬/아이템/패시브가 CSV에 들어온다.
- 기존 번역은 보존된다.
- 코드 수정 없이 CSV 갱신만으로 대부분의 데이터 표시가 따라온다.

## Final Done Criteria

전체 개발 완료 기준:

- 새 SimpleGraphic 런타임에서 PoB2 UI가 한국어 display/search 필드를 실제 한글로 렌더링한다.
- 기본 SimpleGraphic 런타임에서는 영어 fallback으로 깨지지 않는다.
- `loc` 레이어가 canonical 영어 값을 변경하지 않는다.
- 영어 아이템 import, mod parsing, XML save/load 동작이 기존과 동일하다.
- CSV 갱신/검증 명령이 시즌 변경 대응 흐름으로 사용할 수 있다.
- PoeCharm 코드/바이너리/번역 데이터를 복사하지 않았고, 폰트 라이선스 출처가 문서화되어 있다.

## Immediate Next Step

다음 개발 턴의 첫 작업은 **Phase 0과 Phase 1**이다.

1. PoB2 현재 localization 검증을 다시 실행한다.
2. SimpleGraphic 소스 작업 폴더를 준비한다.
3. 로컬 C++ 빌드 도구 상태를 확인한다.
4. 패치 전 SimpleGraphic baseline 빌드를 시도한다.
5. 성공/실패 결과를 이 문서나 별도 작업 로그에 기록한다.
