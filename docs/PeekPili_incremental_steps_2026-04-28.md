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
