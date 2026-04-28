# PeekPili Cross-Platform Build

This project now includes a unified build script:

- `tools/release/build_all.ps1`

It can build `android`, `ios`, `windows` in one flow, with host-aware skip behavior.

## Prerequisites

- Flutter SDK available as `flutter`, or FVM available as `fvm`.
- For iOS build: macOS + Xcode toolchain.
- For Windows build: Windows host with Visual Studio C++ desktop toolchain.

## Usage

### Build all targets (default release)

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1
```

### Build selected targets

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android,windows
```

### Android: include App Bundle output

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -BuildAab
```

### Android: build then auto-install APK to connected devices

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -InstallAndroidApk
```

### Android: build, install, and auto-launch app

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -InstallAndroidApk -LaunchAndroidAfterInstall
```

### iOS: disable codesign for CI-like validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -NoCodesign
```

### Skip dependency restore

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -SkipPubGet
```

### Emit artifact manifest (JSON)

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -ArtifactManifestPath build/artifacts/windows-debug-manifest.json
```

### Build and run runtime smoke in one command

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RuntimeSmokeWaitSeconds 2
```

### Build, runtime smoke, and explicit closure status output

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RuntimeClosureStatusPath build/runtime-smoke/windows-closure-status.json
```

### Build and emit reverse completion report in one flow

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -RunRuntimeSmoke -RunReverseCompletionCheck
```

### GitHub Actions runtime smoke (Windows)

- workflow: `.github/workflows/runtime_smoke_windows.yml`
- trigger: `workflow_dispatch`
- outputs: runtime smoke reports + `windows-runtime-closure-status` artifact
- outputs: `windows-reverse-completion-report` artifact (`build/runtime-smoke/reverse-completion-report.md`)
- outputs: `windows-reverse-completion-report-json` artifact (`build/runtime-smoke/reverse-completion-report.json`)
- outputs: `windows-runtime-smoke-summary` artifact (`build/runtime-smoke/summary.md`)
- outputs: `windows-environment-readiness-status` + `windows-environment-readiness-report` artifacts
- optional input: `fail_on_pending=true` enables closure gate failure mode
- optional input: `fail_on_runtime_validation_pending=true` enables runtime-validation-only gate mode
- optional input: `fail_if_environment_not_ready=true` enables environment-readiness gate mode
- optional input: `environment_profile` (`strict|android|ios`) selects environment readiness requirement profile
- optional inputs: `min_windows_smoke_reports` / `min_android_smoke_logs` adjust closure validation thresholds
  - gate is enforced at workflow tail; closure/report artifacts are still uploaded for diagnosis
  - workflow run summary now includes reverse completion `overallReady`, blocker category counts, pending blockers, and next actions

### GitHub Actions runtime smoke (Android)

- workflow: `.github/workflows/runtime_smoke_android.yml`
- trigger: `workflow_dispatch`
- outputs: runtime smoke logs + `android-runtime-closure-status` artifact
- outputs: `android-reverse-completion-report` artifact (`build/runtime-smoke/reverse-completion-report.md`)
- outputs: `android-reverse-completion-report-json` artifact (`build/runtime-smoke/reverse-completion-report.json`)
- outputs: `android-runtime-smoke-summary` artifact (`build/runtime-smoke/summary.md`)
- outputs: `android-environment-readiness-status` + `android-environment-readiness-report` artifacts
- optional input: `fail_on_pending=true` enables closure gate failure mode
- optional input: `fail_on_runtime_validation_pending=true` enables runtime-validation-only gate mode
- optional input: `fail_if_environment_not_ready=true` enables environment-readiness gate mode
- optional input: `environment_profile` (`strict|android|ios`) selects environment readiness requirement profile
- optional inputs: `min_windows_smoke_reports` / `min_android_smoke_logs` adjust closure validation thresholds
  - gate is enforced at workflow tail; closure/report artifacts are still uploaded for diagnosis
  - workflow run summary now includes reverse completion `overallReady`, blocker category counts, pending blockers, and next actions

## Notes

- On non-macOS hosts, iOS build is skipped with a clear message.
- On non-Windows hosts, Windows build is skipped with a clear message.
- Any failed build command stops the script with non-zero exit.
- On Windows, script auto-prepares `tools/nuget/nuget.exe` if missing (required by some Windows plugins).
- `-InstallAndroidApk` is best-effort: if `adb` or online devices are not available, script logs skip and still succeeds.
- `adb` discovery sources: `ANDROID_SDK_ROOT`, `ANDROID_HOME`, `local.properties`, `android/local.properties`, then PATH.
- Default launch package is `com.example.piliplus`; override by `-AndroidApplicationId`.
- Android launch now has fallback package candidates (`base`, `base.debug`, `base.dev`) for better debug/dev suffix compatibility.
- Set `-ArtifactManifestPath` to export build metadata and artifact file paths in JSON.
- Manifest `schemaVersion=2` includes both `artifacts` and `artifactDetails` (`path/sizeBytes/sha256`).
- `-RunRuntimeSmoke` hooks target-specific smoke scripts (`android_runtime_smoke.ps1` / `windows_runtime_smoke.ps1`) into build flow.
- `-RunRuntimeSmoke` now also triggers closure status generation via `tools/release/runtime_closure_status.ps1`.
- Use `-EmitRuntimeClosureStatus` to generate closure status even when runtime smoke is not executed.
- Override closure status path with `-RuntimeClosureStatusPath`.
- `-RunReverseCompletionCheck` invokes `tools/release/reverse_completion_check.ps1` and writes report markdown.
- Use `-ReverseCompletionReportPath` to override report path.
- Use `-ReverseCompletionJsonReportPath` to override JSON report path.
- Use `-StrictReverseCompletion` to fail build flow when closure is still incomplete.
- Use `-StrictReverseCompletionRuntimeOnly` to fail only when `runtime_validation` blockers remain.
- Use `-ReverseMinWindowsSmokeReports` and `-ReverseMinAndroidSmokeLogs` to adjust reverse-check validation thresholds in build flow.
- When `-ArtifactManifestPath` is enabled, closure/reverse-check outputs are also included in manifest artifact details.

## Runtime Smoke

Android runtime smoke helper:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/android_runtime_smoke.ps1 -ApkPath build/app/outputs/flutter-apk/app-debug.apk
```

Behavior:
- If no online device is connected, script prints skip and exits successfully.
- If device exists, script performs install + launch + logcat capture.
- Launch step now auto-tries package candidates (`base`, `base.debug`, `base.dev`) based on APK mode.

Windows runtime smoke helper:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/windows_runtime_smoke.ps1 -ExePath build/windows/x64/runner/Debug/piliplus.exe
```

Behavior:
- Starts built app process, waits, writes JSON report, and stops process by default.
- Use `-LeaveRunning` to keep process alive after smoke check.

Runtime smoke summary helper:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1
```

Summary now includes reverse completion snapshot (overallReady + blocker counts + pending blockers) when JSON report exists.
Summary now also includes environment readiness snapshots when `*environment-readiness-report.json` files exist.

Runtime closure status snapshot:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1
```

Closure status gating example (fail when blockers remain):

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1 -FailOnPending
```

Runtime environment readiness check:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1
```

Optional readiness profiles:
- Android-focused (ignore iOS requirement):
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1 -SkipIosRequirement`
- iOS-focused (ignore Android/adb requirements):
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1 -SkipAdbRequirement -SkipAndroidDeviceRequirement`
- Strict fail on unmet requirements:
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1 -FailIfNotReady`

One-command reverse completion check:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1
```

The generated report includes:
- completion decision (`Overall ready`)
- pending blockers
- actionable next-step suggestions derived from blocker codes
- machine-readable JSON output (`build/runtime-smoke/reverse-completion-report.json`)
- blocker category counts (`environment` vs `runtime_validation`)
- absolute + repo-relative artifact path fields for automation portability
