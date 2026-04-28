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

## Step 21
- Added `Execute As Code` toggle to `SourceHelperToolPage`:
  - Off: payload echo mode (safe runtime availability probe),
  - On: direct code execution path for Python/Node/PHP adapters.
- `sourceRuntimeExecute` now receives `options.executeAsCode` from UI for practical migration debugging.
- Verified by check:
  - `flutter analyze lib/pages/source_helper/view.dart` passed.

## Step 22
- Wired Android `loadJar` advanced options from Flutter layer:
  - `mainClass` override
  - `staticOnly` method filter
- Extended `/jarTest` page inputs:
  - optional `Main Class` field,
  - `Static Method Only` switch.
- Verified by check:
  - `flutter analyze` on updated jar/source-helper files passed.

## Step 23
- Added Android Jar lifecycle baseline bridge methods in `MainActivity`:
  - `destroySpider`
  - `markSpiderCrashed`
  - `isSpiderCrashed`
  - `getCrashedSpiderCount`
  - `clearCrashedSpiders`
  - `clearAll`
- `loadJar` successful invoke now registers runtime spider state for lifecycle operations (key + jar path identity).
- Extended Flutter `JarLoaderService` with typed lifecycle APIs and Android bridge calls for the same method surface.
- Extended `/jarTest` page with lifecycle controls and result cards:
  - mark/is/destroy
  - crashed count
  - clear crashed / clear all
- Verified by checks:
  - `flutter analyze` on updated jar/source-helper files passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 24
- Added Android Jar spider business method baseline in `MainActivity`:
  - `homeContent`
  - `homeVideoContent`
  - `categoryContent`
  - `searchContent`
  - `detailContent`
  - `playerContent`
  - `action`
  - `setRecent`
- Added reflective business-method invoke path:
  - resolves runtime by `key + jar` identity (or `entryClass + jarPath` fallback),
  - supports common primitive/list/map argument conversion for reverse spider method signatures.
- `clearAll` now also clears local `setRecent` state cache.
- Extended Flutter `JarLoaderService` with typed wrappers for the above business methods.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/jar_loader_service.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 25
- Upgraded Android Thunder fallback bridge to include task lifecycle state:
  - `thunderGetPlayUrl` now allocates/tracks `taskId`,
  - `thunderStopTask` now validates/removes task by id,
  - `thunderRelease` now clears tracked tasks,
  - support info fields: `taskId` / `activeTaskCount`.
- Extended Flutter `ThunderService` models and fallback behavior:
  - `ThunderPlayUrlResult` now exposes `taskId` and `activeTaskCount`,
  - `ThunderStatusResult` now exposes `taskId` and `activeTaskCount`,
  - non-Android fallback now tracks tasks for `getPlayUrl/stopTask/release`.
- Extended `/thunderTest` cards to display `taskId` and active task count for debugging.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 26
- Extended `/jarTest` with `Spider API Quick Call` debug section:
  - selectable method: `homeContent/homeVideoContent/categoryContent/searchContent/detailContent/playerContent/action`,
  - JSON payload input for runtime arguments,
  - direct invoke via `JarLoaderService` business wrappers,
  - result card for `message/error/data` and copy-data action.
- This provides an in-app runtime harness for validating reflective Jar spider business API migration behavior.
- Verified by check:
  - `flutter analyze lib/pages/source_helper/view.dart` passed.

## Step 27
- Added Source Helper `PHP Test` entry (`/phpTest`) in:
  - Source Helper menu page
  - router page map
- `PHP Test` reuses `SourceHelperToolPage` + `SourceEngine.php`, so Android/desktop PHP runtime probing and execute-as-code paths are now directly accessible in debug UI.
- Verified by check:
  - `flutter analyze lib/pages/source_helper/view.dart lib/router/app_pages.dart` passed.

## Step 28
- Improved Android Jar spider runtime consistency for business API calls:
  - added per-`key+jar` cached execution context (`DexClassLoader + loaded class + lazy instance`),
  - business API invoke now reuses cached spider instance for non-static methods,
  - `destroySpider`/`clearAll` now also clear cached execution contexts,
  - reloading a spider identity now resets stale cached context.
- This reduces behavior drift caused by creating a new spider object on every call.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 29
- Added Android PHP bridge baseline method surface in `MainActivity` (reverse plugin-aligned names):
  - `startServer` / `stopServer` / `isServerRunning` / `getServerPort`
  - `installPhp` / `isInstalled` / `getVersion` / `getExtensions`
  - `getScriptsDir` / `getPhpDir` / `executeCode`
  - `getDefaultDownloadUrl`
- Added Flutter-side `PhpBridgeService` with typed models:
  - `PhpServerStatus`
  - `PhpCommandResult`
  - `PhpExecutionResult`
- Added Source Helper diagnostics:
  - new route tile `/phpBridgeTest`
  - new page `PHP Bridge Test` for install/probe/start/stop/extensions/execute workflows.
- Registered service in app bootstrap (`Get.lazyPut(PhpBridgeService.new)`).
- Verified by checks:
  - `flutter analyze` on updated Dart files passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 30
- Upgraded Android PHP bridge install/runtime baseline closer to reverse plugin behavior:
  - runtime root now converges to `files/php` with executable target `files/php/php`,
  - `installPhp` now supports download + archive extraction (`tar -xzf` with gzip fallback) before asset fallback,
  - runtime environment variables are now injected for PHP process launches (`PHPRC`, `PHP_INI_SCAN_DIR`, `HOME`, `TMPDIR`, `LD_LIBRARY_PATH`),
  - `getScriptsDir` now prefers external `/storage/emulated/0/peekpili/php-scripts` with internal fallback,
  - PHP script bootstrap now auto-copies `assets/php/scripts/*.php` and ensures `index.php`,
  - default server instance count moved to `4` for reverse-aligned startup baseline.
- Updated Flutter side defaults for PHP bridge diagnostics:
  - `PhpBridgeService.startServer` default instances `1 -> 4`,
  - `PhpBridgeService.installPhp` default target path `tools/php/php -> php/php`,
  - `PHP Bridge Test` defaults updated to prioritize `php/php` command candidate and 4 instances.
- Verified by checks:
  - `flutter analyze` on updated Dart files passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 31
- Aligned generic Android `sourceRuntimeProbe/sourceRuntimeExecute` with PHP bridge runtime context:
  - PHP engine options now auto-merge runtime environment (`PHPRC`, `PHP_INI_SCAN_DIR`, `HOME`, `TMPDIR`, `LD_LIBRARY_PATH`),
  - PHP engine now defaults working directory to bridge script root when caller does not provide one.
- This closes the biggest consistency gap between `/phpTest` (generic runtime path) and `/phpBridgeTest` (dedicated bridge path) for migration verification.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 32
- Expanded Thunder fallback protocol parsing coverage on Android + Dart fallback:
  - added support for `qqdl://` and `flashget://` decode paths in addition to `thunder://`,
  - improved base64 decode compatibility for payload variants (padding/URL-safe tolerance),
  - added per-scheme unwrap rules (`AA...ZZ` / `[FLASHGET]... [FLASHGET]`) before nested URL parse.
- This improves reverse migration tolerance for real-world thunder-family links and reduces parser mismatch across platforms.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 33
- Improved Android Jar lifecycle parity by adding reflective lifecycle callback handling:
  - `destroySpider` now attempts zero-arg lifecycle calls in order: `destroy` -> `release` -> `close` when runtime context exists,
  - `clearAll` now attempts the same lifecycle callbacks for all cached spider contexts before state cleanup,
  - lifecycle invoke result metadata is returned (`lifecycleMethod`, `lifecycleInvoked`) for migration diagnostics.
- This reduces migration drift where reverse package plugins rely on explicit lifecycle side effects.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 34
- Added Jar runtime-state snapshot bridge for migration diagnostics:
  - Android method `getJarRuntimeState` now exposes loaded/crashed/context/recent spider snapshots,
  - Flutter `JarLoaderService` adds typed `JarRuntimeStateResult`,
  - `/jarTest` adds `Runtime State` action and result card for direct runtime inspection.
- This improves reverse validation efficiency for lifecycle/context reuse regressions.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/jar_loader_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

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
- Source Helper generic tool now supports switching between echo-probe and real code-exec modes.
- Jar Test now exposes advanced invoke controls for `mainClass/staticOnly`.
- Android Jar lifecycle baseline method surface is now callable from Flutter (`destroy/mark/is/count/clear`), but deep spider API parity is still pending.
- Android Jar business method surface (`home/search/detail/player/action/setRecent`) now has a reflective baseline bridge for migration integration.
- Thunder bridge now has baseline task lifecycle behavior (`taskId` tracking + stop/release state management) on Android and fallback platforms.
- Jar business API baseline now has an integrated UI validation entry in Source Helper (`/jarTest`).
- Source Helper now includes direct `PHP Test` route for runtime/migration verification.
- Android Jar business API now reuses per-spider runtime context/instance baseline instead of always re-instantiating.
- PHP plugin-equivalent baseline bridge and debug UI are now available for migration validation on Android.
- Android PHP bridge now includes baseline download/extract install orchestration, runtime env wiring, and scripts/bootstrap behavior closer to reverse plugin path.
- Android generic source runtime path for PHP now shares bridge-aligned env/working-directory defaults, reducing behavior drift between debug entry routes.
- Thunder fallback parser now accepts `thunder/qqdl/flashget` family links with normalized decode behavior on Android and non-Android fallback path.
- Android Jar lifecycle bridge now triggers common plugin lifecycle methods (`destroy/release/close`) during destroy/clear flows when available.
- Jar runtime snapshot diagnostics are now available in bridge and `/jarTest` for loaded/crashed/context state checks.
