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

### iOS: disable codesign for CI-like validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -NoCodesign
```

### Skip dependency restore

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -SkipPubGet
```

## Notes

- On non-macOS hosts, iOS build is skipped with a clear message.
- On non-Windows hosts, Windows build is skipped with a clear message.
- Any failed build command stops the script with non-zero exit.
