# PeekPiliRelease Reverse Feature Inventory (v1)

Last updated: 2026-04-28  
Goal: build a migration-grade feature and capability map from the packages in `D:\Work\workSpace\PeekPiliRelease\app\anzhuangbao`.

## 1. Scope and Samples

Analyzed packages:

- `PeekPili_android_1.2.5+2_arm64.apk`
- `PeekPili_ios_1.2.5+2.ipa`
- `PeekPili_windows_1.2.5+2_x64_setup.exe`
- Unpacked Windows app: `PeekPili_windows_1.2.5+2_x64\Release\...`
- Functional doc: `C:\Users\12170\Desktop\PeekPiliRelease.pdf`

Evidence method:

- Android: JADX classes, AndroidManifest, native libs (`libapp.so`, `lib*.so`), Flutter assets.
- iOS: IPA unpack, `Info.plist`, frameworks, `App.framework/App` strings.
- Windows: unpacked `Release` runtime tree (`data/app.so`, `data/nodejs`, `data/python`, `data/php`, plugins).
- PDF text extraction for doc vs binary comparison.

Confidence tags:

- `FACT`: direct code/file/config proof exists.
- `INFERRED`: inferred from strings/routes/config keys.
- `UNKNOWN`: static proof is not enough; runtime validation needed.

## 2. Architecture Reconstruction

- Cross-platform Flutter app with shared AOT business layer (`app.so`). `FACT`
- Strong config-driven design for TVBox/T4 features (`t4_*` keys), TMDB (`tmdb*`), and WebDAV (`webdav*`). `FACT`
- Platform capabilities are not symmetric:
  - Android: richest local integration (Java plugins/services + native libs).
  - Windows: local Node/Python/PHP runtimes bundled.
  - iOS: Node/JS stack present, but some local runtimes are missing or unclear.

## 3. Platform Evidence

## 3.1 Android package evidence

### 3.1.1 Manifest and system integration

- Package id: `com.example.peekpili`, app class: `com.chaquo.python.android.PyApplication`.  
  Evidence: `_reverse/apk_jadx/resources/AndroidManifest.xml:7,77` `FACT`
- Permissions include storage/media, overlay, install packages, foreground services, notifications.  
  Evidence: `AndroidManifest.xml:52-72` `FACT`
- Deep links for bilibili domains and `bilibili://`.  
  Evidence: `AndroidManifest.xml:111-129` `FACT`
- Declared services:
  - `com.example.peekpili.T4ProxyForegroundService`
  - `com.example.peekpili.music.MusicNotificationService`
  - `com.example.peekpili.music.DesktopLyricsService`  
  Evidence: `AndroidManifest.xml:233-241` `FACT`

### 3.1.2 Android-only plugin channels

- `com.peekpili/jar_loader` (Jar loader plugin).  
  Evidence: `_reverse/apk_jadx/sources/N1/d.java:396` `FACT`
- `com.peekpili/php` (PHP runtime plugin).  
  Evidence: `_reverse/apk_jadx/sources/N1/l.java:305` `FACT`
- `com.peekpili/thunder` (thunder/magnet plugin).  
  Evidence: `_reverse/apk_jadx/sources/com/peekpili/thunder/ThunderPlugin.java:36` `FACT`
- `com.example.peekpili/music_notification` and `com.example.peekpili/desktop_lyrics`.  
  Evidence: `_reverse/apk_jadx/sources/U0/l.java:70`, `U0/c.java:42` `FACT`

### 3.1.3 Android functional entry points

- Jar loader method surface:
  - `loadJar`, `destroySpider`, `homeContent`, `homeVideoContent`, `categoryContent`, `searchContent`,
  - `detailContent`, `playerContent`, `action`, `setRecent`,
  - `startGoProxy`, `stopGoProxy`, `isGoProxyRunning`, `getProxyUrl`,
  - crash mark/check/clear methods.
  Evidence: `_reverse/apk_jadx/sources/N1/a.java:78-239` `FACT`
- GoProxy process control:
  - arch selection, binary start, args (`-port`, `-danmu-dir`), liveness check.
  Evidence: `_reverse/apk_jadx/sources/N1/d.java:488-533` `FACT`
- PHP plugin method surface:
  - `startServer`, `stopServer`, `installPhp`, `isInstalled`, `getVersion`, `getExtensions`,
  - `getScriptsDir`, `executeCode`, `getPhpDir`, `getServerPort`, `isServerRunning`.
  Evidence: `_reverse/apk_jadx/sources/N1/l.java:335-719` `FACT`
- Thunder plugin:
  - `isSupported`, `parseMagnet`, `getPlayUrl`, `stopTask`, `release`,
  - protocol handling includes `magnet`, `ed2k`, `thunder`, `ftp`.
  Evidence: `ThunderPlugin.java:36,60,85,122,350-363` `FACT`
- T4 foreground proxy service with wake/wifi lock and foreground notification action flow.
  Evidence: `T4ProxyForegroundService.java:79-91,111-135` `FACT`
- Desktop lyrics overlay service:
  - overlay permission flow, window manager overlay, lyric text and style persistence.
  Evidence: `DesktopLyricsService.java:219-254,259-260`, `U0/c.java:115-159` `FACT`
- Music notification service:
  - play/pause/prev/next/favorite/lyrics toggle + media session update.
  Evidence: `MusicNotificationService.java:201-217`, `U0/l.java:96-203` `FACT`
- ExoPlayer plugin:
  - initialize/dispose, subtitle style, playback speed, track switching,
  - event stream and retry strategy.
  Evidence: `ExoPlayerPlugin.java:56,132,162,205`, `ExoPlayerManager.java:389-459,1146,1339,1346` `FACT`

### 3.1.4 Android runtime payloads

- Local native libs include:
  - `libnode.so`, `libpython3.11.so`, `libxl_thunder_sdk.so`, `libffmpeg.so`, `libmpv.so`, `libmdk.so`.
  Evidence: `_reverse/apk_jadx/resources/lib/arm64-v8a/*` `FACT`
- Flutter assets include:
  - `assets/nodejs/*.cjs`, `assets/drpy_patches/*.js`, `assets/js/lib/cat.js`, `cheerio`, `crypto-js`.
  Evidence: `_reverse/apk_jadx/resources/assets/flutter_assets/assets/*` `FACT`

## 3.2 iOS package evidence

### 3.2.1 App metadata

- Bundle id: `com.example.peekpili`; version `1.2.5 (279)`; min iOS `13.0`.  
  Evidence: `Payload/PeekPili.app/Info.plist` `FACT`
- Background mode includes `audio`.  
  Evidence: `Info.plist -> UIBackgroundModes` `FACT`
- Deep links include bilibili domains and `bilibili` scheme.  
  Evidence: `Info.plist -> CFBundleURLTypes` `FACT`
- Camera/library/media usage strings are present.  
  Evidence: `Info.plist -> NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSAppleMusicUsageDescription` `FACT`

### 3.2.2 Framework and plugin signals

- Key frameworks include:
  - `NodeMobile.framework`, `flutter_node.framework`, `flutter_js.framework`,
  - `flutter_inappwebview_ios.framework`,
  - `Mpv.framework`, `mdk.framework`, `media_kit_*`, `just_audio.framework`.
  Evidence: `Payload/PeekPili.app/Frameworks/*` `FACT`
- Registered plugin names found in app binary:
  - `FlutterNodePlugin`, `FlutterJsPlugin`, `InAppWebViewFlutterPlugin`,
  - `MediaKitVideoPlugin`, `FvpPlugin`, `JustAudioPlugin`, etc.
  Evidence: `Payload/PeekPili.app/PeekPili` strings `FACT`

### 3.2.3 iOS business assets and routes

- `App.framework/flutter_assets/assets` contains:
  - `nodejs/*.cjs`, `drpy_patches/*.js`, `js/lib/cat.js`, `SDK/lx_bridge.js`.
  Evidence: `Payload/PeekPili.app/Frameworks/App.framework/flutter_assets/assets/*` `FACT`
- `App.framework/App` contains many T4/Drpy/WebDAV/TMDB markers and feature routes:
  - `/pythonTest`, `/catJsTest`, `/nodeJsTest`, `/webdavSetting`, `/t4Detail`.
  Evidence: `Frameworks/App.framework/App` strings `FACT`

### 3.2.4 iOS local runtime payload check (focused)

- Recursive file-name scan under `Payload/PeekPili.app`:
  - matched `NodeMobile` / `flutter_node` framework names,
  - matched only thunder UI image assets (`ic_thunder_*.png`) for thunder keyword.
  Evidence: package file inventory scan `FACT`
- No file or directory names matched local runtime binaries for Python/PHP:
  - no `python*` runtime payload,
  - no `php*` runtime payload.
  Evidence: recursive path scan by keyword on unpacked IPA `FACT`
- No iOS plugin registration signal equivalent to Android jar/php/thunder channels was found in app/plugin names.
  Evidence: plugin-name extraction from `PeekPili` binary (`FlutterNodePlugin`, `FlutterJsPlugin`, etc.) `FACT`

## 3.3 Windows package evidence

### 3.3.1 Runtime layout

- Bundled Node runtime in `data/nodejs` (`node.exe`, `npm`, `npx`). `FACT`
- Bundled Python runtime in `data/python` (`python311.dll`, `python.exe`, stdlib files). `FACT`
- Bundled PHP runtime in `data/php` (`php.exe`, `php-cgi.exe`, `php.ini`, `ext/*`). `FACT`
- Flutter runtime payload in `data/flutter_assets` and `data/app.so`. `FACT`

### 3.3.2 Plugin/media stack

- Windows plugin DLLs include:
  - `flutter_js_plugin.dll`, `flutter_inappwebview_windows_plugin.dll`,
  - `fvp_plugin.dll`, `media_kit_*`, `window_manager_plugin.dll`, `WebView2Loader.dll`.
  Evidence: `Release/*.dll` `FACT`
- MPV-related desktop config exists:
  - `portable_config/mpv.conf`,
  - `portable_config/script-opts/peekpili_danmaku.conf`.
  Evidence: `Release/portable_config/*` `FACT`
- No dedicated thunder/jar/goproxy plugin DLL name was found in `Release/*.dll`.
  Evidence: plugin DLL name inventory `FACT`

### 3.3.3 Business assets and routes

- Same core assets as Android/iOS:
  - `assets/nodejs/*.cjs`, `drpy_patches/*.js`, `js/lib/cat.js`, `SDK/lx_bridge.js`.
  Evidence: `Release/data/flutter_assets/assets/*` `FACT`
- `data/app.so` contains `T4/Drpy2/WebDAV/TMDB` markers and routes:
  - `/pythonTest`, `/catJsTest`, `/nodeJsTest`, `/webdavSetting`.
  Evidence: `Release/data/app.so` strings `FACT`

## 4. Feature Modules for Migration

## 4.1 Source engines

- T4 source flow (category/search/detail/play) exists in shared business layer. `FACT`
- T3 CatJS/Drpy2 support exists via shared JS assets and runtime integration. `FACT`
- T3 Python support:
  - Android: explicit local runtime (`PyApplication`, `libpython3.11.so`, Chaquopy assets).
  - Windows: explicit local Python runtime directory.
  - iOS: route/config markers exist, but no clear local Python runtime files.
  Status: `FACT + UNKNOWN`
- Source helper routes exist:
  - `/pythonTest`, `/catJsTest`, `/nodeJsTest`.
  Status: `FACT`

## 4.2 T4 extension and settings model

Extracted keys from shared binaries (`libapp.so` / `app.so`) include:

- Source config: `t4ApiConfigs`, `t4CurrentApiConfigId`, `t4_source_config_url`, `t4_is_local_config`
- Player config: `t4DefaultPlayer`, `t4CurrentPlayer`, `t4VideoFitIndex`, `t4RememberPlaybackSpeed`, `t4LastPlaybackSpeed`
- Danmaku config: `t4DanmakuUrl`, `t4DanmakuSearchPanel`, `t4DanmakuRandomColorful`, `t4DanmakuGradientColorful`
- Advanced flags: `t4FloatingBallEnabled`, `t4HttpHeaderPolicy`, `t4AutoChangeSource`, `t4AutoContinueDetailEnabled`
- TMDB config: `tmdbAccessToken`, `tmdbIntegrationEnabled`, `tmdbImageProxy`, `tmdb_saved_matches`
- WebDAV config: `webdavServer`, `webdavUsername`, `webdavPassword`, `webdavSetting`, etc.

This key set can be used as the initial migration schema baseline. `FACT`

## 4.3 Settings/Lab feature mapping from static evidence

- Interface/source config: `t4_source_config_url`, `t4ApiConfigs`, `t4_is_local_config`.
- Danmaku API config: `t4DanmakuUrl`, `/danmu_api`.
- Play/video config: `/playSetting`, `/videoSetting`, `t4DefaultPlayer` and related keys.
- Appearance/personalization: `/styleSetting`, `/colorSetting`, `t4Osd*`, `t4Danmaku*`.
- TMDB config: `TMDB_AUTH`, `TMDB_BASE`, and `tmdb*` keys.
- Recommendation/trending config: `/recommendSetting`, `/recommendCalendarSetting`, `t4_trending_view_mode`.
- Source helper tools: `/pythonTest`, `/catJsTest`, `/nodeJsTest`.
- Web sniffing signal: `[VideoSniffer]` marker.
- WebDAV sync signal: `webdav*` keys and `/webdavSetting` route.
- T4 proxy signal: Android has concrete service/plugin evidence; other platforms show config keys only.

All above are `FACT` unless explicitly noted.

## 5. Cross-platform Capability Matrix

| Capability | Android | iOS | Windows | Notes |
|---|---|---|---|---|
| T4 source flow | Yes | Yes | Yes | Shared `app.so` markers and routes |
| CatJS/Drpy2 | Yes | Yes | Yes | Shared assets and runtime markers |
| Local Node service | Yes | Yes | Yes | Android `libnode.so`, iOS `NodeMobile.framework`, Windows `data/nodejs` |
| Local Python runtime | Yes | No payload evidence | Yes | iOS unpacked IPA has no python runtime files by name scan |
| Jar spider engine | Yes | No evidence | No evidence | Android `com.peekpili/jar_loader` + `loadJar` |
| GoProxy local proxy | Yes | No evidence | No evidence | Android `startGoProxy/stopGoProxy` code path |
| Thunder/magnet plugin | Yes | No plugin evidence | No plugin evidence | iOS/Windows have thunder UI markers but no equivalent plugin proof |
| PHP local runtime | Yes | No payload evidence | Yes | Android plugin, Windows bundled runtime, iOS has no php runtime files by name scan |
| Music notification + desktop lyrics | Yes | No evidence | No evidence | Android service/channel implementation |
| T4 foreground proxy service | Yes | No evidence | No evidence | Android `T4ProxyForegroundService` |
| WebDAV module | Yes | Yes | Yes | Shared keys/routes |
| TMDB integration | Yes | Yes | Yes | Shared keys and API markers |

## 6. Document vs Binary Mismatch (Important)

From `PeekPiliRelease.pdf` Q/A:

- `A: Not supported.` (jar package support context)
- `A: Only Python source supports local proxy.` (127.0.0.1:9978 context)

But Android binary evidence shows:

- Existing JarLoader channel and `loadJar` method surface.
- Existing GoProxy control methods (`startGoProxy`, `stopGoProxy`, `isGoProxyRunning`, `getProxyUrl`).

Conclusion: documentation and binaries are not aligned for Android; migration should prioritize package evidence over README claims. `FACT`

## 7. Reverse Completion Checklist

- `DONE (static)` Android native capability anchors for jar/php/thunder/goproxy are complete with channel-level and method-level evidence.
- `DONE (static)` iOS/Windows package inventory and plugin/runtime inventory are complete enough to classify capability asymmetry.
- `DONE (static)` iOS local runtime payload re-check:
  - no python/php payload files by keyword path scan,
  - only Node/JS related plugin/runtime signals are explicit.
- `PENDING (runtime)` confirm whether iOS `/pythonTest` and related routes are strictly remote/proxy fallbacks at runtime.
- `PENDING (runtime)` confirm whether thunder markers on iOS/Windows are UI-only with no hidden runtime bridge path.
- `PENDING (runtime)` execution checklist is tracked in `docs/PeekPili_runtime_closure_checklist.md`.
- `PENDING (runtime)` current environment is toolchain-ready and Android runtime target is now validated on connected adb device, but still lacks macOS iOS runtime host for final runtime-equivalence confirmation.
- `PENDING (migration)` current project still contains implementation gaps:
  - Android `sourceRuntimeProbe/sourceRuntimeExecute` now includes PHP bridge-aligned runtime env and working-directory defaults, plus GoProxy runtime start/status/stop, PHP runtime status/start/stop, Thunder runtime status/parse/play/stop/release, and Jar runtime status/crash_count/clear_marks/clear_all generic action paths; it still remains a generic command bridge (not full reverse plugin lifecycle parity for all engines).
  - Android GoProxy bridge now has start/stop/status/command-prepare, runtime-state diagnostics (including last-exit snapshot and last-stop-strategy), effective arg normalization baseline (`-port`/`-danmu-dir`), foreground-service notification baseline, wake/wifi lock baseline, staged stop signal escalation (`destroy/sigterm/sigkill/force`) with notification stop action pid-termination attempt, and runtime auto-reconciliation for process/service state drift; remaining gap is full reverse-equivalent behavior validation under real proxy workloads (long-run stability under production traffic).
  - Android `loadJar` + Jar lifecycle + spider business method surface (`home/search/detail/player/action/setRecent`) now have baseline reflective bridge support with per-spider context reuse, one-time init/context hook attempts (`init/initialize/setContext`), broader method-signature fallback candidates for spider API calls, recent-key/recent-jar runtime fallback for incomplete call arguments, destroy/release lifecycle callback attempts, runtime-state diagnostics (including per-context init status), and auto crash-state sync on invoke success/failure; however it still lacks reverse package `JarLoader`-equivalent guarantees for all plugin side-effects and full compatibility validation across real source jars.
  - Android PHP bridge now has baseline method surface plus download/extract install orchestration, runtime-env/scripts bootstrap path, archive-variant handling diagnostics (`tar.gz/tgz/zip/gzip`), and runtime-state diagnostics; remaining gap is full runtime equivalence validation (long-running multi-instance stability and real plugin-side effects under production source sets).
  - Thunder bridge now includes baseline task lifecycle tracking, thunder-family link parsing (`thunder/qqdl/flashget` decode paths), parse-media snapshot diagnostics (`mediaCount/medias`, including canonical `magnet/ed2k` file metadata), `magnet/ed2k` hash extraction into `infoHash`, runtime-state diagnostics, and empty-id latest-task stop compatibility; but Thunder SDK-equivalent download/playback/streaming engine behavior is still not closed.

Checkpoint conclusion: reverse work is **not fully complete** for migration-grade certainty yet; static reverse is largely complete, but runtime confirmation and implementation closure are still required.

### 7.1 Latest automated closure snapshot (2026-04-28)

Executed:

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/reverse_completion_check.ps1
```

Result:
- `overallReady=false` (runtime closure incomplete).
- blockerCounts:
  - `environment=1`
  - `runtimeValidation=0`
- Pending blockers:
  - `ios_runtime_environment_missing_macos`
- Generated report:
  - `build/runtime-smoke/reverse-completion-report.md`
  - `build/runtime-smoke/reverse-completion-report.json`
  - relative paths recorded in JSON:
    - `summaryPathRelative`
    - `statusPathRelative`
    - `markdownReportPathRelative`
    - `jsonReportPathRelative`

## 8. Tools Installed During This Pass

- `pypdf` (installed locally) for PDF text extraction and diff against package behavior.
