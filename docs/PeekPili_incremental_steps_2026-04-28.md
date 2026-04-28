# PeekPili Migration Incremental Steps (2026-04-28)

This document records the practical migration increments after the initial reverse report and baseline plan.

## Step 7
- Added `T4ConfigRuntimeService` to normalize `currentApiConfigId` against parsed `t4ApiConfigs`.
- Upgraded Source Config page with:
  - parse error display
  - current config dropdown selection
  - current config summary view

## Step 8
- Added `T4ActiveConfigService` for unified active-config resolution:
  - local mode
  - remote fetch mode
  - local fallback mode
- Added `/t4ActiveConfigTest` for active-config diagnostics.

## Step 9
- Added `T4NavigationConfigService`:
  - parse bottom-nav mapping from active config payload
  - preview/apply to `navBarSort` and `defaultHomePage`
- `/t4ActiveConfigTest` now supports preview/apply for bottom navigation.

## Step 10
- Added `t4_nav_auto_apply` key and Source Config switch.
- Added startup auto-apply flow (local snapshot only) to avoid remote fetch blocking.
- Added runtime option to disable remote fetch in auto-apply paths.

## Step 11
- Added `T4HomeTabConfigService`:
  - parse home-tab mapping from active config payload
  - preview/apply to `tabBarSort`
- Extended startup auto-apply to include both:
  - home tabs (`tabBarSort`)
  - bottom nav (`navBarSort` / `defaultHomePage`)

## Step 12
- Source Config `Save` flow now immediately attempts local layout apply when auto-apply switch is enabled.
- Save toast now reports applied/skipped status with reason.

## Step 14
- Re-validated reverse evidence for iOS/Windows with focused low-noise checks:
  - iOS frameworks/plugins confirm Node/JS path signals.
  - iOS unpacked payload has no python/php runtime files by keyword path scan.
  - Windows release includes bundled `nodejs/python/php` runtimes, but no thunder/jar/goproxy-named plugin DLL evidence.
- Updated `PeekPili_reverse_feature_inventory.md` with:
  - focused iOS payload check subsection,
  - refined cross-platform matrix,
  - reverse completion checklist with explicit pending runtime/migration items.

## Step 15
- Replaced Desktop `SourceRuntime` execute stub with real process execution for:
  - `python` (`python -c` or payload-echo mode),
  - `nodejs/catjs` (`node -e` or payload-echo mode),
  - `php` (`php -r` or payload-echo mode).
- Added desktop bundled-runtime path probing for packaged layout:
  - `data/python/python(.exe)`,
  - `data/nodejs/node(.exe)`,
  - `data/php/php(.exe)`,
  with automatic fallback to system command.
- Kept `jar/goproxy` on desktop routed to dedicated pages (`/jarTest`, `/goProxyTest`) instead of generic execute path.

## Step 16
- Replaced Android `sourceRuntimeProbe/sourceRuntimeExecute` pure placeholder return with executable bridge logic in `MainActivity`:
  - supports command resolution + process execution for `python/nodejs/catjs/php`,
  - supports `executeAsCode` mode and default payload-echo mode via base64 transfer,
  - keeps `jar/goproxy` routed to dedicated bridges with explicit guidance message.
- Added Android runtime command resolution strategy:
  - options override (`command`, `commandCandidates`),
  - fallback candidates under app `filesDir/tools/*` and common shell commands.
- Added Android execution safety controls:
  - timeout handling with process kill path,
  - stdout/stderr capture,
  - structured result mapping with success/exitCode/elapsed/error.
- Verified by Android build compile task:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 17
- Replaced Android `loadJar` placeholder implementation with real execution path:
  - uses `DexClassLoader` to load target class from jar/dex artifact,
  - reflects and invokes configured method (`entryClass + methodName`),
  - supports common signatures (`()`, `String`, `String[]`, `List<String>`, all-String positional args).
- Added richer `loadJar` result output:
  - reports resolved jar path, signature used, and return value snapshot.
- Kept explicit boundary:
  - this is reflective method invocation capability,
  - not yet full parity with reverse package `JarLoader` spider lifecycle API.
- Verified by Android build compile task:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 18
- Enhanced Android `loadJar` entry resolution:
  - if `entryClass` is empty, it now attempts to read `MANIFEST.MF -> Main-Class`,
  - supports optional `options.mainClass` override.
- This improves direct execution compatibility for standard runnable jars without forcing manual class entry.
- Verified by Android build compile task:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 19
- Added Android Thunder fallback bridge in `MainActivity`:
  - `thunderIsSupported`
  - `thunderParseMagnet`
  - `thunderGetPlayUrl`
  - `thunderStopTask`
  - `thunderRelease`
- Added Flutter-side `ThunderService` and Source Helper route/page:
  - `/thunderTest` for direct capability probing and URL parse/play-url checks.
- Current boundary remains explicit:
  - this is a lightweight protocol/URL fallback bridge,
  - not yet equivalent to reverse package Thunder SDK behavior.
- Verified by checks:
  - `flutter analyze` on changed Dart files passed,
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 20
- Extended `ThunderService` with cross-platform fallback parser:
  - non-Android now supports local parse/getPlayUrl for `magnet/thunder/ed2k/http/https/ftp`,
  - thunder URL decoding supports `AA...ZZ` unwrap and base64 decode.
- Non-Android `stopTask/release` now return safe no-op success instead of unsupported.
- Verified by check:
  - `flutter analyze` on updated thunder/source-helper files passed.

## Current Outcome
- Config-driven migration has entered executable skeleton phase for both:
  - bottom navigation
  - home tab layout
- Android/iOS/Windows compatibility strategy remains:
  - shared Dart runtime parser + per-platform adapter execution
  - fallback-safe behavior when target capability is not available
- Reverse status is now explicit:
  - static reverse inventory is mostly complete,
  - runtime confirmation + implementation closure are still pending.
- Desktop Source Helper execute path is no longer global stub for Python/Node/PHP.
- Android Source Helper generic bridge is no longer pure placeholder for Python/Node/PHP.
- Android Jar helper no longer file-check stub and now has real reflective invoke capability.
- Android Jar helper now supports `Main-Class` auto-discovery for runnable jars.
- Android now has a callable Thunder fallback bridge and test page.
- Thunder parse/play-url fallback now works on non-Android too (local parser path).
