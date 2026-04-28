param(
    [string[]]$Targets = @("android", "ios", "windows"),
    [ValidateSet("debug", "profile", "release")]
    [string]$Mode = "release",
    [switch]$SkipPubGet,
    [switch]$BuildAab,
    [switch]$NoCodesign
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
        [switch]$NeedAab
    )
    Write-Step "Building Android APK..."
    Invoke-CommandChecked -Command ($FlutterCommand + @("build", "apk", "--$BuildMode"))
    if ($NeedAab) {
        Write-Step "Building Android App Bundle..."
        Invoke-CommandChecked -Command ($FlutterCommand + @("build", "appbundle", "--$BuildMode"))
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
            Build-Android -FlutterCommand $flutterCommand -BuildMode $Mode -NeedAab:$BuildAab
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
