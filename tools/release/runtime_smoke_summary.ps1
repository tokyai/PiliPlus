param(
    [string]$RuntimeSmokeDir = "build/runtime-smoke",
    [string]$ArtifactsDir = "build/artifacts",
    [string]$OutputPath = "build/runtime-smoke/summary.md",
    [int]$MaxItems = 10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ("[runtime_smoke_summary] " + $Message)
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

$resolvedRuntimeSmokeDir = Resolve-PathRelativeToRoot -Root $root -PathInput $RuntimeSmokeDir
$resolvedArtifactsDir = Resolve-PathRelativeToRoot -Root $root -PathInput $ArtifactsDir
$resolvedOutputPath = Resolve-PathRelativeToRoot -Root $root -PathInput $OutputPath
$resolvedOutputDir = Split-Path -Parent $resolvedOutputPath
if ($resolvedOutputDir -and -not (Test-Path $resolvedOutputDir)) {
    New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Runtime Smoke Summary")
$lines.Add("")
$lines.Add(("Generated at: {0}" -f ((Get-Date).ToUniversalTime().ToString("o"))))
$lines.Add("")

$lines.Add("## Runtime Smoke Reports")
if (Test-Path $resolvedRuntimeSmokeDir) {
    $jsonReports = @(Get-ChildItem -Path $resolvedRuntimeSmokeDir -Filter *.json -File | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxItems)
    if ($jsonReports.Count -eq 0) {
        $lines.Add("- No JSON runtime smoke reports found.")
    } else {
        foreach ($reportFile in $jsonReports) {
            $lines.Add(("### {0}" -f $reportFile.Name))
            try {
                $payload = Get-Content -Raw $reportFile.FullName | ConvertFrom-Json
                foreach ($prop in $payload.PSObject.Properties) {
                    $lines.Add(("- {0}: {1}" -f $prop.Name, $prop.Value))
                }
            } catch {
                $lines.Add("- parseError: failed to parse json content")
            }
            $lines.Add("")
        }
    }
} else {
    $lines.Add("- Runtime smoke directory not found.")
}
$lines.Add("")

$lines.Add("## Reverse Completion Snapshot")
$reverseCompletionJsonPath = Join-Path $resolvedRuntimeSmokeDir "reverse-completion-report.json"
if (Test-Path $reverseCompletionJsonPath) {
    try {
        $reversePayload = Get-Content -Raw $reverseCompletionJsonPath | ConvertFrom-Json -ErrorAction Stop
        $lines.Add(("- overallReady: {0}" -f $reversePayload.overallReady))
        if ($reversePayload.blockerCounts) {
            $lines.Add(("- blockerCounts.environment: {0}" -f $reversePayload.blockerCounts.environment))
            $lines.Add(("- blockerCounts.runtimeValidation: {0}" -f $reversePayload.blockerCounts.runtimeValidation))
        }
        if ($reversePayload.pending -and $reversePayload.pending.Count -gt 0) {
            $lines.Add("- pending blockers:")
            foreach ($item in $reversePayload.pending) {
                $lines.Add(("  - {0}" -f $item))
            }
        } else {
            $lines.Add("- pending blockers: none")
        }
    } catch {
        $lines.Add(("- parseError: {0}" -f $_.Exception.Message))
    }
} else {
    $lines.Add("- reverse-completion-report.json not found.")
}
$lines.Add("")

$lines.Add("## Environment Readiness Snapshots")
if (Test-Path $resolvedRuntimeSmokeDir) {
    $readinessReports = @(Get-ChildItem -Path $resolvedRuntimeSmokeDir -Filter "*environment-readiness-report.json" -File | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxItems)
    if ($readinessReports.Count -eq 0) {
        $lines.Add("- No environment readiness reports found.")
    } else {
        foreach ($reportFile in $readinessReports) {
            $lines.Add(("### {0}" -f $reportFile.Name))
            try {
                $payload = Get-Content -Raw $reportFile.FullName | ConvertFrom-Json -ErrorAction Stop
                $lines.Add(("- ready: {0}" -f $payload.ready))
                if ($payload.requirements) {
                    $lines.Add(("- requirements: adb={0}, androidDevice={1}, ios={2}" -f $payload.requirements.requireAdb, $payload.requirements.requireAndroidDevice, $payload.requirements.requireIosEnvironment))
                }
                if ($payload.failedChecks -and $payload.failedChecks.Count -gt 0) {
                    $lines.Add("- failedChecks:")
                    foreach ($item in $payload.failedChecks) {
                        $lines.Add(("  - {0}" -f $item))
                    }
                } else {
                    $lines.Add("- failedChecks: none")
                }
            } catch {
                $lines.Add(("- parseError: {0}" -f $_.Exception.Message))
            }
            $lines.Add("")
        }
    }
} else {
    $lines.Add("- Runtime smoke directory not found.")
}
$lines.Add("")

$lines.Add("## Artifact Manifests")
if (Test-Path $resolvedArtifactsDir) {
    $manifestFiles = @(Get-ChildItem -Path $resolvedArtifactsDir -Filter *.json -File | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxItems)
    if ($manifestFiles.Count -eq 0) {
        $lines.Add("- No artifact manifest JSON files found.")
    } else {
        foreach ($manifestFile in $manifestFiles) {
            $lines.Add(("### {0}" -f $manifestFile.Name))
            try {
                $manifestRaw = Get-Content -Raw $manifestFile.FullName
                $manifest = $manifestRaw | ConvertFrom-Json -ErrorAction Stop
                $lines.Add(("- generatedAtUtc: {0}" -f $manifest.generatedAtUtc))
                $lines.Add(("- mode: {0}" -f $manifest.mode))
                $lines.Add(("- targets: {0}" -f ($manifest.targets -join ", ")))
                $hasArtifactDetails = $null -ne $manifest.PSObject.Properties["artifactDetails"]
                $hasArtifacts = $null -ne $manifest.PSObject.Properties["artifacts"]
                if ($hasArtifactDetails -and $manifest.artifactDetails) {
                    foreach ($item in $manifest.artifactDetails) {
                        $lines.Add(("- artifact: {0}" -f $item.path))
                        $lines.Add(("  - sizeBytes: {0}" -f $item.sizeBytes))
                        $lines.Add(("  - sha256: {0}" -f $item.sha256))
                    }
                } elseif ($hasArtifacts -and $manifest.artifacts) {
                    foreach ($path in $manifest.artifacts) {
                        $lines.Add(("- artifact: {0}" -f $path))
                    }
                }
            } catch {
                $lines.Add(("- parseError: {0}" -f $_.Exception.Message))
            }
            $lines.Add("")
        }
    }
} else {
    $lines.Add("- Artifact directory not found.")
}

$lines | Set-Content -Encoding UTF8 $resolvedOutputPath
Write-Step ("Summary written: " + $resolvedOutputPath)
