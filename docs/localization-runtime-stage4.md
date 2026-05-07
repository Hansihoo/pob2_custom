# Stage 4: TTF/CJK Runtime Renderer

Stage 4 목표는 SimpleGraphic이 UTF-8/UTF-32 문자열을 이미 받고 있는 상태에서, 기존 bitmap font가 처리하지 못하는 한글 코드포인트를 FreeType 기반 glyph fallback으로 그릴 수 있게 만드는 것이다.

## Result

완료.

- 기존 ASCII/bitmap font 경로는 유지했다.
- 128 이상 코드포인트는 먼저 runtime CJK font glyph cache를 확인한다.
- CJK glyph가 있으면 FreeType으로 glyph bitmap을 만들고, glyph별 GL texture로 cache한 뒤 기존 `r_layer_c::Quad()` 경로로 그린다.
- font가 없거나 glyph가 없으면 기존 `[U+XXXX]` tofu fallback을 계속 사용한다.
- `GetRuntimeFeature("unicodeText")`, `cjkText`, `ttfText`는 실제 runtime font가 로드될 때 true를 반환하도록 바뀌었다.
- `CanRenderText(text)`는 실제 renderer/font가 해당 문자열을 렌더링할 수 있는지 검사한다.

## SimpleGraphic Patch

패치 보관 위치:

```text
patches\simplegraphic\0002-ttf-cjk-runtime-renderer.patch
```

적용 순서:

```powershell
git apply patches\simplegraphic\0001-runtime-capability-api.patch
git apply patches\simplegraphic\0002-ttf-cjk-runtime-renderer.patch
```

변경 파일:

```text
CMakeLists.txt
vcpkg.json
engine/render.h
engine/render/r_font.h
engine/render/r_font.cpp
engine/render/r_main.h
engine/render/r_main.cpp
engine/render/r_texture.cpp
ui_api.cpp
```

## Renderer Design

기존 경로:

- `DrawString*` API는 UTF-8 string을 받는다.
- `IndexUTF8ToUTF32()`가 UTF-32 codepoint sequence로 변환한다.
- `r_font_c`는 bitmap `.tgf/.tga` font에 없는 codepoint를 `[U+XXXX]` 문자열로 대체했다.

새 경로:

- `r_font_c`가 `SimpleGraphic/Fonts/NotoSansCJKkr-Regular.otf`를 FreeType face로 연다.
- 기존 bitmap glyph 범위에 없는 codepoint는 `GetRuntimeGlyph(height, cp)`로 lookup/cache한다.
- glyph cache key는 `height + codepoint`다.
- FreeType bitmap은 `IMGTYPE_GRAY` `image_c`로 복사되고 `r_tex_c` texture로 직접 업로드된다.
- width/cursor 계산은 runtime glyph advance를 사용한다.
- 실제 draw는 glyph bearing과 advance를 사용해 기존 quad batching에 올린다.

## Dependency Changes

추가 vcpkg dependency:

```text
freetype
```

CMake target:

```text
Freetype::Freetype
```

빌드 결과 새 runtime dependency 후보:

```text
freetype.dll
libpng16.dll
bz2.dll
brotlicommon.dll
brotlidec.dll
brotlienc.dll
```

이 DLL들은 Stage 5에서 PoB2 `runtime` 배포물에 포함해야 한다.

## Review Loop

Stage 4에서 실제로 발생한 검토 이슈와 수정:

- `ui_api.cpp`가 concrete renderer가 아니라 `r_IRenderer` interface를 보므로 capability 메서드가 보이지 않아 빌드 실패
  - 수정: `r_IRenderer`에도 `HasUnicodeTextSupport()`와 `CanRenderText()`를 추가
- dynamic glyph texture가 `r_tex_c(manager, image, flags)` 생성자를 사용하면서 기존 생성자 shadowing 버그를 밟을 수 있음
  - 수정: direct upload 생성자가 매개변수 `img`가 아니라 `this->img`에 `BuildMipSet()` 결과를 저장하도록 수정
- FreeType bitmap pitch는 음수일 수 있음
  - 수정: pitch 방향을 고려해 glyph bitmap row를 복사
- CRLF 작업트리와 patch 보관 파일 때문에 기본 whitespace 검토가 소음이 됨
  - 수정: SimpleGraphic 외부 검토는 `cr-at-eol` 옵션으로 수행하고, PoB2 patch 파일은 `.gitattributes`의 `-whitespace` 규칙을 사용

## Verification

CMake configure:

```powershell
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' `
  -B D:\program\build-SimpleGraphic `
  -S D:\program\PathOfBuilding-SimpleGraphic `
  -A x64 `
  -G "Visual Studio 17 2022" `
  --toolchain D:\program\PathOfBuilding-SimpleGraphic\vcpkg\scripts\buildsystems\vcpkg.cmake `
  -DCMAKE_INSTALL_PREFIX=D:\program\PathOfBuilding-PoE2\runtime
```

Result:

```text
freetype and transitive dependencies installed successfully.
Configuring done.
Generating done.
```

Build:

```powershell
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' `
  --build D:\program\build-SimpleGraphic `
  --config RelWithDebInfo `
  --target SimpleGraphic `
  -- /m
```

Result:

```text
SimpleGraphic.vcxproj -> D:\program\build-SimpleGraphic\RelWithDebInfo\SimpleGraphic.dll
```

Patch checks:

```powershell
git -C D:\program\PathOfBuilding-SimpleGraphic `
  -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol `
  diff --check -- CMakeLists.txt vcpkg.json engine/render.h engine/render/r_font.h engine/render/r_font.cpp engine/render/r_main.h engine/render/r_main.cpp engine/render/r_texture.cpp ui_api.cpp

git -C D:\program\PathOfBuilding-SimpleGraphic apply --reverse --check D:\program\PathOfBuilding-PoE2\patches\simplegraphic\0002-ttf-cjk-runtime-renderer.patch
```

## Remaining For Stage 5

Stage 4는 renderer code path와 build를 완료했지만, PoB2 runtime package에는 아직 새 DLL, FreeType dependency DLL, Noto font가 들어가지 않았다.

따라서 실제 PoB2 실행에서 한글이 보이려면 Stage 5에서 다음을 수행해야 한다.

- `D:\program\build-SimpleGraphic\RelWithDebInfo\SimpleGraphic.dll`을 PoB2 `runtime`에 반영
- FreeType 관련 runtime DLL들을 PoB2 `runtime`에 반영
- `NotoSansCJKkr-Regular.otf`와 OFL license를 `runtime\SimpleGraphic\Fonts`에 추가
- `manifest.xml` 갱신
- `POB_LANG=ko-KR`, `POB_LOG_LOCALIZATION=1`로 실제 실행 확인
