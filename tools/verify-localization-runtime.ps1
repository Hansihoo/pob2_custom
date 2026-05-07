param(
	[int]$TimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtimeDir = Join-Path $repoRoot "runtime"
$exePath = Join-Path $runtimeDir "Path{space}of{space}Building-PoE2.exe"
$reportPath = Join-Path $env:TEMP ("pob2-localization-runtime-" + [guid]::NewGuid().ToString("N") + ".csv")

if (-not (Test-Path -LiteralPath $exePath)) {
	throw "PoB2 runtime executable not found: $exePath"
}

Remove-Item -LiteralPath $reportPath -ErrorAction SilentlyContinue

$oldLang = [Environment]::GetEnvironmentVariable("POB_LANG", "Process")
$oldLog = [Environment]::GetEnvironmentVariable("POB_LOG_LOCALIZATION", "Process")
$oldSmoke = [Environment]::GetEnvironmentVariable("POB_LOCALIZATION_SMOKE_FILE", "Process")
$process = $null

try {
	[Environment]::SetEnvironmentVariable("POB_LANG", "ko-KR", "Process")
	[Environment]::SetEnvironmentVariable("POB_LOG_LOCALIZATION", "1", "Process")
	[Environment]::SetEnvironmentVariable("POB_LOCALIZATION_SMOKE_FILE", $reportPath, "Process")

	$process = Start-Process -FilePath $exePath -WorkingDirectory $runtimeDir -PassThru
	$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
	while ((Get-Date) -lt $deadline) {
		if (Test-Path -LiteralPath $reportPath) {
			break
		}
		if ($process.HasExited) {
			throw "PoB2 exited before writing localization runtime smoke report. ExitCode=$($process.ExitCode)"
		}
		Start-Sleep -Milliseconds 500
		$process.Refresh()
	}

	if (-not (Test-Path -LiteralPath $reportPath)) {
		throw "Timed out waiting for localization runtime smoke report: $reportPath"
	}

	$rows = Import-Csv -LiteralPath $reportPath -Header "field", "value"
	$report = @{}
	foreach ($row in $rows) {
		$report[$row.field] = $row.value
	}

	function Assert-ReportValue {
		param(
			[string]$Field,
			[string]$Expected
		)
		if ($report[$Field] -ne $Expected) {
			throw "Runtime smoke mismatch for ${Field}: expected '$Expected', got '$($report[$Field])'"
		}
	}

	Assert-ReportValue -Field "language" -Expected "ko-KR"
	Assert-ReportValue -Field "hasUnicode" -Expected "true"
	Assert-ReportValue -Field "sampleGem.name" -Expected "Ice Nova"

	if ($report["sampleGem.displayName"] -eq "Ice Nova" -or $report["sampleGem.displayName"] -notmatch "[^\x00-\x7F]") {
		throw "Sample gem displayName is not localized Korean text: '$($report["sampleGem.displayName"])'"
	}
	if ($report["sampleGem.searchText"] -notmatch "Ice Nova" -or $report["sampleGem.searchText"] -notmatch $report["sampleGem.displayName"]) {
		throw "Sample gem searchText does not contain both English and Korean: '$($report["sampleGem.searchText"])'"
	}
	if ($report["sampleBase.displayName"] -eq "Chain Tiara" -or $report["sampleBase.displayName"] -notmatch "[^\x00-\x7F]") {
		throw "Sample item base displayName is not localized Korean text: '$($report["sampleBase.displayName"])'"
	}

	Write-Output "Localization runtime smoke verification passed"
	Write-Output ("language={0} runtime={1}" -f $report["language"], $report["runtimeReason"])
	Write-Output ("sampleGem={0} -> {1}" -f $report["sampleGem.name"], $report["sampleGem.displayName"])
	Write-Output ("sampleBase={0} -> {1}" -f $report["sampleBase.name"], $report["sampleBase.displayName"])
}
finally {
	if ($process -and -not $process.HasExited) {
		Stop-Process -Id $process.Id -Force
	}
	[Environment]::SetEnvironmentVariable("POB_LANG", $oldLang, "Process")
	[Environment]::SetEnvironmentVariable("POB_LOG_LOCALIZATION", $oldLog, "Process")
	[Environment]::SetEnvironmentVariable("POB_LOCALIZATION_SMOKE_FILE", $oldSmoke, "Process")
	Remove-Item -LiteralPath $reportPath -ErrorAction SilentlyContinue
}
