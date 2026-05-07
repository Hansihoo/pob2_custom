# Stage 2: Korean Font Package And License

Stage 2 목표는 PoB2 한글 런타임 표시를 위해 재배포 가능한 한국어 폰트와 배치 경로를 결정하는 것이다.

## Result

완료.

선택 폰트:

```text
NotoSansCJKkr-Regular.otf
```

권장 배치 경로:

```text
runtime\SimpleGraphic\Fonts\NotoSansCJKkr-Regular.otf
runtime\SimpleGraphic\Fonts\NotoSansCJK-LICENSE.txt
```

Stage 2에서는 아직 runtime 폴더에 폰트를 추가하지 않는다.
실제 파일 추가와 `manifest.xml` 갱신은 Stage 5에서 새 SimpleGraphic runtime 산출물과 함께 처리한다.

## Why This Font

- 한국어 전용 CJK variant라 PoB2 한국어 UI에 필요한 Hangul glyph를 포함한다.
- `Noto Sans KR`보다 runtime renderer 입장에서는 CJK 전체 OpenType 폰트 구조를 기준으로 삼기 쉽다.
- Regular 단일 파일만 먼저 사용하면 Stage 4 renderer 구현 범위를 줄일 수 있다.
- Bold/Italic/SmallCaps는 v1에서 같은 regular fallback으로 처리하고, 후속 단계에서 필요하면 확장한다.

## Source

Official source:

```text
https://github.com/notofonts/noto-cjk
```

File:

```text
Sans/OTF/Korean/NotoSansCJKkr-Regular.otf
```

Direct raw download candidate:

```text
https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/OTF/Korean/NotoSansCJKkr-Regular.otf
```

Official docs referenced:

- Noto docs explain that the Noto collection includes CJK font families and Korean variants such as Noto Sans KR.
- The Noto CJK Sans README recommends language-specific OTFs when only one language is needed but full character coverage is wanted.
- The Noto license is SIL Open Font License 1.1.

## License

License:

```text
SIL Open Font License, Version 1.1
```

Packaging requirements for PoB2:

- Include the OFL license text with the font.
- Do not sell the font by itself.
- Do not rename/modify the font and use reserved names for a modified derivative without permission.
- Bundling the unmodified font with software is allowed under OFL terms.

## Size And Repository Impact

Observed GitHub file size:

```text
NotoSansCJKkr-Regular.otf: 16,433,112 bytes, about 15.7 MiB
```

Impact:

- Below GitHub's 50 MB warning threshold.
- Large enough that only one regular font should be bundled for v1.
- Should be listed in `manifest.xml` in Stage 5 so updater can distribute it.
- Avoid bundling the full Super OTC or all weights because those are much larger than v1 needs.

## Renderer Assumptions

Stage 4 should implement the renderer assuming:

- Primary CJK font file name: `NotoSansCJKkr-Regular.otf`
- Default CJK font family label: `Noto Sans CJK KR`
- Regular fallback is acceptable for all PoB UI font roles in v1.
- Existing bitmap fonts can remain for ASCII, but any UTF-32 codepoint outside the bitmap font coverage should fall back to the CJK font.

## Rejected Options

### Windows Malgun Gothic

Rejected for bundling.

Reason:

- It is a Windows system font, not a PoB2 redistributable asset.
- Runtime may use it as a local fallback only if a future implementation explicitly supports system font fallback.

### PoeCharm Assets

Rejected.

Reason:

- PoeCharm is reference-only.
- Do not copy code, binaries, or translation/font assets from it.

### Full Noto Super OTC

Rejected for v1.

Reason:

- Much larger package.
- Contains far more language/weight coverage than the first Korean UI target needs.

## Stage 5 Manifest Draft

Files to add when packaging:

```text
runtime/SimpleGraphic/Fonts/NotoSansCJKkr-Regular.otf
runtime/SimpleGraphic/Fonts/NotoSansCJK-LICENSE.txt
```

`manifest.xml` must include both files after they are added.

## Verification

Stage 2 verification is documentation/license verification.

- Selected font has an official upstream source.
- License is OFL 1.1.
- File size is acceptable for repository/update distribution.
- Runtime path and file names are fixed for Stage 4 and Stage 5.

## Next Stage

Stage 3 can proceed.

Next work:

- Add runtime capability API design/implementation.
- Update PoB2 localization language selection to prefer explicit runtime capability over `_G.utf8`.
- Ensure default runtime still falls back to English if CJK rendering is unavailable.
