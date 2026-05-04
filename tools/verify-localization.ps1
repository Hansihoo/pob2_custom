[CmdletBinding()]
param(
	[switch]$RunBusted,
	[switch]$RunDocker
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtimeDir = Join-Path $repoRoot "runtime"
$luaDll = Join-Path $runtimeDir "lua51.dll"

if (-not (Test-Path -LiteralPath $luaDll)) {
	throw "Missing Lua runtime: $luaDll"
}

$env:PATH = "$runtimeDir;$env:PATH"

if (-not ("PobLocalizationVerify.NativeMethods" -as [type])) {
	Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace PobLocalizationVerify {
	public static class NativeMethods {
		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern IntPtr luaL_newstate();

		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern void luaL_openlibs(IntPtr L);

		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern int luaL_loadfile(IntPtr L, [MarshalAs(UnmanagedType.LPStr)] string filename);

		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern int lua_pcall(IntPtr L, int nargs, int nresults, int errfunc);

		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern IntPtr lua_tolstring(IntPtr L, int index, out IntPtr len);

		[DllImport("lua51.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern void lua_close(IntPtr L);
	}
}
"@
}

function Get-LuaString {
	param(
		[Parameter(Mandatory = $true)]
		[IntPtr]$State,
		[Parameter(Mandatory = $true)]
		[int]$Index
	)

	$length = [IntPtr]::Zero
	$pointer = [PobLocalizationVerify.NativeMethods]::lua_tolstring($State, $Index, [ref]$length)
	if ($pointer -eq [IntPtr]::Zero) {
		return ""
	}

	$count = $length.ToInt32()
	if ($count -le 0) {
		return ""
	}

	$bytes = New-Object byte[] $count
	[Runtime.InteropServices.Marshal]::Copy($pointer, $bytes, 0, $count)
	return [Text.Encoding]::UTF8.GetString($bytes)
}

function Invoke-LuaFile {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[Parameter(Mandatory = $true)]
		[string]$WorkingDirectory,
		[switch]$Execute
	)

	$state = [IntPtr]::Zero
	$previousCurrentDirectory = [Environment]::CurrentDirectory
	Push-Location $WorkingDirectory
	[Environment]::CurrentDirectory = (Resolve-Path $WorkingDirectory).Path
	try {
		$state = [PobLocalizationVerify.NativeMethods]::luaL_newstate()
		if ($state -eq [IntPtr]::Zero) {
			throw "Failed to allocate Lua state"
		}

		[PobLocalizationVerify.NativeMethods]::luaL_openlibs($state)
		$result = [PobLocalizationVerify.NativeMethods]::luaL_loadfile($state, $Path)
		if ($result -ne 0) {
			throw "$(Resolve-Path $Path): $(Get-LuaString -State $state -Index -1)"
		}

		if ($Execute) {
			$result = [PobLocalizationVerify.NativeMethods]::lua_pcall($state, 0, 0, 0)
			if ($result -ne 0) {
				throw "$(Resolve-Path $Path): $(Get-LuaString -State $state -Index -1)"
			}
		}
	}
	finally {
		if ($state -ne [IntPtr]::Zero) {
			[PobLocalizationVerify.NativeMethods]::lua_close($state)
		}
		[Environment]::CurrentDirectory = $previousCurrentDirectory
		Pop-Location
	}
}

function Invoke-OptionalBusted {
	if (-not $RunBusted) {
		return
	}

	$busted = Get-Command busted -ErrorAction SilentlyContinue
	if (-not $busted) {
		throw "busted is not available on PATH"
	}

	Push-Location $repoRoot
	try {
		& $busted.Source --lua=luajit spec/System/TestLocalization_spec.lua
		if ($LASTEXITCODE -ne 0) {
			throw "Busted localization spec failed"
		}
	}
	finally {
		Pop-Location
	}
}

function Invoke-OptionalDocker {
	if (-not $RunDocker) {
		return
	}

	$docker = Get-Command docker -ErrorAction SilentlyContinue
	if (-not $docker) {
		throw "docker is not available on PATH"
	}

	Push-Location $repoRoot
	try {
		& $docker.Source compose run --rm busted-tests busted --lua=luajit spec/System/TestLocalization_spec.lua
		if ($LASTEXITCODE -ne 0) {
			throw "Docker Busted localization spec failed"
		}
	}
	finally {
		Pop-Location
	}
}

$syntaxFiles = @(
	"src/Modules/Localization.lua",
	"src/Modules/Main.lua",
	"src/Modules/Data.lua",
	"src/Classes/GemSelectControl.lua",
	"src/Classes/SkillsTab.lua",
	"src/Classes/ItemDBControl.lua",
	"src/Classes/ItemsTab.lua",
	"src/Classes/NotableDBControl.lua",
	"src/Classes/PassiveTree.lua",
	"src/Classes/PassiveTreeView.lua",
	"src/Classes/EditControl.lua",
	"src/Classes/CalcBreakdownControl.lua",
	"spec/System/TestLocalization_spec.lua",
	"src/Data/Translations/ko-KR/manifest.lua",
	"tools/verify-localization-smoke.lua",
	"tools/localization-lib.lua",
	"tools/update-localization-csv.lua"
)

Write-Host "Checking Lua syntax..."
foreach ($file in $syntaxFiles) {
	Invoke-LuaFile -Path (Join-Path $repoRoot $file) -WorkingDirectory $repoRoot
}

Write-Host "Checking localization CSV synchronization..."
& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "tools/update-localization-csv.ps1") -Check
if ($LASTEXITCODE -ne 0) {
	throw "Localization CSV synchronization check failed"
}

Write-Host "Running standalone localization smoke verification..."
$previousLocalizationLog = $env:POB_LOG_LOCALIZATION
$env:POB_LOG_LOCALIZATION = "1"
try {
	Invoke-LuaFile -Path (Join-Path $repoRoot "tools/verify-localization-smoke.lua") -WorkingDirectory (Join-Path $repoRoot "src") -Execute
}
finally {
	if ($null -eq $previousLocalizationLog) {
		Remove-Item Env:\POB_LOG_LOCALIZATION -ErrorAction SilentlyContinue
	}
	else {
		$env:POB_LOG_LOCALIZATION = $previousLocalizationLog
	}
}

Invoke-OptionalBusted
Invoke-OptionalDocker

Write-Host "Localization verification passed"
