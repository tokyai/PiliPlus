# PeekPili Runtime Closure Checklist

This checklist defines the remaining validation work to close migration-grade reverse confidence.

## 1) Android Runtime Equivalence

Suggested automation entry:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/android_runtime_smoke.ps1 -ApkPath build/app/outputs/flutter-apk/app-debug.apk
```

### GoProxy
- Verify staged stop strategy under real workloads:
  - start proxy with real source config
  - trigger repeated start/stop cycles
  - confirm `lastStopStrategy` converges and process is not orphaned
- Validate long-run stability:
  - run for at least 30 minutes under traffic
  - confirm no stale `running=true` drift after forced exits

### Jar
- Validate real source jars (not only synthetic test jars):
  - lifecycle (`destroy/release/close`) side-effects
  - business APIs (`home/search/detail/player/action/setRecent`)
  - context init hooks (`init/initialize/setContext`) compatibility

### PHP
- Validate production-like scripts:
  - install variants (`tar.gz/tgz/zip/gzip`)
  - multi-instance server start/stop churn
  - script side-effects and runtime env correctness

### Thunder
- Validate task lifecycle under real links:
  - magnet/ed2k/thunder family links
  - stop/release behavior with multiple concurrent tasks
  - playback/streaming expectation gap vs real Thunder SDK behavior

## 2) iOS Runtime Confirmation

- Confirm `/pythonTest` and related routes are fallback/proxy-only in runtime behavior.
- Confirm no hidden local python/php runtime execution path behind UI routes.

## 3) Windows Runtime Confirmation

Suggested automation entry:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/windows_runtime_smoke.ps1 -ExePath build/windows/x64/runner/Debug/piliplus.exe
```

Unified flow alternative:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke
```

Unified flow can also set explicit closure output path:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RuntimeClosureStatusPath build/runtime-smoke/windows-closure-status.json
```

Unified flow can also emit reverse completion report directly:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RunReverseCompletionCheck
```

Optional custom JSON output path:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RunReverseCompletionCheck -ReverseCompletionJsonReportPath build/runtime-smoke/windows-reverse-completion.json
```

Runtime-validation-only strict gate example:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RunReverseCompletionCheck -StrictReverseCompletionRuntimeOnly
```

Threshold override example:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RunReverseCompletionCheck -ReverseMinWindowsSmokeReports 1 -ReverseMinAndroidSmokeLogs 1
```

- Confirm thunder markers are UI-only and not backed by hidden local runtime bridge.
- Confirm current migration behavior is consistent with packaged app expectations.

## 4) Cross-Platform Packaging Validation

Use:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android,windows
```

On macOS for iOS:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -NoCodesign
```

Acceptance:
- target build exits successfully
- generated artifacts install and launch
- Source Helper core test pages (`jar/php/thunder/goProxy`) can open and return expected runtime state.

Optional smoke summary:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1
```

Summary output now includes reverse completion snapshot when `reverse-completion-report.json` is available.

Current closure status snapshot:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1
```

Closure gate mode (non-zero exit if pending blockers exist):

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1 -FailOnPending
```

One-command closure check report:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1
```

Report output now includes blocker-oriented next-action suggestions.
Report output also includes machine-readable JSON (`reverse-completion-report.json`).
Blockers are now categorized (`environment` / `runtime_validation`) for triage.

CI artifact snapshots:
- Windows workflow uploads `windows-runtime-closure-status`.
- Android workflow uploads `android-runtime-closure-status`.
- Windows workflow uploads `windows-reverse-completion-report`.
- Android workflow uploads `android-reverse-completion-report`.
- Windows workflow uploads `windows-reverse-completion-report-json`.
- Android workflow uploads `android-reverse-completion-report-json`.
- Windows workflow uploads `windows-runtime-smoke-summary`.
- Android workflow uploads `android-runtime-smoke-summary`.
- Both workflows support `fail_on_pending=true` to fail run when blockers remain.
- Both workflows support `fail_on_runtime_validation_pending=true` to fail only on runtime-validation blockers.
- Gate failure is deferred to final step so closure/report artifacts remain available for troubleshooting.
- Workflow job summary also shows reverse completion `overallReady`, blocker category counts, and pending blocker list.
- Unified build manifest (`-ArtifactManifestPath`) now also captures closure/reverse-check report artifacts when those steps are enabled.
