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

## Step 35
- Extended PHP install diagnostics model and UI:
  - `PhpCommandResult` now parses `downloaded` / `extracted` / `archivePath`,
  - `PHP Bridge Test` install result card now shows download/extract status and archive path.
- This makes Android PHP runtime installation chain easier to validate during reverse migration.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/php_bridge_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 36
- Improved Jar crash-state lifecycle automation:
  - business API invoke failure now auto-marks spider as crashed,
  - business API invoke success now auto-clears previous crashed marker,
  - successful `loadJar` registration now clears stale crashed markers for registered aliases.
- This reduces manual crash-flag operations and better matches expected runtime protection behavior during reverse migration.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 37
- Added Thunder runtime-state snapshot bridge and diagnostics:
  - Android bridge adds `getThunderRuntimeState` with active tasks snapshot (`taskId/protocol/url/infoHash/index/ageMs`),
  - Flutter `ThunderService` adds typed `ThunderRuntimeStateResult`,
  - `/thunderTest` adds `Runtime State` action and snapshot card display.
- This improves runtime verification visibility for thunder task lifecycle closure during reverse migration.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 38
- Expanded Android PHP install archive compatibility and diagnostics:
  - `installPhp` download path now detects archive variants (`tar.gz` / `tgz` / `zip` / `gzip`) using URL + file signature,
  - added zip extraction path with zip-slip path safety checks,
  - extraction now reports `archiveFormat` + `extractMethod` for migration diagnostics.
- Extended Flutter PHP bridge and `/phpBridgeTest` UI:
  - `PhpCommandResult` now parses `archiveFormat` and `extractMethod`,
  - install result card now shows archive format and extraction method chips/details.
- This closes a key archive-variant migration gap for reverse PHP runtime package handling.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/php_bridge_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 39
- Improved Thunder stop-task compatibility closer to reverse plugin behavior:
  - Android `thunderStopTask` now supports empty `taskId` by auto-stopping latest active task,
  - fallback runtime path now mirrors the same empty-id latest-task stop semantics.
- Extended `/thunderTest` diagnostics with `Stop Latest` action for direct verification.
- This reduces API behavior drift where reverse plugin stop flow is current-task oriented instead of strict task-id required.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 40
- Fixed PHP install diagnostics semantics for download/extract separation:
  - `downloaded` is now marked immediately after successful archive download,
  - `extracted` continues to reflect actual unpack/install success.
- This preserves failure visibility for cases where network download succeeds but archive extraction fails.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 41
- Added PHP runtime-state snapshot bridge and diagnostics:
  - Android bridge adds `getPhpRuntimeState` with install/server/process/runtime-path snapshot fields,
  - Flutter `PhpBridgeService` adds typed `PhpRuntimeStateResult`,
  - `/phpBridgeTest` adds `Runtime State` action and runtime snapshot card display.
- This improves migration runtime verification for PHP multi-instance status and runtime path consistency.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/php_bridge_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 42
- Improved Android Jar spider side-effect compatibility with init lifecycle baseline:
  - when creating non-static spider instances, bridge now attempts one-time reflective init hooks:
    - `init(Context|Activity|Application|...)`
    - `initialize(...)`
    - `setContext(...)`
    - and zero-arg `init()/initialize()/setContext()`
  - init attempt/result is cached per spider context to avoid repeated side effects.
- Extended `getJarRuntimeState` diagnostics:
  - adds per-context init snapshot (`initAttempted/initialized/initMethod/initError`) and initialized context count.
- This reduces a key migration gap where reverse jars rely on implicit init/context side effects.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 43
- Synced Jar init-lifecycle diagnostics to Flutter side:
  - `JarRuntimeStateResult` now parses `initializedContextCount` and `contextItems`,
  - `/jarTest` runtime-state card now displays per-context init attempt/status/method/error details.
- This closes the diagnostics loop for Step42, making init side-effect behavior observable from migration test UI.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/jar_loader_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 44
- Improved Android Jar business API signature compatibility:
  - `homeContent` now tries both `(filter)` and `()`,
  - `homeVideoContent` now tries both `(filter)` and `()`,
  - `categoryContent` now supports degraded candidates `(tid,pg,filter,extend)` -> `(tid,pg,filter)` -> `(tid,pg)` -> `(tid)`,
  - `searchContent` adds `(keyword)` fallback,
  - `detailContent` adds single-id string fallback,
  - `playerContent` adds `(flag,id)` fallback,
  - `action` now tries both `(action)` and `()`.
- This reduces reverse migration failures caused by signature drift across different spider jar implementations.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 45
- Made `setRecent` state materially effective in Android Jar runtime resolution:
  - when spider business calls miss `key` but provide `jarPath`, bridge now attempts recent key fallback,
  - when calls miss `jarPath` but provide `key`, bridge now attempts recent jar fallback,
  - when only one recent entry exists and both are missing, bridge can use that single recent pair,
  - runtime lookup now also falls back to latest loaded spider under same jar path.
- This reduces migration call failures from incomplete call arguments and better aligns with reverse package "recent spider" semantics.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 46
- Improved Thunder parse output parity for migration diagnostics:
  - Android `thunderParseMagnet` now returns `mediaCount` and `medias` snapshot list (`name/size/index/ext/sizeText`) for magnet links,
  - Flutter `ThunderParseResult` now parses typed media snapshot fields,
  - `/thunderTest` parse card now displays media count and media detail lines.
- This closes a key schema gap versus reverse plugin parse results and improves downstream debug readability.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 47
- Added GoProxy runtime-state snapshot bridge and diagnostics:
  - Android bridge adds `getGoProxyRuntimeState` (running/pid/proxyUrl/lastCommand/args/workingDirectory/uptime/lastError),
  - Flutter `GoProxyService` adds typed `GoProxyRuntimeStateResult`,
  - `/goProxyTest` adds `Runtime State` action and state snapshot card.
- This improves reverse migration observability for GoProxy startup/stop behavior and command-state drift.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 48
- Improved GoProxy startup argument parity with reverse package behavior:
  - Android bridge now normalizes effective process args by auto-upserting `-port` and `-danmu-dir`,
  - runtime state now exposes resolved `port` and `danmuDir`,
  - Flutter `GoProxyRuntimeStateResult` and `/goProxyTest` runtime card now display those fields.
- This reduces behavior drift where configured GoProxy URL/port could mismatch the real process args and where danmu cache path was implicit.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 49
- Added Android GoProxy foreground-service baseline and runtime visibility:
  - introduced `GoProxyForegroundService` with persistent low-priority notification and stop action,
  - `startGoProxy/stopGoProxy` now auto-link to foreground service lifecycle,
  - runtime state now exposes `foregroundServiceRunning/foregroundServiceError`,
  - `/goProxyTest` runtime card now shows foreground-service status/error.
- This closes a major migration gap between pure process control and reverse package service-style runtime anchoring.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 50
- Extended GoProxy foreground-service baseline with runtime lock strategy:
  - foreground service now attempts to hold `PARTIAL_WAKE_LOCK` and `WifiLock` during runtime,
  - runtime state now exposes `foregroundWakeLockHeld` and `foregroundWifiLockHeld`,
  - `/goProxyTest` runtime state card now shows lock holding status.
- This narrows reverse parity gap for long-running proxy workloads by adding service-side power/network lock anchoring.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 51
- Improved GoProxy foreground notification action routing baseline:
  - foreground service now tracks GoProxy child pid passed from bridge startup,
  - notification `Stop` action now attempts to terminate tracked pid (`kill -TERM`) before stopping service,
  - runtime state now exposes `foregroundTrackedPid` for action-path observability.
- This narrows reverse parity gap for notification-action control flow from UI-only service stop toward process-level stop routing.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 52
- Improved Thunder parse-media snapshot coverage for `ed2k` links:
  - Android thunder parser now extracts file-name/size/ext snapshot from canonical `ed2k://|file|...|` format,
  - non-Android Thunder fallback parser now mirrors the same `ed2k` media snapshot behavior.
- This reduces parse-schema drift where `ed2k` previously returned protocol-only success without media snapshot detail.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 53
- Improved Thunder `ed2k` hash parity:
  - Android parser now extracts `ed2k` file hash into `infoHash`,
  - fallback parser now mirrors the same `ed2k` `infoHash` extraction.
- This aligns task/result hash observability across `magnet` and `ed2k`.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/thunder_service.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 54
- Added GoProxy runtime state auto-reconciliation:
  - `isGoProxyRunning/getGoProxyRuntimeState` now reconcile process/service consistency,
  - when process has exited, bridge auto-clears stale process state and stops foreground service,
  - when process is alive but foreground service is missing, bridge auto-attempts foreground service recovery.
- This reduces stale-runtime drift between process liveness and service status under edge-case lifecycle changes.
- Verified by checks:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 55
- Added GoProxy exit-state diagnostics:
  - Android runtime state now includes `lastExitCode/lastExitedAtMs`,
  - bridge captures exit code/timestamp on normal stop and on detected unexpected exit,
  - Flutter `GoProxyRuntimeStateResult` and `/goProxyTest` runtime card now display exit diagnostics.
- This improves reverse migration triage for process death causes and lifecycle verification.
- Verified by checks:
  - `flutter analyze lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 56
- Improved generic Source Runtime path for GoProxy:
  - `sourceRuntimeProbe(engine=goproxy)` now returns detailed runtime snapshot text,
  - `sourceRuntimeExecute(engine=goproxy)` now supports `options.action=status|stop`,
  - this removes previous hard block where GoProxy was only usable via dedicated helper route.
- This reduces bridge fragmentation and enables script-level runtime control for migration diagnostics.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 57
- Extended generic Source Runtime GoProxy actions:
  - `sourceRuntimeExecute(engine=goproxy)` now additionally supports `options.action=start`,
  - generic start path reuses the same internal GoProxy start logic as dedicated bridge (`command/args/port/proxyUrl/workingDirectory/danmuDir/environment`).
- This reduces divergence risk between dedicated and generic GoProxy execution paths.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 58
- Extended generic Source Runtime PHP runtime actions:
  - `sourceRuntimeProbe(engine=php)` now returns structured PHP runtime snapshot text instead of plain version-only probe,
  - `sourceRuntimeExecute(engine=php)` now supports `options.action=status|start|stop` besides execute mode,
  - generic PHP `start` now reuses shared internal server-start logic with dedicated PHP bridge path.
- This reduces dedicated-vs-generic behavior drift for PHP runtime control and improves migration observability.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 59
- Extended generic Source Runtime Thunder runtime actions:
  - `sourceRuntimeProbe(engine=thunder)` now returns structured Thunder runtime snapshot text,
  - `sourceRuntimeExecute(engine=thunder)` now supports `options.action=status|parse|play|stop|release`,
  - dedicated Thunder handlers now share internal logic with generic path for parse/play/stop.
- This reduces dedicated-vs-generic behavior drift for Thunder task/runtime control and improves migration debug coverage.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 60
- Extended generic Source Runtime Jar runtime control actions:
  - `sourceRuntimeProbe(engine=jar)` now falls back to Jar runtime snapshot when `options.jarPath` is absent,
  - `sourceRuntimeExecute(engine=jar)` now supports runtime-control actions `status|crash_count|clear_marks|clear_all`,
  - these generic actions reuse existing Jar runtime/crash management internals.
- This adds a lightweight generic Jar control plane for migration scripts without replacing dedicated business invoke flow.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 61
- Added cross-platform packaging orchestration baseline:
  - introduced unified build script `tools/release/build_all.ps1`,
  - script supports `android/ios/windows` target selection, `release/profile/debug` mode, optional Android `appbundle`, and iOS `--no-codesign`,
  - script auto-detects `fvm flutter` or plain `flutter`, and skips unsupported host-target combinations with explicit logs.
- Added build usage doc:
  - `docs/PeekPili_cross_platform_build.md`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 62
- Improved GoProxy stop signal strategy robustness:
  - `stopGoProxy` now uses staged termination (`destroy -> sigterm -> sigkill -> force`) instead of single-path destroy,
  - runtime/operation diagnostics now include `lastStopStrategy/stopStrategy` for stop-path traceability.
- This narrows reverse migration gap around GoProxy long-run stop reliability and failure triage.
- Verified by check:
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 63
- Extended Flutter GoProxy runtime diagnostics surface:
  - `GoProxyRuntimeStateResult` now parses/exposes `lastStopStrategy`,
  - `/goProxyTest` runtime card now displays stop strategy in both chip and detail text.
- This closes Dart/UI visibility gap for newly added native stop-strategy diagnostics.
- Verified by checks:
  - `flutter analyze --no-pub lib/services/source_runtime/go_proxy_service.dart lib/pages/source_helper/view.dart` passed.
  - `android\\gradlew.bat :app:compileDebugKotlin` passed.

## Step 64
- Added migration closure execution checklist:
  - new document `docs/PeekPili_runtime_closure_checklist.md` captures remaining runtime validation work across Android/iOS/Windows and cross-platform packaging acceptance criteria.
- Reverse inventory now links to this checklist from pending-runtime section for traceable closure tracking.

## Step 65
- Hardened cross-platform build script for Windows plugin dependency bootstrap:
  - fixed single-target parsing under strict PowerShell mode,
  - added host detection compatibility for Windows PowerShell (`$IsWindows/$IsMacOS` fallback),
  - added automatic `tools/nuget/nuget.exe` bootstrap download for Windows build dependency chain.
- Repo hygiene:
  - `.gitignore` now ignores `tools/nuget/nuget.exe` (auto-downloaded tool binary).
- Smoke verification:
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -SkipPubGet` passed,
  - artifact produced: `build\\windows\\x64\\runner\\Debug\\piliplus.exe`.

## Step 66
- Android packaging smoke verification via unified script:
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -SkipPubGet` passed,
  - artifact produced: `build\\app\\outputs\\flutter-apk\\app-debug.apk`.

## Step 67
- iOS host-skip behavior verification on Windows:
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -NoCodesign` passed with expected skip output (`host is not macOS`).

## Step 68
- Windows release packaging smoke verification:
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode release -SkipPubGet` passed,
  - artifact produced: `build\\windows\\x64\\runner\\Release\\piliplus.exe`.

## Step 69
- Android release packaging smoke verification:
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode release -SkipPubGet` passed,
  - artifact produced: `build\\app\\outputs\\flutter-apk\\app-release.apk`.

## Step 70
- Environment readiness checkpoint:
  - `flutter doctor -v` passed with no issues,
  - Android SDK/Windows Build Tools are available and healthy.
- Runtime closure blocker snapshot:
  - current connected devices are desktop/web only (`windows/chrome/edge`),
  - no Android physical/emulator target and no macOS host in current environment, so iOS/Android runtime-equivalence closure items remain pending.

## Step 71
- Extended unified build script with optional Android post-build install flow:
  - new flag: `-InstallAndroidApk`,
  - script now auto-discovers `adb` from `ANDROID_SDK_ROOT` / `ANDROID_HOME` / `local.properties` / `android/local.properties` / PATH,
  - if no online Android device is connected, install step is skipped explicitly and build remains successful.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -SkipPubGet -InstallAndroidApk` passed (detected adb, skipped install due no online devices).

## Step 72
- Extended Android post-build automation with optional app launch:
  - new flag: `-LaunchAndroidAfterInstall`,
  - launch defaults to package `com.example.piliplus`, configurable via `-AndroidApplicationId`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -SkipPubGet -InstallAndroidApk -LaunchAndroidAfterInstall` passed (no online device -> install/launch skipped explicitly).

## Step 73
- Added artifact-manifest export in unified build script:
  - new flag: `-ArtifactManifestPath`,
  - script now outputs JSON metadata (`generatedAtUtc/mode/targets/host`) and generated artifact paths.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -SkipPubGet -ArtifactManifestPath build/artifacts/windows-debug-manifest.json` passed.
  - manifest generated: `build\\artifacts\\windows-debug-manifest.json`.

## Step 74
- Upgraded artifact-manifest schema for release integrity:
  - manifest now includes `schemaVersion=2`,
  - added `artifactDetails` entries with `path/sizeBytes/sha256` for each built artifact.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets android -Mode debug -SkipPubGet -ArtifactManifestPath build/artifacts/android-debug-manifest.json` passed.
  - manifest generated: `build\\artifacts\\android-debug-manifest.json` with `artifactDetails.sha256`.

## Step 75
- Added Android runtime smoke automation script:
  - new script: `tools/release/android_runtime_smoke.ps1`,
  - supports APK install, app launch, and per-device `logcat` capture when devices are online,
  - no-device condition is explicit skip with success exit for CI-friendly preflight.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/android_runtime_smoke.ps1 -LaunchWaitSeconds 2` passed (skip due no online Android devices).

## Step 76
- Added Windows runtime smoke automation script:
  - new script: `tools/release/windows_runtime_smoke.ps1`,
  - supports app launch, short runtime wait, JSON report output, and default auto-stop for non-interactive smoke verification.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/windows_runtime_smoke.ps1 -LaunchWaitSeconds 3` passed.
  - report generated: `build\\runtime-smoke\\windows_runtime_smoke_*.json`.

## Step 77
- Integrated runtime smoke automation into unified build script:
  - new flags: `-RunRuntimeSmoke` and `-RuntimeSmokeWaitSeconds`,
  - when enabled, build flow auto-invokes target smoke scripts (`android_runtime_smoke.ps1` / `windows_runtime_smoke.ps1`) after successful build.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets windows -Mode debug -SkipPubGet -RunRuntimeSmoke -RuntimeSmokeWaitSeconds 2` passed.
  - runtime smoke report generated via integrated flow: `build\\runtime-smoke\\windows_runtime_smoke_*.json`.

## Step 78
- Added CI-ready Windows runtime smoke workflow:
  - new workflow: `.github/workflows/runtime_smoke_windows.yml`,
  - supports manual dispatch with `mode` and smoke wait inputs,
  - executes unified build script with integrated runtime smoke and uploads smoke reports + artifact manifest.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`.

## Step 79
- Added CI-ready Android runtime smoke workflow:
  - new workflow: `.github/workflows/runtime_smoke_android.yml`,
  - supports manual dispatch with `mode/smoke_wait_seconds/application_id`,
  - executes unified build flow (`build + install + launch + runtime smoke + manifest`) and uploads APK/manifest/smoke logs.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`.

## Step 80
- Added runtime smoke summary script:
  - new script: `tools/release/runtime_smoke_summary.ps1`,
  - aggregates recent runtime smoke JSON reports and artifact manifests into Markdown summary (`build/runtime-smoke/summary.md`).
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1 -MaxItems 5` passed.
  - summary generated: `build\\runtime-smoke\\summary.md`.

## Step 81
- Improved runtime smoke summary compatibility:
  - summary script now supports legacy artifact manifests that only include `artifacts` (without `artifactDetails`),
  - avoids false parse-error output for schema-v1 manifest files.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1 -MaxItems 5` passed.
  - summary now lists legacy manifest artifacts without parse errors.

## Step 82
- Added runtime closure status snapshot script:
  - new script: `tools/release/runtime_closure_status.ps1`,
  - emits machine-readable closure state JSON (`build/runtime-smoke/closure-status.json`) including:
    - runtime smoke evidence counts,
    - environment readiness (`adb`, online Android devices, macOS/iOS host),
    - pending closure blockers.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1` passed.
  - status generated: `build\\runtime-smoke\\closure-status.json`.

## Step 83
- Integrated closure status snapshot into CI runtime-smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now run `tools/release/runtime_closure_status.ps1` and upload dedicated closure-status artifacts.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 84
- Enhanced unified build orchestrator with runtime closure snapshot integration:
  - updated `tools/release/build_all.ps1`,
  - new options:
    - `-EmitRuntimeClosureStatus`,
    - `-RuntimeClosureStatusPath`,
  - `-RunRuntimeSmoke` now auto-triggers closure status generation at end of build flow.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/build_all.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Dry execution passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -EmitRuntimeClosureStatus`.

## Step 85
- Enhanced runtime closure status script with policy/gating support:
  - updated `tools/release/runtime_closure_status.ps1`,
  - new options:
    - `-MinWindowsSmokeReports`,
    - `-MinAndroidSmokeLogs`,
    - `-FailOnPending`,
  - output now includes `schemaVersion=2` and explicit `criteria`.
- Readiness calculation update:
  - `overallReady` now also requires online Android device readiness.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/runtime_closure_status.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Default status generation passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1`.
  - Gate mode verified (pending expected in current environment):
    - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_closure_status.ps1 -FailOnPending` returned non-zero as designed.

## Step 86
- Added optional closure gate control to runtime smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now expose `workflow_dispatch` input `fail_on_pending` (`false/true`),
  - closure snapshot step appends `-FailOnPending` when `fail_on_pending=true`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 87
- Added one-command reverse completion check helper:
  - new script: `tools/release/reverse_completion_check.ps1`,
  - orchestrates:
    - runtime smoke summary refresh,
    - closure status refresh with thresholds,
    - machine-readable completion decision (`overallReady`) and pending blockers report.
  - emits Markdown report: `build/runtime-smoke/reverse-completion-report.md`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Check command passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1`.
  - Report generated:
    - `build\\runtime-smoke\\reverse-completion-report.md`.

## Step 88
- Integrated reverse completion report into runtime-smoke CI workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now run `tools/release/reverse_completion_check.ps1 -SkipStatus`,
  - both upload `reverse-completion-report.md` as dedicated artifacts.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 89
- Synced latest automated closure-check conclusion into reverse inventory:
  - updated `docs/PeekPili_reverse_feature_inventory.md`,
  - added explicit `2026-04-28` snapshot section with command, result, pending blockers and report path.
- Verified by checks:
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - generated report confirms current state is still incomplete due environment/runtime blockers.

## Step 90
- Enhanced reverse completion check report with actionable remediation guidance:
  - updated `tools/release/reverse_completion_check.ps1`,
  - report now includes `Next Actions` section derived from pending blocker codes,
  - console output now prints suggested actions when closure is incomplete.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.

## Step 91
- Improved strict closure-gate workflow behavior for better diagnostics:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - `closure_status` step now captures exit code output and uses `continue-on-error`,
  - artifact/report uploads now run with `if: always()`,
  - final `Enforce closure gate` step fails workflow tail when `fail_on_pending=true` and closure exit code is non-zero.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 92
- Extended unified build orchestrator with reverse completion report support:
  - updated `tools/release/build_all.ps1`,
  - new options:
    - `-RunReverseCompletionCheck`,
    - `-ReverseCompletionReportPath`,
    - `-StrictReverseCompletion`,
  - when closure status was already generated in the same flow, reverse-check step reuses it via `-SkipStatus`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/build_all.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Dry execution passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -EmitRuntimeClosureStatus -RunReverseCompletionCheck`.

## Step 93
- Added runtime smoke summary artifact publishing to CI workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now upload `build/runtime-smoke/summary.md` as dedicated artifacts.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 94
- Added machine-readable JSON report output to reverse completion check:
  - updated `tools/release/reverse_completion_check.ps1`,
  - new option: `-JsonReportPath` (default `build/runtime-smoke/reverse-completion-report.json`),
  - JSON now captures: `overallReady`, `pending`, `nextActions`, and report/source paths.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - JSON report generated:
    - `build\\runtime-smoke\\reverse-completion-report.json`.

## Step 95
- Added reverse-completion JSON artifact uploads in runtime-smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now upload `build/runtime-smoke/reverse-completion-report.json`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 96
- Extended unified build orchestrator with configurable reverse-completion JSON path:
  - updated `tools/release/build_all.ps1`,
  - new option: `-ReverseCompletionJsonReportPath`,
  - build flow now passes both markdown and JSON output paths to `reverse_completion_check.ps1`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/build_all.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Dry execution passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -EmitRuntimeClosureStatus -RunReverseCompletionCheck -ReverseCompletionJsonReportPath build/runtime-smoke/custom-reverse-completion.json`.

## Step 97
- Updated reverse feature inventory with JSON closure-evidence path:
  - updated `docs/PeekPili_reverse_feature_inventory.md`,
  - automated closure snapshot section now explicitly records both markdown/json report outputs.
- Verified by checks:
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - both reports exist:
    - `build\\runtime-smoke\\reverse-completion-report.md`,
    - `build\\runtime-smoke\\reverse-completion-report.json`.

## Step 98
- Added CI job-summary closure output for runtime-smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now append reverse completion summary (`overallReady` + pending blocker list) to `GITHUB_STEP_SUMMARY`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 99
- Extended build artifact manifest coverage for closure artifacts:
  - updated `tools/release/build_all.ps1`,
  - manifest generation is now executed after closure/report steps to capture final outputs,
  - when enabled, generated closure/reverse-check outputs are now added to `BuildArtifacts`,
  - manifest now can include:
    - closure status json,
    - reverse completion markdown report,
    - reverse completion json report.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/build_all.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Dry execution with manifest passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -EmitRuntimeClosureStatus -RunReverseCompletionCheck -ArtifactManifestPath build/artifacts/ios-closure-manifest.json`.
  - Manifest contains closure/report artifact entries.

## Step 100
- Enhanced reverse completion reports with blocker categorization:
  - updated `tools/release/reverse_completion_check.ps1`,
  - pending blockers now carry category labels (`environment` / `runtime_validation`),
  - markdown/json outputs now include category counts and categorized blocker listing.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - JSON report contains `pendingWithCategory` and `blockerCounts`.

## Step 101
- Extended runtime-smoke workflow summaries with blocker category counts:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - run summary now additionally prints `blockerCounts.environment` and `blockerCounts.runtimeValidation`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 102
- Added runtime-validation-only strict gate mode for reverse completion checks:
  - updated `tools/release/reverse_completion_check.ps1`,
  - new option: `-StrictRuntimeValidationOnly`,
  - strict-mode evaluation now supports:
    - full strict (`-Strict`) by overall closure,
    - runtime-only strict by `runtime_validation` blocker count.
- Wired through unified build flow:
  - updated `tools/release/build_all.ps1`,
  - new option: `-StrictReverseCompletionRuntimeOnly`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Runtime-only strict fails when runtime blockers exist:
    - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1 -StrictRuntimeValidationOnly` returned non-zero in current environment.
  - Runtime-only strict passes when only environment blockers remain:
    - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1 -MinAndroidSmokeLogs 0 -MinWindowsSmokeReports 0 -StrictRuntimeValidationOnly` returned zero in current environment.

## Step 103
- Added runtime-validation-only gate input to runtime-smoke CI workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - new workflow input: `fail_on_runtime_validation_pending` (`false/true`),
  - final gate step now reads `reverse-completion-report.json` and fails only when `blockerCounts.runtimeValidation > 0`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 104
- Enhanced runtime smoke summary with reverse completion snapshot section:
  - updated `tools/release/runtime_smoke_summary.ps1`,
  - summary now reads `build/runtime-smoke/reverse-completion-report.json` when present,
  - outputs:
    - `overallReady`,
    - blocker category counts,
    - pending blocker list.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/runtime_smoke_summary.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1 -MaxItems 5` passed.
  - `build\\runtime-smoke\\summary.md` contains `Reverse Completion Snapshot` section.

## Step 105
- Added reverse-check threshold pass-through options in unified build flow:
  - updated `tools/release/build_all.ps1`,
  - new options:
    - `-ReverseMinWindowsSmokeReports`,
    - `-ReverseMinAndroidSmokeLogs`,
  - build flow now forwards these thresholds to `reverse_completion_check.ps1`,
  - when custom thresholds are used, reverse-check step refreshes closure status instead of reusing pre-generated default-threshold snapshot.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/build_all.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Dry execution passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/build_all.ps1 -Targets ios -Mode debug -SkipPubGet -EmitRuntimeClosureStatus -RunReverseCompletionCheck -StrictReverseCompletionRuntimeOnly -ReverseMinAndroidSmokeLogs 0 -ReverseMinWindowsSmokeReports 0`.

## Step 106
- Added runtime-smoke threshold inputs to CI workflows and aligned closure/reverse checks:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - new inputs:
    - `min_windows_smoke_reports`,
    - `min_android_smoke_logs`,
  - closure status and reverse completion steps now consume the same threshold inputs for consistent gating.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 107
- Extended runtime-smoke workflow job summaries with recommended next actions:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - summary step now appends `nextActions` from `reverse-completion-report.json`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 108
- Enhanced reverse completion JSON with repo-relative paths:
  - updated `tools/release/reverse_completion_check.ps1`,
  - JSON now includes both absolute and repo-relative path fields:
    - `summaryPathRelative`,
    - `statusPathRelative`,
    - `markdownReportPathRelative`,
    - `jsonReportPathRelative`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/reverse_completion_check.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - JSON report contains new `*PathRelative` fields.

## Step 109
- Updated reverse feature inventory closure snapshot with blocker category counts and relative-path evidence:
  - updated `docs/PeekPili_reverse_feature_inventory.md`,
  - snapshot now includes `blockerCounts(environment/runtimeValidation)` and JSON relative-path key list.
- Verified by checks:
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - JSON report confirms:
    - `blockerCounts.environment=2`,
    - `blockerCounts.runtimeValidation=1`,
    - `*PathRelative` fields present.

## Step 110
- Added runtime environment readiness quick-check helper:
  - new script: `tools/release/runtime_environment_readiness.ps1`,
  - executes closure snapshot with smoke thresholds forced to zero (environment-focused),
  - reports:
    - `adbFound`,
    - `onlineAndroidDevices`,
    - `iosEnvironmentReady`,
    - aggregate readiness result.
  - supports strict mode `-FailIfNotReady`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/runtime_environment_readiness.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1` passed.

## Step 111
- Added environment-readiness gate input in runtime-smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - new input: `fail_if_environment_not_ready` (`false/true`),
  - final gate step now can fail specifically on `blockerCounts.environment > 0`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 112
- Enhanced environment readiness helper with requirement profiles and dedicated report output:
  - updated `tools/release/runtime_environment_readiness.ps1`,
  - new options:
    - `-ReportOutputPath`,
    - `-SkipAdbRequirement`,
    - `-SkipAndroidDeviceRequirement`,
    - `-SkipIosRequirement`,
  - output now includes machine-readable readiness report with `requirements`, `ready`, and `failedChecks`.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/runtime_environment_readiness.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Default check command passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1`.
  - Profile + strict gate command passed:
    - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_environment_readiness.ps1 -SkipIosRequirement -SkipAndroidDeviceRequirement -FailIfNotReady`.

## Step 113
- Integrated environment readiness script into runtime-smoke workflows:
  - updated `.github/workflows/runtime_smoke_windows.yml`,
  - updated `.github/workflows/runtime_smoke_android.yml`,
  - both now run `runtime_environment_readiness.ps1` and publish:
    - readiness status JSON,
    - readiness report JSON.
- Gate behavior enhancement:
  - `fail_if_environment_not_ready=true` now evaluates dedicated readiness report (`ready/failedChecks`) instead of inferred blocker count only.
  - new workflow input `environment_profile` (`strict|android|ios`) controls readiness requirement profile.
- Workflow summary enhancement:
  - run summaries now include environment readiness section (`ready`, requirements, failed checks).
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; [yaml.safe_load(pathlib.Path(p).read_text(encoding='utf-8')) for p in ['.github/workflows/runtime_smoke_windows.yml','.github/workflows/runtime_smoke_android.yml']]"`.

## Step 114
- Enhanced runtime smoke summary with environment readiness snapshots:
  - updated `tools/release/runtime_smoke_summary.ps1`,
  - summary now includes `*environment-readiness-report.json` entries with:
    - `ready`,
    - requirement profile flags,
    - failed check list.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/runtime_smoke_summary.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - `powershell -ExecutionPolicy Bypass -File tools/release/runtime_smoke_summary.ps1 -MaxItems 5` passed.
  - Summary contains `Environment Readiness Snapshots` section.

## Step 115
- Fixed Android runtime launch package mismatch by adding package-candidate fallback:
  - updated `tools/release/android_runtime_smoke.ps1`,
  - updated `tools/release/build_all.ps1` (`Start-AndroidApp`),
  - launch now tries candidates in order (`base`, `base.debug`, `base.dev`) to handle debug/dev suffix variants.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`.
- Verified by checks:
  - PowerShell script syntax parse passed:
    - `powershell -NoProfile -Command '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile(''tools/release/android_runtime_smoke.ps1'',[ref]$tokens,[ref]$errors); if($errors -and $errors.Count -gt 0){$errors | ForEach-Object { $_.Message }; exit 1}'`.
  - Runtime smoke with base package id passed on connected device:
    - `powershell -ExecutionPolicy Bypass -File tools/release/android_runtime_smoke.ps1 -ApkPath build/app/outputs/flutter-apk/app-debug.apk -ApplicationId com.example.piliplus -LaunchWaitSeconds 10`.
  - Reverse completion check now clears Android runtime blocker after device validation:
    - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1`.

## Step 116
- Synced reverse inventory closure snapshot to adb-validated state:
  - updated `docs/PeekPili_reverse_feature_inventory.md`,
  - latest snapshot now reflects:
    - `blockerCounts.environment=1`,
    - `blockerCounts.runtimeValidation=0`,
    - only remaining blocker: `ios_runtime_environment_missing_macos`.
  - updated runtime checklist narrative to indicate Android target is validated; remaining environment gap is macOS iOS host.
- Verified by checks:
  - `powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1` passed.
  - latest JSON report confirms Android blocker removal.

## Step 117
- Added dedicated iOS runtime-confirmation workflow for macOS runners:
  - new workflow: `.github/workflows/runtime_confirmation_ios.yml`,
  - workflow performs:
    - iOS no-codesign build via `build_all.ps1`,
    - reverse completion report generation (iOS-specific output paths),
    - iOS-profile environment readiness check (`SkipAdbRequirement` + `SkipAndroidDeviceRequirement`),
    - summary + artifacts upload for closure/reverse/environment evidence.
- Documentation linked in:
  - `docs/PeekPili_cross_platform_build.md`,
  - `docs/PeekPili_runtime_closure_checklist.md`.
- Verified by checks:
  - workflow YAML parse check passed via:
    - `python -c "import pathlib, yaml; yaml.safe_load(pathlib.Path('.github/workflows/runtime_confirmation_ios.yml').read_text(encoding='utf-8'))"`.

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
- PHP install diagnostics now expose download/extract/archive details in typed bridge model and test UI.
- PHP install diagnostics now also expose archive format/extract-method (`tar/gzip/zip`) for reverse parity verification.
- Jar crash markers now auto-synchronize with business invoke success/failure and reload lifecycle.
- Thunder runtime snapshot diagnostics are now available in bridge and `/thunderTest` for active-task state checks.
- Thunder stop flow now supports empty-id latest-task stop semantics for better reverse parity.
- PHP install diagnostics now separate `downloaded` vs `extracted` states for clearer failure triage.
- PHP runtime snapshot diagnostics are now available in bridge and `/phpBridgeTest` for install/server/process state checks.
- Jar runtime context now includes one-time init hook attempts (`init/initialize/setContext`) with runtime-state diagnostics.
- Jar init-lifecycle diagnostics are now parsed and displayed in `/jarTest` runtime-state UI.
- Jar business API now supports broader method-signature fallback combinations to improve cross-jar compatibility.
- Jar runtime resolution now uses recent-key/recent-jar fallback semantics when business call arguments are incomplete.
- Thunder parse output now includes media snapshot structure (`mediaCount/medias`) for magnet diagnostics.
- GoProxy runtime snapshot diagnostics are now available in bridge and `/goProxyTest`.
- GoProxy startup args now auto-align on `-port`/`-danmu-dir`, and runtime state exposes resolved values.
- GoProxy now has a foreground-service baseline (notification + stop action) linked to process lifecycle.
- GoProxy foreground-service runtime now includes wake/wifi lock baseline with state visibility.
- GoProxy notification stop path now includes tracked child-pid termination attempt with runtime pid visibility.
- Thunder parse-media snapshot now covers both magnet and canonical ed2k file links.
- Thunder parse now also emits `infoHash` for canonical ed2k links.
- GoProxy runtime now auto-reconciles process/service state to reduce stale-running markers.
- GoProxy runtime diagnostics now include last exit code/time snapshot fields.
- Source Runtime generic bridge now supports GoProxy runtime `status/stop` actions.
- Source Runtime generic bridge now supports full GoProxy `start/status/stop` action set.
- Source Runtime generic bridge now supports PHP runtime `status/start/stop` actions with runtime snapshot probe output.
- Source Runtime generic bridge now supports Thunder runtime `status/parse/play/stop/release` actions with runtime snapshot probe output.
- Source Runtime generic bridge now supports Jar runtime `status/crash_count/clear_marks/clear_all` actions with runtime snapshot probe output.
- Cross-platform packaging baseline now has a unified PowerShell build orchestrator for Android/iOS/Windows.
- GoProxy stop flow now uses staged signal escalation with stop-strategy diagnostics (`lastStopStrategy`).
- GoProxy stop-strategy diagnostics are now visible end-to-end in Flutter runtime model and `/goProxyTest` UI.
- Remaining reverse/migration closure tasks are now explicitly operationalized in `docs/PeekPili_runtime_closure_checklist.md`.
- Windows local packaging flow has been smoke-validated via the unified build script.
- Android local packaging flow has been smoke-validated via the unified build script.
- iOS non-macOS skip path has been validated to be explicit and non-failing.
- Windows and Android release-mode packaging flows have been smoke-validated.
- Toolchain is ready (`flutter doctor` clean), but mobile runtime closure still depends on Android device/emulator and macOS iOS runtime validation environment.
- Unified build flow now supports optional Android auto-install with robust adb discovery and graceful no-device skip.
- Unified build flow now also supports optional Android app auto-launch after install.
- Unified build flow now can emit machine-readable artifact manifests for release tracking/CI integration.
- Artifact manifests now include checksum/size metadata for integrity verification.
- Android runtime closure now has an executable smoke script entrypoint ready for device-connected validation.
- Windows runtime closure now has an executable smoke script entrypoint ready for packaged-app launch validation.
- Unified build flow can now directly execute post-build runtime smoke for supported targets.
- Windows runtime smoke now has a dedicated GitHub Actions entry for repeatable CI execution.
- Android runtime smoke now has a dedicated GitHub Actions entry for device-enabled runners.
- Runtime smoke outputs now support one-command summary aggregation for audit and handoff.
- Runtime smoke summary output now handles both schema-v1 and schema-v2 artifact manifests.
- Closure progress now has a machine-readable status snapshot with explicit pending blockers.
- Runtime smoke CI workflows now publish per-run closure-status artifacts for audit traceability.
- Unified build flow now can auto-generate closure status snapshots and supports explicit status output path.
- Closure status script now supports threshold policies and optional CI gate failure on pending blockers.
- Runtime smoke workflows now support optional `fail_on_pending` gate for strict closure enforcement.
- Reverse completion check now has a single command entry with explicit completion/incomplete decision output.
- Runtime smoke workflows now also publish reverse completion report artifacts for each run.
- Reverse inventory now contains a dated machine-assisted closure snapshot and concrete blocker list.
- Reverse completion report now includes blocker-to-action guidance for direct next-step execution.
- Strict closure gating now preserves diagnostic artifacts before failing workflow result.
- Unified build flow now can optionally emit reverse completion report (and strict-fail by closure state) in one run.
- Runtime smoke CI workflows now publish summary/report/status artifacts as a full closure evidence set.
- Reverse completion check now also emits a machine-readable JSON report for automation integration.
- Runtime smoke CI workflows now also publish reverse completion JSON artifacts for machine consumers.
- Unified build flow now supports custom reverse completion JSON report path.
- Reverse inventory snapshot now captures both human-readable and machine-readable closure artifacts.
- Runtime-smoke workflow run summaries now directly expose closure readiness and pending blockers.
- Unified build manifest now includes closure/report artifacts for end-to-end auditability.
- Closure reports now separate environment blockers from runtime-validation blockers for clearer triage.
- Runtime-smoke workflow summaries now also display blocker category counts for quicker diagnosis.
- Reverse completion strict mode now supports runtime-validation-only gating to avoid environment-only false failures.
- Runtime-smoke CI workflows now support runtime-validation-only gate input for practical non-macOS/non-device runners.
- Runtime smoke summary now directly surfaces reverse completion snapshot for human audit.
- Unified build flow now supports reverse-check threshold tuning without leaving build script context.
- Runtime-smoke workflows now allow threshold tuning with consistent closure/reverse evaluation logic.
- Runtime-smoke workflow summaries now directly include actionable next steps.
- Reverse completion JSON now provides repo-relative path metadata for portable automation.
- Reverse inventory snapshot now includes blocker category counts aligned with machine-readable closure output.
- Environment readiness now has a dedicated quick-check script for pre-flight validation.
- Runtime-smoke workflows now support an explicit environment-readiness gate option.
- Environment readiness checks now support profile-based requirements and machine-readable readiness reports.
- Runtime-smoke workflows now execute and publish dedicated environment readiness evidence with profile-aware gate enforcement.
- Runtime smoke summary now consolidates reverse completion and environment readiness evidence in one report.
- Android device runtime smoke no longer fails on debug package suffix mismatch during launch.
- Android runtime closure blockers are now cleared on connected adb device; remaining blocker is iOS runtime environment validation on macOS.
- A dedicated macOS iOS runtime-confirmation workflow is now available to close the final blocker in CI.
