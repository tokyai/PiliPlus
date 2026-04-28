param(
    [string]$SummaryPath = "build/runtime-smoke/summary.md",
    [string]$StatusPath = "build/runtime-smoke/closure-status.json",
    [string]$ReportPath = "build/runtime-smoke/reverse-completion-report.md",
    [string]$JsonReportPath = "build/runtime-smoke/reverse-completion-report.json",
    [int]$SummaryMaxItems = 10,
    [int]$MinWindowsSmokeReports = 1,
    [int]$MinAndroidSmokeLogs = 1,
    [switch]$SkipSummary,
    [switch]$SkipStatus,
    [switch]$Strict,
    [switch]$StrictRuntimeValidationOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[reverse_completion_check] " + $Message)
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

function Convert-ToRelativePath {
    param(
        [string]$Root,
        [string]$AbsolutePath
    )
    $normalizedRoot = [System.IO.Path]::GetFullPath($Root)
    if (-not $normalizedRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
        $normalizedRoot += [System.IO.Path]::DirectorySeparatorChar
    }
    $normalizedPath = [System.IO.Path]::GetFullPath($AbsolutePath)
    $rootUri = [System.Uri]$normalizedRoot
    $pathUri = [System.Uri]$normalizedPath
    $relativeUri = $rootUri.MakeRelativeUri($pathUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('\', '/')
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\")
Set-Location $root

$resolvedSummaryPath = Resolve-PathRelativeToRoot -Root $root -PathInput $SummaryPath
$resolvedStatusPath = Resolve-PathRelativeToRoot -Root $root -PathInput $StatusPath
$resolvedReportPath = Resolve-PathRelativeToRoot -Root $root -PathInput $ReportPath
$resolvedJsonReportPath = Resolve-PathRelativeToRoot -Root $root -PathInput $JsonReportPath

$summaryScript = Join-Path $root "tools/release/runtime_smoke_summary.ps1"
$statusScript = Join-Path $root "tools/release/runtime_closure_status.ps1"

if (-not $SkipSummary) {
    if (-not (Test-Path $summaryScript)) {
        throw ("runtime_smoke_summary script not found: " + $summaryScript)
    }
    & powershell -ExecutionPolicy Bypass -File $summaryScript -OutputPath $resolvedSummaryPath -MaxItems $SummaryMaxItems
    if ($LASTEXITCODE -ne 0) {
        throw ("runtime_smoke_summary failed with exit code {0}" -f $LASTEXITCODE)
    }
}

if (-not $SkipStatus) {
    if (-not (Test-Path $statusScript)) {
        throw ("runtime_closure_status script not found: " + $statusScript)
    }
    & powershell -ExecutionPolicy Bypass -File $statusScript -OutputPath $resolvedStatusPath -MinWindowsSmokeReports $MinWindowsSmokeReports -MinAndroidSmokeLogs $MinAndroidSmokeLogs
    if ($LASTEXITCODE -ne 0) {
        throw ("runtime_closure_status failed with exit code {0}" -f $LASTEXITCODE)
    }
}

if (-not (Test-Path $resolvedStatusPath)) {
    throw ("closure status file not found: " + $resolvedStatusPath)
}

$status = Get-Content -Raw $resolvedStatusPath | ConvertFrom-Json
$overallReady = [bool]$status.closure.overallReady
$pending = @()
if ($status.closure.pending) {
    $pending = @($status.closure.pending)
}
$pendingActionMap = @{
    "android_runtime_validation_pending"   = "Connect an online Android device or emulator, then run: powershell -ExecutionPolicy Bypass -File tools/release/android_runtime_smoke.ps1 -ApkPath build/app/outputs/flutter-apk/app-debug.apk"
    "android_online_device_missing"        = "Ensure adb reports at least one online device (adb devices) before running runtime smoke."
    "ios_runtime_environment_missing_macos" = "Run iOS runtime validation on macOS host and execute iOS-targeted build/smoke checks."
    "windows_runtime_validation_pending"   = "Run Windows runtime smoke: powershell -ExecutionPolicy Bypass -File tools/release/windows_runtime_smoke.ps1 -ExePath build/windows/x64/runner/Debug/piliplus.exe"
}
$pendingCategoryMap = @{
    "android_runtime_validation_pending"    = "runtime_validation"
    "windows_runtime_validation_pending"    = "runtime_validation"
    "android_online_device_missing"         = "environment"
    "ios_runtime_environment_missing_macos" = "environment"
}
$nextActions = [System.Collections.Generic.List[string]]::new()
foreach ($item in $pending) {
    if ($pendingActionMap.ContainsKey($item)) {
        $nextActions.Add($pendingActionMap[$item])
    }
}
$nextActions = @($nextActions | Select-Object -Unique)
$pendingWithCategory = [System.Collections.Generic.List[object]]::new()
foreach ($item in $pending) {
    $category = "unknown"
    if ($pendingCategoryMap.ContainsKey($item)) {
        $category = $pendingCategoryMap[$item]
    }
    $pendingWithCategory.Add([ordered]@{
        code = $item
        category = $category
    })
}
$environmentPendingCount = @($pendingWithCategory | Where-Object { $_.category -eq "environment" }).Count
$runtimeValidationPendingCount = @($pendingWithCategory | Where-Object { $_.category -eq "runtime_validation" }).Count

$reportLines = [System.Collections.Generic.List[string]]::new()
$reportLines.Add("# Reverse Completion Check")
$reportLines.Add("")
$reportLines.Add(("Generated at: {0}" -f ((Get-Date).ToUniversalTime().ToString("o"))))
$reportLines.Add(("Overall ready: {0}" -f $overallReady))
$reportLines.Add(("Summary path: {0}" -f $resolvedSummaryPath))
$reportLines.Add(("Status path: {0}" -f $resolvedStatusPath))
$reportLines.Add("")
$reportLines.Add("## Blocker Categories")
$reportLines.Add(("- environment: {0}" -f $environmentPendingCount))
$reportLines.Add(("- runtime_validation: {0}" -f $runtimeValidationPendingCount))
$reportLines.Add("")
$reportLines.Add("## Pending Blockers")
if ($pending.Count -eq 0) {
    $reportLines.Add("- none")
} else {
    foreach ($item in $pendingWithCategory) {
        $reportLines.Add(("- {0} ({1})" -f $item.code, $item.category))
    }
}
$reportLines.Add("")
$reportLines.Add("## Next Actions")
if ($nextActions.Count -eq 0) {
    $reportLines.Add("- none")
} else {
    foreach ($item in $nextActions) {
        $reportLines.Add(("- " + $item))
    }
}

$reportDir = Split-Path -Parent $resolvedReportPath
if ($reportDir -and -not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}
$reportLines | Set-Content -Encoding UTF8 $resolvedReportPath

$jsonReportDir = Split-Path -Parent $resolvedJsonReportPath
if ($jsonReportDir -and -not (Test-Path $jsonReportDir)) {
    New-Item -ItemType Directory -Path $jsonReportDir -Force | Out-Null
}
$jsonPayload = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    overallReady = $overallReady
    summaryPath = $resolvedSummaryPath
    summaryPathRelative = (Convert-ToRelativePath -Root $root -AbsolutePath $resolvedSummaryPath)
    statusPath = $resolvedStatusPath
    statusPathRelative = (Convert-ToRelativePath -Root $root -AbsolutePath $resolvedStatusPath)
    markdownReportPath = $resolvedReportPath
    markdownReportPathRelative = (Convert-ToRelativePath -Root $root -AbsolutePath $resolvedReportPath)
    jsonReportPath = $resolvedJsonReportPath
    jsonReportPathRelative = (Convert-ToRelativePath -Root $root -AbsolutePath $resolvedJsonReportPath)
    pending = @($pending)
    pendingWithCategory = @($pendingWithCategory)
    blockerCounts = [ordered]@{
        environment = $environmentPendingCount
        runtimeValidation = $runtimeValidationPendingCount
    }
    strictEvaluation = [ordered]@{
        strict = [bool]$Strict
        strictRuntimeValidationOnly = [bool]$StrictRuntimeValidationOnly
    }
    nextActions = @($nextActions)
}
($jsonPayload | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 $resolvedJsonReportPath

Write-Step ("Report written: " + $resolvedReportPath)
Write-Step ("JSON report written: " + $resolvedJsonReportPath)
if ($overallReady) {
    Write-Step "Reverse runtime closure status: complete."
} else {
    Write-Step ("Reverse runtime closure status: incomplete. Pending blockers: " + ($pending -join ", "))
    foreach ($item in $nextActions) {
        Write-Step ("Suggested action: " + $item)
    }
}

if ($Strict -and -not $overallReady) {
    exit 2
}

if ($StrictRuntimeValidationOnly -and $runtimeValidationPendingCount -gt 0) {
    exit 3
}
