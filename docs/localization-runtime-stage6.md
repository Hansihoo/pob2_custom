# Stage 6: Runtime Verification

Stage 6 목표는 한글 표시 가능 여부를 수동 화면 확인에만 의존하지 않고, 실제 PoB2 런처 안에서 검증 가능한 로그/테스트 경로를 만드는 것이다.

## Result

완료.

- `POB_LOCALIZATION_SMOKE_FILE` 환경변수를 추가했다.
- `Data.lua`가 `loc:DecorateData(data)`를 끝낸 뒤 runtime smoke report를 쓸 수 있게 했다.
- `tools/verify-localization-runtime.ps1`을 추가했다.
- `tools/verify-localization.ps1 -RunRuntime`에서 runtime smoke를 선택적으로 실행하게 했다.

## Smoke Report

`POB_LOCALIZATION_SMOKE_FILE`이 설정되어 있을 때만 CSV report를 쓴다. 일반 실행에는 영향이 없다.

보고 내용:

```text
language
hasUnicode
runtimeReason
translationFiles
translationRows
sampleGem.name
sampleGem.displayName
sampleGem.searchText
sampleBase.name
sampleBase.displayName
sampleBase.searchText
```

검증 샘플:

```text
Ice Nova -> 얼음 폭발
Chain Tiara -> 연쇄 관
```

이 샘플은 canonical 영어값이 그대로 남고, display/search 파생 필드에 한글이 붙는지 확인하기 위한 것이다.

## Runtime Test

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization-runtime.ps1
```

이 스크립트는 다음을 수행한다.

- `POB_LANG=ko-KR`를 설정한다.
- PoB2 exe를 `runtime` 작업 디렉터리에서 실행한다.
- smoke report가 생성될 때까지 기다린다.
- `language=ko-KR`, `hasUnicode=true`를 검증한다.
- `Ice Nova`와 `Chain Tiara`의 display/search 값에 한글이 들어갔는지 검증한다.
- 검증 후 실행한 PoB2 프로세스를 종료한다.

전체 localization 검증에 포함하려면 다음을 사용한다.

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1 -RunRuntime
```

## Failure Classification

- `language=en-US`: runtime capability가 언어 선택 시점에 false이거나 `ko-KR` CSV를 찾지 못한 것이다.
- `hasUnicode=false`: SimpleGraphic capability API 또는 runtime font package 경로 문제다.
- 샘플 displayName이 영어 그대로: CSV 로딩 또는 `DecorateData` 경로 문제다.
- searchText에 영어/한글 중 하나가 없음: 검색 인덱스 생성 문제다.
- process가 report 전에 종료: DLL 의존성, 런처 작업 디렉터리, runtime ABI 문제를 먼저 본다.
