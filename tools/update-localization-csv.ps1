[CmdletBinding()]
param(
	[switch]$Check,
	[switch]$Refresh
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtimeDir = Join-Path $repoRoot "runtime"
$luaDll = Join-Path $runtimeDir "lua51.dll"
$scriptPath = Join-Path $repoRoot "tools\update-localization-csv.lua"

if (-not (Test-Path -LiteralPath $luaDll)) {
	throw "Missing Lua runtime: $luaDll"
}

$env:PATH = "$runtimeDir;$env:PATH"
$previousLocalizationMode = $env:POB_LOCALIZATION_MODE
$previousLocalizationRefresh = $env:POB_LOCALIZATION_REFRESH
$env:POB_LOCALIZATION_MODE = if ($Check) { "check" } else { "write" }
$env:POB_LOCALIZATION_REFRESH = if ($Refresh) { "1" } else { "0" }

if (-not ("PobLocalizationUpdate.NativeMethods" -as [type])) {
	Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace PobLocalizationUpdate {
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
	$pointer = [PobLocalizationUpdate.NativeMethods]::lua_tolstring($State, $Index, [ref]$length)
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

$state = [IntPtr]::Zero
$previousCurrentDirectory = [Environment]::CurrentDirectory
Push-Location (Join-Path $repoRoot "src")
[Environment]::CurrentDirectory = (Resolve-Path (Join-Path $repoRoot "src")).Path
try {
	$state = [PobLocalizationUpdate.NativeMethods]::luaL_newstate()
	if ($state -eq [IntPtr]::Zero) {
		throw "Failed to allocate Lua state"
	}

	[PobLocalizationUpdate.NativeMethods]::luaL_openlibs($state)
	$result = [PobLocalizationUpdate.NativeMethods]::luaL_loadfile($state, $scriptPath)
	if ($result -ne 0) {
		throw "$(Resolve-Path $scriptPath): $(Get-LuaString -State $state -Index -1)"
	}

	$result = [PobLocalizationUpdate.NativeMethods]::lua_pcall($state, 0, 0, 0)
	if ($result -ne 0) {
		throw "$(Resolve-Path $scriptPath): $(Get-LuaString -State $state -Index -1)"
	}
}
finally {
	if ($state -ne [IntPtr]::Zero) {
		[PobLocalizationUpdate.NativeMethods]::lua_close($state)
	}
	[Environment]::CurrentDirectory = $previousCurrentDirectory
	Pop-Location
	if ($null -eq $previousLocalizationMode) {
		Remove-Item Env:\POB_LOCALIZATION_MODE -ErrorAction SilentlyContinue
	}
	else {
		$env:POB_LOCALIZATION_MODE = $previousLocalizationMode
	}
	if ($null -eq $previousLocalizationRefresh) {
		Remove-Item Env:\POB_LOCALIZATION_REFRESH -ErrorAction SilentlyContinue
	}
	else {
		$env:POB_LOCALIZATION_REFRESH = $previousLocalizationRefresh
	}
}
