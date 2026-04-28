param(
    [string]$ApkPath = "build/app/outputs/flutter-apk/app-debug.apk",
    [string]$ApplicationId = "com.example.piliplus",
    [int]$LaunchWaitSeconds = 8,
    [string]$OutputDir = "build/runtime-smoke"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[android_runtime_smoke] " + $Message)
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
        $adbBin = Join-Path $sdk "platform-tools\adb"
        if (Test-Path $adbExe) {
            return $adbExe
        }
        if (Test-Path $adbBin) {
            return $adbBin
        }
    }
    $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCommand) {
        return $adbCommand.Source
    }
    return ""
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root

$adb = Resolve-AdbCommand -RepositoryRoot $root
if (-not $adb) {
    Write-Step "Skip: adb not found."
    exit 0
}

$resolvedApkPath = if ([System.IO.Path]::IsPathRooted($ApkPath)) { $ApkPath } else { Join-Path $root $ApkPath }
if (-not (Test-Path $resolvedApkPath)) {
    throw ("APK not found: " + $resolvedApkPath)
}

$deviceLines = & $adb "devices"
if ($LASTEXITCODE -ne 0) {
    throw "adb devices failed."
}
$deviceIds = @()
foreach ($line in $deviceLines) {
    if ($line -match '^\s*([^\s]+)\s+device\s*$') {
        $deviceIds += $matches[1]
    }
}
if ($deviceIds.Count -eq 0) {
    Write-Step "Skip: no online Android devices."
    exit 0
}

$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $root $OutputDir }
New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null

foreach ($deviceId in $deviceIds) {
    Write-Step ("Installing APK on device: " + $deviceId)
    & $adb "-s" $deviceId "install" "-r" $resolvedApkPath
    if ($LASTEXITCODE -ne 0) {
        throw ("adb install failed: " + $deviceId)
    }

    Write-Step ("Clearing logcat on device: " + $deviceId)
    & $adb "-s" $deviceId "logcat" "-c"
    if ($LASTEXITCODE -ne 0) {
        throw ("adb logcat -c failed: " + $deviceId)
    }

    Write-Step ("Launching app on device: " + $deviceId)
    & $adb "-s" $deviceId "shell" "monkey" "-p" $ApplicationId "-c" "android.intent.category.LAUNCHER" "1"
    if ($LASTEXITCODE -ne 0) {
        throw ("adb launch failed: " + $deviceId)
    }

    Start-Sleep -Seconds $LaunchWaitSeconds

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $outputFile = Join-Path $resolvedOutputDir ("{0}_{1}.log" -f $deviceId, $timestamp)
    Write-Step ("Collecting logcat to: " + $outputFile)
    & $adb "-s" $deviceId "logcat" "-d" | Set-Content -Encoding UTF8 $outputFile
    if ($LASTEXITCODE -ne 0) {
        throw ("adb logcat -d failed: " + $deviceId)
    }
}

Write-Step "Runtime smoke flow finished."
