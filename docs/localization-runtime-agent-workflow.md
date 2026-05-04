# PoB2 Korean Runtime Agent Workflow

이 문서는 coding agent에게 단계별 작업을 맡기기 위한 실행 지시서다.
전체 방향 문서는 `docs/localization-runtime-cjk-plan.md`이고, 실제 개발 지시는 이 문서의 단계 하나씩만 전달한다.

## How To Use This File

- 한 번에 하나의 단계만 agent에게 맡긴다.
- agent에게는 이 문서와 해당 단계 번호를 함께 준다.
- agent는 해당 단계의 `Develop`, `Fix`, `Review`를 모두 수행하고 멈춘다.
- 단계가 끝나면 코드 변경, 검증 결과, 남은 위험을 짧게 보고한다.
- 다음 단계는 이전 단계의 산출물이 커밋되거나 명확히 승인된 뒤 시작한다.

권장 agent 지시문:

```text
Read docs/localization-runtime-agent-workflow.md.
Execute Stage N only.
Do not start later stages.
Keep canonical PoB data in English.
After development, run the required checks, fix failures, and report review notes.
```

## Global Rules For Agents

- PoB2 계산 엔진, 저장 파일, item import, mod parsing 입력은 영어 canonical 값을 유지한다.
- 한국어는 UI display/search, tooltip 표시, 검색 인덱스에만 붙인다.
- PoeCharm의 코드, 바이너리, 번역 데이터는 복사하지 않는다. 구조 참고만 허용한다.
- 런타임이 한국어를 렌더링하지 못하면 `ko-KR`을 강제로 보여주지 않고 영어 fallback을 사용한다.
- `_G.utf8`만으로 한국어 표시 가능 여부를 판단하지 않는다. 명시적 runtime capability가 우선이다.
- 새 시즌 대응은 코드 수정이 아니라 CSV 갱신/검증 중심이어야 한다.
- binary/runtime/font 파일을 바꾸는 단계는 반드시 manifest 영향과 라이선스 기록을 함께 남긴다.

## Cloud Agent Rules

Claude, GitHub Codespaces, remote coding agent처럼 Linux 컨테이너에서 실행되는 환경은 Windows PowerShell, `runtime/lua51.dll`, MSVC `cl`이 없을 수 있다.
이 경우 그 도구가 없다는 이유만으로 Stage 전체를 중단하지 않는다.

- PowerShell이 없으면 `python3 tools/verify-localization-cloud.py`를 사용한다.
- `python3` 명령이 없고 `python`만 있으면 `python tools/verify-localization-cloud.py`를 사용한다.
- Windows 전용 검증은 "Windows 후속 검증 필요"로 기록한다.
- `cl` 부재는 클라우드 환경에서 blocker가 아니다. Stage 1에서는 MSVC 빌드가 불가능하다는 환경 사실로 기록한다.
- GitHub fetch/clone이 네트워크 정책으로 막히면, 현재 작업공간 안에서 가능한 문서/스크립트/PoB2 Lua 작업을 계속 진행한다.
- Stage를 멈추는 blocker는 현재 작업공간 안에서 더 이상 수행 가능한 로컬 작업이 없을 때만 인정한다.

## Stage 0: Lock Current Lua Localization Baseline

목표:

- 현재 PoB2 Lua/CSV 번역 레이어가 깨지지 않았는지 기준선을 고정한다.
- 이후 런타임 작업 중 문제가 생겼을 때 Lua 레이어 문제인지 런타임 문제인지 분리할 수 있게 한다.

참고 내용:

- `docs/localization.md`
- `src/Modules/Localization.lua`
- `tools/verify-localization.ps1`
- `tools/update-localization-csv.ps1`

고려할 것:

- 이 단계에서는 SimpleGraphic C++ 런타임을 수정하지 않는다.
- CSV 번역 품질을 완벽하게 만드는 단계가 아니다.
- 목적은 "현재 데이터와 CSV가 동기화되어 있고 canonical 영어 값이 보존된다"를 확인하는 것이다.

Develop:

- localization 관련 문서와 검증 명령을 확인한다.
- 필요한 경우 smoke test가 실패하지 않도록 Lua/CSV/검증 스크립트만 수정한다.

Fix:

- `missing`, `stale`, `blank`, `orphaned`, `duplicate` 리포트가 있으면 CSV 생성 도구 또는 CSV를 수정한다.
- `gem.name`, item base key, tree node id 같은 canonical 필드가 바뀌었다면 되돌리고 display/search 파생 필드만 사용하게 수정한다.

Review:

Windows/PoB 로컬 런타임 환경에서는 다음 명령을 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
git diff --check
```

Claude 같은 클라우드/Linux 환경에서는 다음 명령을 실행한다.

```bash
python3 tools/verify-localization-cloud.py
git diff --check
```

`python3`가 없고 `python`만 있으면 다음 명령을 사용한다.

```bash
python tools/verify-localization-cloud.py
git diff --check
```

산출물:

- 통과한 검증 로그 요약
- 필요한 경우 Lua/CSV/검증 스크립트 수정
- 다음 단계가 런타임 작업으로 넘어가도 되는지 판단
- 클라우드 환경에서 Windows 전용 검증을 실행하지 못했다면 후속 Windows 검증 필요 여부 기록

완료 기준:

- Windows 환경에서는 localization verification과 CSV sync check가 통과한다.
- 클라우드 환경에서는 `tools/verify-localization-cloud.py`가 통과한다.
- working tree의 변경이 Stage 0 범위로만 제한된다.

## Stage 1: Prepare SimpleGraphic Runtime Workspace

목표:

- PoB2 저장소와 분리된 SimpleGraphic 런타임 개발 공간을 만든다.
- 패치 전 baseline 빌드 가능 여부를 확인한다.

참고 내용:

- `docs/localization-runtime-cjk-plan.md`
- SimpleGraphic upstream: https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic
- PoB2 bundled runtime: `runtime/SimpleGraphic.dll`
- PoB2 runtime rundown: `docs/rundown.md`

고려할 것:

- SimpleGraphic 소스는 현재 PoB2 저장소 안에 없다.
- 권장 작업 위치는 `D:\program\PathOfBuilding-SimpleGraphic`이다.
- 이 단계에서는 CJK renderer를 구현하지 않는다.
- 빌드 도구가 없으면 설치를 시도하지 말고 필요한 도구와 실패 원인을 문서화한다.

Develop:

- SimpleGraphic upstream을 별도 폴더에 clone한다.
- 현재 bundled `SimpleGraphic.dll` 버전과 upstream release/commit을 비교한다.
- `git`, `cmake`, `ninja`, MSVC `cl` 사용 가능 여부를 확인한다.
- baseline 빌드를 시도한다.

Fix:

- 빌드 설정 문제만 최소 수정한다.
- 소스 패치 없이 dependency path, generator, build directory 문제를 정리한다.
- 빌드가 불가능하면 "필요한 설치물/환경 변수/명령"을 명확히 남긴다.

Review:

Windows 개발 환경에서는 다음 명령을 실행한다.

```powershell
git --version
cmake --version
ninja --version
cl
```

클라우드/Linux 환경에서는 다음 명령을 실행하고, 없는 도구는 blocker가 아니라 환경 기록으로 남긴다.

```bash
git --version
cmake --version || true
ninja --version || true
cc --version || true
c++ --version || true
```

산출물:

- SimpleGraphic worktree 위치
- baseline 빌드 성공/실패 결과
- 사용한 빌드 명령
- PoB2에 runtime 산출물을 복사하지 않은 상태의 기록

완료 기준:

- baseline SimpleGraphic 빌드가 성공했거나, 실패 이유가 재현 가능한 명령과 함께 정리된다.

## Stage 2: Decide Font Package And License

목표:

- 한국어 글리프를 포함하고 재배포 가능한 폰트를 확정한다.
- 런타임이 찾을 폰트 파일명과 경로를 고정한다.

참고 내용:

- Noto font docs: https://notofonts.github.io/noto-docs/website/use/
- OFL 1.1 license
- `runtime/SimpleGraphic/Fonts/`
- `manifest.xml`

고려할 것:

- Windows 기본 폰트인 Malgun Gothic은 배포물에 직접 포함하지 않는다.
- Noto Sans KR 또는 Noto Sans CJK KR를 우선 후보로 둔다.
- 폰트 파일은 크기가 크기 때문에 GitHub 50MB 권장 제한과 updater manifest 영향을 확인한다.

Develop:

- 사용할 폰트와 정확한 파일명을 선택한다.
- 라이선스 출처를 문서화한다.
- SimpleGraphic의 폰트 검색 경로 후보를 정한다.

Fix:

- 폰트 크기가 너무 크면 subset 또는 다른 Noto variant를 검토한다.
- 라이선스 파일 누락, 출처 불명확, 파일명 불일치를 정리한다.

Review:

- 폰트 파일이 Korean glyph를 포함하는지 확인한다.
- 재배포 라이선스가 PoB2 배포와 충돌하지 않는지 확인한다.
- manifest 반영이 필요한 파일 목록을 만든다.

산출물:

- 선택된 font 파일
- 라이선스/출처 기록
- runtime font path 결정
- manifest 반영 대상 목록

완료 기준:

- renderer 단계가 참조할 폰트 파일명과 경로가 확정된다.

## Stage 3: Add Runtime Capability API

목표:

- Lua가 "이 런타임은 한국어 표시 가능"을 명시적으로 판단할 수 있게 한다.

참고 내용:

- SimpleGraphic Lua API 연결부
- `src/Modules/Localization.lua`
- Unicode reference PR: https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic/pull/24

고려할 것:

- capability API는 renderer 완성 전에도 false 또는 stub로 동작할 수 있다.
- `_G.utf8` 제공은 보조 수단이고, 최종 판단 기준은 capability API다.
- 기존 runtime에서는 함수가 없어도 PoB2가 깨지지 않아야 한다.

Develop:

- SimpleGraphic에 `GetRuntimeFeature("unicodeText")` 또는 동등 API를 추가한다.
- 가능하면 `CanRenderText("한글")` 또는 동등 API도 추가한다.
- PoB2 `Localization.lua`의 언어 선택 로직을 capability 기반으로 수정한다.
- `POB_LOG_LOCALIZATION=1`에서 선택 이유를 로그로 남긴다.

Fix:

- 기존 runtime에서 API가 없을 때 Lua error가 나지 않게 방어한다.
- `POB_LANG=ko-KR`가 있어도 capability가 없으면 영어 fallback을 선택하게 한다.

Review:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
```

산출물:

- SimpleGraphic capability API
- PoB2 runtime detection 보강
- capability 로그

완료 기준:

- 기존 runtime에서는 영어 fallback이 선택된다.
- 새 runtime capability가 true이면 `ko-KR` 선택 경로가 열린다.

## Stage 4: Implement TTF/CJK Renderer

목표:

- SimpleGraphic이 UTF-8 한국어 문자열을 실제 glyph로 렌더링하게 한다.

참고 내용:

- SimpleGraphic current text renderer
- Unicode reference PR의 FreeType/dynamic glyph cache 구조
- Stage 2에서 선택한 font
- Stage 3 capability API

고려할 것:

- 현재 SimpleGraphic의 UTF-8 to UTF-32 흐름을 최대한 유지한다.
- color code, string width, cursor index, wrapping, tooltip layout이 같이 맞아야 한다.
- ASCII 기존 표시를 깨지 않으면서 CJK glyph fallback을 추가한다.
- 성능 문제를 피하기 위해 glyph cache/atlas가 필요하다.

Develop:

- FreeType dependency를 연결한다.
- dynamic glyph cache/atlas를 구현한다.
- CJK glyph가 없을 때 fallback/tofu 처리를 명확히 한다.
- `DrawString`, `DrawStringWidth`, cursor index 계산 경로를 정합성 있게 수정한다.

Fix:

- `[U+XXXX]` placeholder가 UI에 표시되면 glyph fallback 경로를 수정한다.
- 폭 계산이 0이거나 과도하게 틀리면 metrics/scale 처리를 수정한다.
- tooltip/search input/edit control에서 깨지는 경우 해당 text path를 보완한다.

Review:

- 최소 문자열을 실제 렌더링으로 확인한다.

```text
한글 테스트
Ice Nova 얼음 폭발
Wooden Club 나무 몽둥이
```

산출물:

- CJK 가능한 SimpleGraphic build
- FreeType/font runtime dependency
- renderer smoke 결과

완료 기준:

- 한국어가 tofu나 `[U+XXXX]`가 아니라 실제 글리프로 표시된다.
- mixed English/Korean string 폭 계산이 UI 배치에 사용할 수 있다.

## Stage 5: Integrate Runtime Into PoB2

목표:

- 새 SimpleGraphic runtime과 font/dependency를 PoB2 저장소에 반영한다.

참고 내용:

- `runtime/`
- `runtime/SimpleGraphic/Fonts/`
- `manifest.xml`
- `update_manifest.py`
- `docs/localization.md`

고려할 것:

- binary 파일 변경은 diff로 검토하기 어렵기 때문에 출처와 빌드 commit을 반드시 기록한다.
- updater가 받을 파일은 manifest에 들어가야 한다.
- 기존 runtime fallback 테스트도 유지한다.

Develop:

- 새 `SimpleGraphic.dll`과 필요한 dependency/font를 PoB2 runtime 경로에 배치한다.
- `manifest.xml`에 새 파일/변경 파일을 반영한다.
- localization docs에 runtime 요구사항을 추가한다.

Fix:

- PoB2 실행 시 DLL 로드 실패가 있으면 dependency 경로를 수정한다.
- font load 실패가 있으면 font path/name 설정을 수정한다.
- manifest 누락 파일이 있으면 추가한다.

Review:

```powershell
$env:POB_LANG = "ko-KR"
$env:POB_LOG_LOCALIZATION = "1"
.\PathOfBuilding.exe
```

산출물:

- PoB2에 포함된 새 runtime 산출물
- 갱신된 manifest
- 실행 확인 로그

완료 기준:

- 새 runtime으로 PoB2 실행 시 한국어 UI/search/tooltip이 보인다.
- 기존 영어 import/save/load는 유지된다.

## Stage 6: Add Automated Runtime Verification

목표:

- 한국어 표시 지원을 수동 확인에만 의존하지 않게 한다.

참고 내용:

- `tools/verify-localization.ps1`
- `tools/verify-localization-smoke.lua`
- SimpleGraphic render/debug entrypoint

고려할 것:

- 스크린샷 검증이 어렵다면 먼저 capability/log 검증부터 추가한다.
- 가능하면 renderer smoke mode를 만들어 `[U+XXXX]` placeholder가 나오지 않는지 확인한다.
- CI에서 runtime GUI를 띄우기 어려울 수 있으므로 local verification과 CI verification을 분리한다.

Develop:

- `tools/verify-localization.ps1`에 runtime capability check를 추가한다.
- 가능하면 render smoke command 또는 screenshot check를 추가한다.
- 실패 메시지가 "Lua/CSV 문제"인지 "runtime rendering 문제"인지 구분되게 한다.

Fix:

- default runtime에서 false-positive로 실패하지 않게 fallback 기대값을 분리한다.
- new runtime이 있을 때만 CJK rendering strict check를 수행하게 옵션화한다.

Review:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
```

산출물:

- runtime-aware verification script
- render/capability smoke result
- 실패 원인 분류 로그

완료 기준:

- 기본 runtime에서는 영어 fallback이 정상으로 판정된다.
- CJK runtime에서는 한국어 rendering 가능 상태가 검증된다.

## Stage 7: Seasonal Maintenance Workflow

목표:

- 시즌 업데이트 때 코드 수정 없이 CSV 갱신 중심으로 따라갈 수 있게 한다.

참고 내용:

- `tools/update-localization-csv.ps1`
- `tools/localization-lib.lua`
- `src/Data/Translations/ko-KR/*.csv`
- `docs/localization.md`

고려할 것:

- 이 단계는 renderer 구현 이후에도 계속 반복되는 운영 단계다.
- 새 데이터 domain이 추가된 경우에만 코드 변경을 검토한다.
- 번역 품질 개선은 CSV/glossary 갱신으로 흡수한다.

Develop:

- 시즌 데이터 변경 후 CSV 후보를 재생성한다.
- glossary를 보완해 machine draft 품질을 올린다.
- missing/stale/orphan/blank/duplicate 리포트를 정리한다.

Fix:

- 새 domain이 기존 extract 도구에 잡히지 않으면 `tools/localization-lib.lua`에 extractor를 추가한다.
- UI에서 새 데이터가 영어로만 보이면 해당 UI display/search path에 `loc` 적용을 추가한다.

Review:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Refresh
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
```

산출물:

- 갱신된 CSV
- 필요하면 glossary/extractor 보강
- 시즌 업데이트 검증 결과

완료 기준:

- 새 시즌 데이터가 CSV에 반영된다.
- 기존 번역은 보존된다.
- 코드 수정 없이 대부분의 표시 데이터가 따라온다.

## Recommended Agent Split

가장 좋은 분할:

- Agent A: Stage 0, Stage 7처럼 PoB2 Lua/CSV/검증 작업을 담당한다.
- Agent B: Stage 1, Stage 3, Stage 4처럼 SimpleGraphic C++ runtime 작업을 담당한다.
- Agent C: Stage 2, Stage 5처럼 font/license/manifest/runtime packaging을 담당한다.
- Reviewer Agent: 각 stage 완료 후 diff, 검증 로그, 위험 항목만 리뷰한다.

병렬로 해도 되는 작업:

- Stage 2 font/license 결정은 Stage 1 baseline build와 병렬 가능하다.
- Stage 6 verification 설계는 Stage 3 capability API 이후부터 일부 병렬 가능하다.

순차로 해야 하는 작업:

- Stage 4 renderer 구현은 Stage 1 baseline build와 Stage 2 font 결정 후 진행한다.
- Stage 5 PoB2 runtime integration은 Stage 4 runtime build 산출물 이후 진행한다.
- Stage 7 seasonal maintenance는 현재도 가능하지만, 실제 한국어 표시 완료 판단은 Stage 5 이후 한다.

## Review Checklist For Every Stage

- 작업 범위가 해당 stage 밖으로 새지 않았는가?
- canonical 영어 값이 변경되지 않았는가?
- fallback 동작이 유지되는가?
- 검증 명령이 실제로 실행되었는가?
- 실패한 검증이 있다면 원인과 다음 조치가 기록되었는가?
- binary/font/license/manifest 변경이 있으면 출처와 재현 방법이 기록되었는가?
- 다음 stage가 사용할 산출물이 명확한가?
