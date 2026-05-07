# Stage 1: SimpleGraphic Runtime Workspace

Stage 1 목표는 PoB2 저장소와 분리된 SimpleGraphic 개발 공간을 준비하고, 패치 전 baseline 빌드가 가능한지 확인하는 것이다.

## Result

완료.

- SimpleGraphic source worktree: `D:\program\PathOfBuilding-SimpleGraphic`
- Build directory: `D:\program\build-SimpleGraphic`
- Build config: `RelWithDebInfo`
- Built DLL: `D:\program\build-SimpleGraphic\RelWithDebInfo\SimpleGraphic.dll`
- PoB2 runtime에는 아직 복사하지 않았다.

## Current PoB2 Runtime

- Bundled DLL: `runtime\SimpleGraphic.dll`
- File version: `2.5-7fd8aca`
- Product version: `2.5-7fd8aca`
- Current font assets are bitmap `.tga`/`.tgf` files under `runtime\SimpleGraphic\Fonts`.
- No TTF/OTF font is currently bundled in the PoB2 runtime.

## Source Baseline

- Repository: `https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic`
- Local branch: `master`
- Baseline commit: `c062b29 Merge pull request #99 from Helyos96/performance-improvements`
- Submodules initialized recursively.

Submodule baseline:

```text
dep/compressonator f4b53d79ec5abbb50924f58aebb7bf2793200b94
dep/glm 47585fde0c49fa77a2bf2fb1d2ead06999fd4b6e
dep/imgui 0962c9fb723ee1498a533f0e592d81f7e6c1ffd8
libs/Lua-cURLv3 9f8b6dba8b5ef1b26309a571ae75cda4034279e5
libs/luasocket 66cdeca6636a017fe8ed2b0ee431798f8fb4ade3
libs/luautf8 bdd3d7fb6ef22334fde028ba792d3a16309a4de8
vcpkg 66c0373dc7fca549e5803087b9487edfe3aca0a1
```

## Toolchain

The tools were installed but not available on the default PowerShell `PATH`.
Absolute Visual Studio paths were used.

```text
Git: 2.49.0.windows.1
CMake: C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
Ninja: C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe
MSVC cl: C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe
```

MSVC 19.44.35226 was used by the generated Visual Studio 2022 build.

## Commands

Clone:

```powershell
git clone https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic.git D:\program\PathOfBuilding-SimpleGraphic
git -C D:\program\PathOfBuilding-SimpleGraphic submodule update --init --recursive
```

Configure:

```powershell
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' `
  -B D:\program\build-SimpleGraphic `
  -S D:\program\PathOfBuilding-SimpleGraphic `
  -A x64 `
  -G "Visual Studio 17 2022" `
  --toolchain D:\program\PathOfBuilding-SimpleGraphic\vcpkg\scripts\buildsystems\vcpkg.cmake `
  -DCMAKE_INSTALL_PREFIX=D:\program\PathOfBuilding-PoE2\runtime
```

Build:

```powershell
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' `
  --build D:\program\build-SimpleGraphic `
  --config RelWithDebInfo `
  --target SimpleGraphic `
  -- /m
```

## Verification

- CMake configure completed successfully.
- vcpkg dependencies installed successfully.
- `SimpleGraphic` target built successfully.
- Built DLL exists at `D:\program\build-SimpleGraphic\RelWithDebInfo\SimpleGraphic.dll`.
- Built DLL version reports `2.5`.
- PoB2 runtime files were not modified.

## Warnings

- `engine\common\base64.c` emitted MSVC C4828 source character warnings during build.
- These warnings existed in baseline source and did not block the build.
- Default PowerShell cannot find `cmake`, `ninja`, or `cl` without absolute Visual Studio paths or a developer environment.

## Next Stage

Stage 2 can proceed.

The next decision is the Korean font package and license. The renderer work should use a redistributable OFL font, preferably Noto Sans KR or Noto Sans CJK KR, and should avoid copying PoeCharm assets or Windows system fonts into the repository.
