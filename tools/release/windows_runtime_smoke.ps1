param(
    [string]$ExePath = "build/windows/x64/runner/Debug/piliplus.exe",
    [int]$LaunchWaitSeconds = 8,
    [string]$OutputDir = "build/runtime-smoke",
    [switch]$LeaveRunning
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[windows_runtime_smoke] " + $Message)
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root

$resolvedExePath = if ([System.IO.Path]::IsPathRooted($ExePath)) {
    $ExePath
} else {
    Join-Path $root $ExePath
}
if (-not (Test-Path $resolvedExePath)) {
    throw ("Windows executable not found: " + $resolvedExePath)
}

$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir
} else {
    Join-Path $root $OutputDir
}
New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null

$startedAt = Get-Date
Write-Step ("Launching: " + $resolvedExePath)
$process = Start-Process -FilePath $resolvedExePath -WorkingDirectory (Split-Path -Parent $resolvedExePath) -WindowStyle Hidden -PassThru
Start-Sleep -Seconds $LaunchWaitSeconds

$isAlive = -not $process.HasExited
$exitCode = $null
if (-not $isAlive) {
    $exitCode = $process.ExitCode
}

$stoppedByScript = $false
if ($isAlive -and -not $LeaveRunning) {
    Write-Step ("Stopping process: " + $process.Id)
    Stop-Process -Id $process.Id -Force
    $stoppedByScript = $true
}

$report = [ordered]@{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    exePath = $resolvedExePath
    launchWaitSeconds = $LaunchWaitSeconds
    processId = $process.Id
    startedAtLocal = $startedAt.ToString("o")
    aliveAfterWait = $isAlive
    exitCodeAfterWait = $exitCode
    stoppedByScript = $stoppedByScript
}

$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$reportFile = Join-Path $resolvedOutputDir ("windows_runtime_smoke_{0}.json" -f $timestamp)
($report | ConvertTo-Json -Depth 4) | Set-Content -Encoding UTF8 $reportFile

Write-Step ("Report written: " + $reportFile)
Write-Step "Runtime smoke flow finished."
