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

## Notes

- On non-macOS hosts, iOS build is skipped with a clear message.
- On non-Windows hosts, Windows build is skipped with a clear message.
- Any failed build command stops the script with non-zero exit.
- On Windows, script auto-prepares `tools/nuget/nuget.exe` if missing (required by some Windows plugins).
- `-InstallAndroidApk` is best-effort: if `adb` or online devices are not available, script logs skip and still succeeds.
- `adb` discovery sources: `ANDROID_SDK_ROOT`, `ANDROID_HOME`, `local.properties`, `android/local.properties`, then PATH.
- Default launch package is `com.example.piliplus`; override by `-AndroidApplicationId`.
- Set `-ArtifactManifestPath` to export build metadata and artifact file paths in JSON.
