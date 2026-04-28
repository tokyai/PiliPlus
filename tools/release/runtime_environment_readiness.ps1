param(
    [string]$StatusOutputPath = "build/runtime-smoke/environment-readiness-status.json",
    [switch]$FailIfNotReady
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[runtime_environment_readiness] " + $Message)
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

$resolvedStatusPath = if ([System.IO.Path]::IsPathRooted($StatusOutputPath)) {
    $StatusOutputPath
} else {
    Join-Path $root $StatusOutputPath
}
if (-not (Test-Path $resolvedStatusPath)) {
    throw ("environment readiness status not found: " + $resolvedStatusPath)
}

$payload = Get-Content -Raw $resolvedStatusPath | ConvertFrom-Json
$envReady = [bool]$payload.environment.iosEnvironmentReady -and ([int]$payload.environment.onlineAndroidDevices -gt 0) -and [bool]$payload.environment.adbFound

Write-Step ("adbFound={0}, onlineAndroidDevices={1}, iosEnvironmentReady={2}" -f $payload.environment.adbFound, $payload.environment.onlineAndroidDevices, $payload.environment.iosEnvironmentReady)
if ($envReady) {
    Write-Step "Environment readiness: ready."
} else {
    Write-Step "Environment readiness: not ready."
}

if ($FailIfNotReady -and -not $envReady) {
    exit 2
}
