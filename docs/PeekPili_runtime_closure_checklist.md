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

Current closure status snapshot:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1
```

Closure gate mode (non-zero exit if pending blockers exist):

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1 -FailOnPending
```

CI artifact snapshots:
- Windows workflow uploads `windows-runtime-closure-status`.
- Android workflow uploads `android-runtime-closure-status`.
- Both workflows support `fail_on_pending=true` to fail run when blockers remain.
