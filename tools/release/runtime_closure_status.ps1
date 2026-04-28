param(
    [string]$OutputPath = "build/runtime-smoke/closure-status.json",
    [int]$MinWindowsSmokeReports = 1,
    [int]$MinAndroidSmokeLogs = 1,
    [switch]$FailOnPending
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[runtime_closure_status] " + $Message)
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

function Resolve-AdbCommand {
    param(
        [string]$RepositoryRoot
    )
    $sdkCandidates = @()
    if ($env:ANDROID_SDK_ROOT) { $sdkCandidates += $env:ANDROID_SDK_ROOT }
    if ($env:ANDROID_HOME) { $sdkCandidates += $env:ANDROID_HOME }
    $propertiesCandidates = @(
        (Join-Path $RepositoryRoot "local.properties"),
        (Join-Path $RepositoryRoot "android\local.properties")
    )
    foreach ($propertiesPath in $propertiesCandidates) {
        if (-not (Test-Path $propertiesPath)) {
            continue
        }
        $sdkLine = Get-Content $propertiesPath | Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
        if (-not $sdkLine) {
            continue
        }
        $rawValue = $sdkLine.Substring(8).Trim()
        if ($rawValue) {
            $sdkCandidates += $rawValue.Replace('\\', '\')
        }
    }
    foreach ($sdk in ($sdkCandidates | Where-Object { $_ } | Select-Object -Unique)) {
        $adbExe = Join-Path $sdk "platform-tools\adb.exe"
        if (Test-Path $adbExe) {
            return $adbExe
        }
    }
    $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCommand) {
        return $adbCommand.Source
    }
    return ""
}

$isWindowsHost = if (Get-Variable IsWindows -ErrorAction SilentlyContinue) {
    [bool]$IsWindows
} else {
    ($env:OS -eq "Windows_NT")
}
$isMacOsHost = if (Get-Variable IsMacOS -ErrorAction SilentlyContinue) {
    [bool]$IsMacOS
} else {
    $false
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root

$runtimeSmokeDir = Join-Path $root "build/runtime-smoke"
$artifactDir = Join-Path $root "build/artifacts"

$windowsSmokeReports = @()
if (Test-Path $runtimeSmokeDir) {
    $windowsSmokeReports = @(Get-ChildItem -Path $runtimeSmokeDir -Filter "windows_runtime_smoke_*.json" -File)
}

$androidSmokeLogs = @()
if (Test-Path $runtimeSmokeDir) {
    $androidSmokeLogs = @(Get-ChildItem -Path $runtimeSmokeDir -Filter "*.log" -File)
}

$windowsManifestExists = Test-Path (Join-Path $artifactDir "windows-debug-manifest.json")
$androidManifestExists = Test-Path (Join-Path $artifactDir "android-debug-manifest.json")

$adb = Resolve-AdbCommand -RepositoryRoot $root
$onlineAndroidDevices = 0
if ($adb) {
    $deviceLines = & $adb "devices"
    if ($LASTEXITCODE -eq 0) {
        foreach ($line in $deviceLines) {
            if ($line -match '^\s*([^\s]+)\s+device\s*$') {
                $onlineAndroidDevices += 1
            }
        }
    }
}

$pending = [System.Collections.Generic.List[string]]::new()

$androidRuntimeValidated = $androidSmokeLogs.Count -ge $MinAndroidSmokeLogs
if (-not $androidRuntimeValidated) {
    $pending.Add("android_runtime_validation_pending")
}

$windowsRuntimeValidated = $windowsSmokeReports.Count -ge $MinWindowsSmokeReports
if (-not $windowsRuntimeValidated) {
    $pending.Add("windows_runtime_validation_pending")
}

$iosEnvironmentReady = $isMacOsHost
if (-not $iosEnvironmentReady) {
    $pending.Add("ios_runtime_environment_missing_macos")
}

$androidDeviceReady = $onlineAndroidDevices -gt 0
if (-not $androidDeviceReady) {
    $pending.Add("android_online_device_missing")
}

$status = [ordered]@{
    schemaVersion = 2
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    host = [ordered]@{
        isWindows = $isWindowsHost
        isMacOs = $isMacOsHost
    }
    artifacts = [ordered]@{
        androidDebugManifestExists = $androidManifestExists
        windowsDebugManifestExists = $windowsManifestExists
    }
    runtimeSmoke = [ordered]@{
        windowsReportCount = $windowsSmokeReports.Count
        androidLogCount = $androidSmokeLogs.Count
    }
    criteria = [ordered]@{
        minWindowsSmokeReports = $MinWindowsSmokeReports
        minAndroidSmokeLogs = $MinAndroidSmokeLogs
    }
    environment = [ordered]@{
        adbFound = [bool]($adb)
        onlineAndroidDevices = $onlineAndroidDevices
        iosEnvironmentReady = $iosEnvironmentReady
    }
    closure = [ordered]@{
        androidRuntimeValidated = $androidRuntimeValidated
        windowsRuntimeValidated = $windowsRuntimeValidated
        overallReady = ($androidRuntimeValidated -and $windowsRuntimeValidated -and $iosEnvironmentReady -and $androidDeviceReady)
        pending = @($pending)
    }
}

$resolvedOutputPath = Resolve-PathRelativeToRoot -Root $root -PathInput $OutputPath
$resolvedOutputDir = Split-Path -Parent $resolvedOutputPath
if ($resolvedOutputDir -and -not (Test-Path $resolvedOutputDir)) {
    New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null
}

($status | ConvertTo-Json -Depth 8) | Set-Content -Encoding UTF8 $resolvedOutputPath
Write-Step ("Status written: " + $resolvedOutputPath)

if ($FailOnPending -and $pending.Count -gt 0) {
    Write-Step ("Pending blockers: " + (($pending | Select-Object -Unique) -join ", "))
    exit 2
}
