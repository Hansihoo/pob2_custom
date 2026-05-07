# Stage 5: PoB2 Runtime Integration

Stage 5 목표는 CJK 렌더링이 가능한 SimpleGraphic 빌드 산출물, FreeType 의존성, Noto Sans CJK KR 폰트를 PoB2 `runtime` 패키지에 실제로 포함하는 것이다.

## Result

완료.

- `runtime/SimpleGraphic.dll`을 CJK/FreeType 빌드 산출물로 교체했다.
- 새 SimpleGraphic이 링크한 vcpkg DLL 세트를 같은 빌드 산출물로 맞췄다.
- `runtime/SimpleGraphic/Fonts/NotoSansCJKkr-Regular.otf`를 추가했다.
- `runtime/SimpleGraphic/Fonts/NotoSansCJK-LICENSE.txt`에 OFL 1.1 출처와 SPDX 확인 정보를 기록했다.
- `manifest.xml`을 갱신했다.
- 실제 PoB2 런처가 `POB_LANG=ko-KR`에서 `ko-KR`을 선택하고 한글 display/search 필드를 만드는 것을 runtime smoke로 확인했다.

## Runtime Files

새로 추가한 파일:

```text
runtime/brotlicommon.dll
runtime/brotlidec.dll
runtime/brotlienc.dll
runtime/bz2.dll
runtime/freetype.dll
runtime/libpng16.dll
runtime/SimpleGraphic/Fonts/NotoSansCJK-LICENSE.txt
runtime/SimpleGraphic/Fonts/NotoSansCJKkr-Regular.otf
```

같은 SimpleGraphic 빌드 세트로 교체한 파일:

```text
runtime/SimpleGraphic.dll
runtime/abseil_dll.dll
runtime/fmt.dll
runtime/glfw3.dll
runtime/libEGL.dll
runtime/libGLESv2.dll
runtime/libwebpdecoder.dll
runtime/re2.dll
runtime/zlib1.dll
runtime/zstd.dll
```

`lua51.dll`, `libcurl.dll`, `lcurl.dll`은 PoB 런처/앱 런타임의 기존 ABI를 유지하기 위해 교체하지 않았다.

## Source And License

SimpleGraphic source:

```text
D:\program\PathOfBuilding-SimpleGraphic
base commit: c062b29
patches:
  patches/simplegraphic/0001-runtime-capability-api.patch
  patches/simplegraphic/0002-ttf-cjk-runtime-renderer.patch
```

Font:

```text
NotoSansCJKkr-Regular.otf
source: https://github.com/notofonts/noto-cjk
file: Sans/OTF/Korean/NotoSansCJKkr-Regular.otf
license: OFL-1.1
```

SPDX manifest에서 `./Sans/OTF/Korean/NotoSansCJKkr-Regular.otf`의 `licenseConcluded`가 `OFL-1.1`임을 확인했다.

## Review Loop Findings

Stage 5 검토 중 실제로 발생한 문제와 수정:

- `SimpleGraphic.dll`만 교체했을 때 기존 `fmt.dll`과 ABI가 맞지 않아 Windows entry point 오류가 발생했다.
  - 수정: SimpleGraphic이 직접 링크한 C++/그래픽 DLL 세트를 같은 vcpkg 빌드 산출물로 맞췄다.
- `loc`가 `Data.lua` 전에 언어를 선택하는데, 기존 capability API는 renderer 초기화 전 `false`를 반환했다.
  - 수정: `GetRuntimeFeature("unicodeText")`와 `CanRenderText("한글")`이 renderer 초기화 전에도 bundled Noto font package 존재를 기준으로 true를 반환하게 했다.
- 앱을 `src` 작업 디렉터리에서 실행하면 별도 콘솔 경고가 뜰 수 있었다.
  - 검증 기준: PoB2 런처는 `runtime` 작업 디렉터리에서 실행한다.

## Verification

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1 -RunRuntime
python tools/verify-localization-cloud.py
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
git diff --check
```

결과:

```text
Localization runtime smoke verification passed
language=ko-KR runtime=CanRenderText(korean)=true
sampleGem=Ice Nova -> 얼음 폭발
sampleBase=Chain Tiara -> 연쇄 관
```
