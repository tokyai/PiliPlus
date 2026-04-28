param(
    [string]$StatusOutputPath = "build/runtime-smoke/environment-readiness-status.json",
    [string]$ReportOutputPath = "build/runtime-smoke/environment-readiness-report.json",
    [switch]$SkipAdbRequirement,
    [switch]$SkipAndroidDeviceRequirement,
    [switch]$SkipIosRequirement,
    [switch]$FailIfNotReady
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[runtime_environment_readiness] " + $Message)
}

function Resolve-PathRelativeToRoot {
    param(
        [string]$Root,
        [string]$PathInput
    )
    if ([System.IO.Path]::IsPathRooted($PathInput)) {
        return $PathInput
    }
    return Join-Path $Root $PathInput
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root

$closureScript = Join-Path $root "tools/release/runtime_closure_status.ps1"
if (-not (Test-Path $closureScript)) {
    throw ("runtime_closure_status script not found: " + $closureScript)
}

& powershell -ExecutionPolicy Bypass -File $closureScript `
    -OutputPath $StatusOutputPath `
    -MinWindowsSmokeReports 0 `
    -MinAndroidSmokeLogs 0
if ($LASTEXITCODE -ne 0) {
    throw ("runtime_closure_status failed with exit code {0}" -f $LASTEXITCODE)
}

$resolvedStatusPath = Resolve-PathRelativeToRoot -Root $root -PathInput $StatusOutputPath
if (-not (Test-Path $resolvedStatusPath)) {
    throw ("environment readiness status not found: " + $resolvedStatusPath)
}
$resolvedReportPath = Resolve-PathRelativeToRoot -Root $root -PathInput $ReportOutputPath
$resolvedReportDir = Split-Path -Parent $resolvedReportPath
if ($resolvedReportDir -and -not (Test-Path $resolvedReportDir)) {
    New-Item -ItemType Directory -Path $resolvedReportDir -Force | Out-Null
}

$payload = Get-Content -Raw $resolvedStatusPath | ConvertFrom-Json
$hasAdb = [bool]$payload.environment.adbFound
$hasAndroidDevice = ([int]$payload.environment.onlineAndroidDevices -gt 0)
$hasIosEnvironment = [bool]$payload.environment.iosEnvironmentReady
$requireAdb = -not [bool]$SkipAdbRequirement
$requireAndroidDevice = -not [bool]$SkipAndroidDeviceRequirement
$requireIosEnvironment = -not [bool]$SkipIosRequirement

$failedChecks = [System.Collections.Generic.List[string]]::new()
if ($requireAdb -and -not $hasAdb) {
    $failedChecks.Add("adb_missing")
}
if ($requireAndroidDevice -and -not $hasAndroidDevice) {
    $failedChecks.Add("android_device_missing")
}
if ($requireIosEnvironment -and -not $hasIosEnvironment) {
    $failedChecks.Add("ios_environment_missing")
}

$envReady = ($failedChecks.Count -eq 0)

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    sourceStatusPath = $resolvedStatusPath
    requirements = [ordered]@{
        requireAdb = $requireAdb
        requireAndroidDevice = $requireAndroidDevice
        requireIosEnvironment = $requireIosEnvironment
    }
    environment = [ordered]@{
        adbFound = $hasAdb
        onlineAndroidDevices = [int]$payload.environment.onlineAndroidDevices
        iosEnvironmentReady = $hasIosEnvironment
    }
    ready = $envReady
    failedChecks = @($failedChecks)
}
($report | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 $resolvedReportPath

Write-Step ("adbFound={0}, onlineAndroidDevices={1}, iosEnvironmentReady={2}" -f $payload.environment.adbFound, $payload.environment.onlineAndroidDevices, $payload.environment.iosEnvironmentReady)
Write-Step ("requirements: requireAdb={0}, requireAndroidDevice={1}, requireIosEnvironment={2}" -f $requireAdb, $requireAndroidDevice, $requireIosEnvironment)
Write-Step ("Report written: " + $resolvedReportPath)
if ($envReady) {
    Write-Step "Environment readiness: ready."
} else {
    Write-Step ("Environment readiness: not ready. failedChecks=" + ($failedChecks -join ", "))
}

if ($FailIfNotReady -and -not $envReady) {
    exit 2
}
