param(
    [string[]]$Targets = @("android", "ios", "windows"),
    [ValidateSet("debug", "profile", "release")]
    [string]$Mode = "release",
    [switch]$SkipPubGet,
    [switch]$BuildAab,
    [switch]$NoCodesign,
    [switch]$InstallAndroidApk,
    [switch]$LaunchAndroidAfterInstall,
    [string]$AndroidApplicationId = "com.example.piliplus"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

function Write-Step {
    param([string]$Message)
    Write-Host ("[build_all] " + $Message)
}

function Find-FlutterCommand {
    if (Get-Command fvm -ErrorAction SilentlyContinue) {
        return @("fvm", "flutter")
    }
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        return @("flutter")
    }
    throw "flutter command not found. Install Flutter SDK or FVM first."
}

function Invoke-CommandChecked {
    param(
        [string[]]$Command
    )
    Write-Step ("Run: " + ($Command -join " "))
    & $Command[0] @($Command[1..($Command.Length - 1)])
    if ($LASTEXITCODE -ne 0) {
        throw ("Command failed with exit code {0}: {1}" -f $LASTEXITCODE, ($Command -join " "))
    }
}

function Build-Android {
    param(
        [string[]]$FlutterCommand,
        [string]$BuildMode,
        [switch]$NeedAab,
        [switch]$NeedInstall,
        [switch]$NeedLaunch,
        [string]$RepositoryRoot,
        [string]$ApplicationId
    )
    Write-Step "Building Android APK..."
    Invoke-CommandChecked -Command ($FlutterCommand + @("build", "apk", "--$BuildMode"))
    if ($NeedAab) {
        Write-Step "Building Android App Bundle..."
        Invoke-CommandChecked -Command ($FlutterCommand + @("build", "appbundle", "--$BuildMode"))
    }
    $installedDevices = @()
    if ($NeedInstall) {
        $installedDevices = @(Install-AndroidApk -RepositoryRoot $RepositoryRoot -BuildMode $BuildMode)
    }
    if ($NeedLaunch) {
        if ($installedDevices.Count -eq 0) {
            Write-Step "Skip Android launch: no installed target devices."
        } else {
            foreach ($deviceId in $installedDevices) {
                Start-AndroidApp -RepositoryRoot $RepositoryRoot -DeviceId $deviceId -ApplicationId $ApplicationId
            }
        }
    }
}

function Build-Ios {
    param(
        [string[]]$FlutterCommand,
        [string]$BuildMode,
        [switch]$DisableCodesign
    )
    if (-not $isMacOsHost) {
        Write-Step "Skip iOS build: host is not macOS."
        return
    }
    $args = @("build", "ios", "--$BuildMode")
    if ($DisableCodesign) {
        $args += "--no-codesign"
    }
    Write-Step "Building iOS..."
    Invoke-CommandChecked -Command ($FlutterCommand + $args)
}

function Build-Windows {
    param(
        [string[]]$FlutterCommand,
        [string]$BuildMode
    )
    if (-not $isWindowsHost) {
        Write-Step "Skip Windows build: host is not Windows."
        return
    }
    Write-Step "Building Windows..."
    Invoke-CommandChecked -Command ($FlutterCommand + @("build", "windows", "--$BuildMode"))
}

function Ensure-NuGetCli {
    param(
        [string]$RepositoryRoot
    )
    if (-not $isWindowsHost) {
        return
    }
    $nugetDir = Join-Path $RepositoryRoot "tools/nuget"
    $nugetExe = Join-Path $nugetDir "nuget.exe"
    if (Test-Path $nugetExe) {
        return
    }
    New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
    $downloadUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    Write-Step ("Downloading nuget.exe from " + $downloadUrl)
    Invoke-WebRequest -Uri $downloadUrl -OutFile $nugetExe -UseBasicParsing
    if (-not (Test-Path $nugetExe)) {
        throw "Failed to prepare nuget.exe at $nugetExe"
    }
}

function Find-AdbCommand {
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
            $resolvedValue = $rawValue.Replace('\\', '\')
            $sdkCandidates += $resolvedValue
        }
    }
    $sdkCandidates += (Join-Path $env:LOCALAPPDATA "Android\Sdk")
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

function Get-AndroidApkPath {
    param(
        [string]$RepositoryRoot,
        [string]$BuildMode
    )
    $apkName = switch ($BuildMode) {
        "debug" { "app-debug.apk" }
        "profile" { "app-profile.apk" }
        default { "app-release.apk" }
    }
    return Join-Path $RepositoryRoot ("build\app\outputs\flutter-apk\" + $apkName)
}

function Install-AndroidApk {
    param(
        [string]$RepositoryRoot,
        [string]$BuildMode
    )
    $adb = Find-AdbCommand -RepositoryRoot $RepositoryRoot
    if (-not $adb) {
        Write-Step "Skip Android APK install: adb not found."
        return @()
    }
    $apkPath = Get-AndroidApkPath -RepositoryRoot $RepositoryRoot -BuildMode $BuildMode
    if (-not (Test-Path $apkPath)) {
        Write-Step ("Skip Android APK install: apk not found at " + $apkPath)
        return @()
    }
    Write-Step ("Detect Android devices via: " + $adb)
    $deviceLines = & $adb "devices"
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Skip Android APK install: adb devices failed."
        return @()
    }
    $deviceIds = @()
    foreach ($line in $deviceLines) {
        if ($line -match '^\s*([^\s]+)\s+device\s*$') {
            $deviceIds += $matches[1]
        }
    }
    if ($deviceIds.Count -eq 0) {
        Write-Step "Skip Android APK install: no online Android devices."
        return @()
    }
    foreach ($deviceId in $deviceIds) {
        Write-Step ("Installing APK to device: " + $deviceId)
        & $adb "-s" $deviceId "install" "-r" $apkPath
        if ($LASTEXITCODE -ne 0) {
            throw ("adb install failed for device {0}" -f $deviceId)
        }
    }
    return $deviceIds
}

function Start-AndroidApp {
    param(
        [string]$RepositoryRoot,
        [string]$DeviceId,
        [string]$ApplicationId
    )
    $adb = Find-AdbCommand -RepositoryRoot $RepositoryRoot
    if (-not $adb) {
        Write-Step "Skip Android launch: adb not found."
        return
    }
    Write-Step ("Launching app on {0}: {1}" -f $DeviceId, $ApplicationId)
    & $adb "-s" $DeviceId "shell" "monkey" "-p" $ApplicationId "-c" "android.intent.category.LAUNCHER" "1"
    if ($LASTEXITCODE -ne 0) {
        throw ("adb launch failed for device {0}" -f $DeviceId)
    }
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root
Ensure-NuGetCli -RepositoryRoot $root

$normalizedTargets = @($Targets | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ -ne "" })
if ($normalizedTargets.Count -eq 0) {
    throw "Targets is empty. Use android/ios/windows."
}

$validTargets = @("android", "ios", "windows")
$unknownTargets = @($normalizedTargets | Where-Object { $_ -notin $validTargets })
if ($unknownTargets.Count -gt 0) {
    throw "Unknown targets: $($unknownTargets -join ', '). Valid: $($validTargets -join ', ')"
}

$flutterCommand = Find-FlutterCommand
Write-Step ("Using flutter command: " + ($flutterCommand -join " "))

if (-not $SkipPubGet) {
    Write-Step "Running flutter pub get..."
    Invoke-CommandChecked -Command ($flutterCommand + @("pub", "get"))
}

foreach ($target in $normalizedTargets) {
    switch ($target) {
        "android" {
            Build-Android -FlutterCommand $flutterCommand -BuildMode $Mode -NeedAab:$BuildAab -NeedInstall:$InstallAndroidApk -NeedLaunch:$LaunchAndroidAfterInstall -RepositoryRoot $root -ApplicationId $AndroidApplicationId
        }
        "ios" {
            Build-Ios -FlutterCommand $flutterCommand -BuildMode $Mode -DisableCodesign:$NoCodesign
        }
        "windows" {
            Build-Windows -FlutterCommand $flutterCommand -BuildMode $Mode
        }
        default {
            throw "Unhandled target: $target"
        }
    }
}

Write-Step "Build flow finished."
