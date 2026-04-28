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

## Current Outcome
- Config-driven migration has entered executable skeleton phase for both:
  - bottom navigation
  - home tab layout
- Android/iOS/Windows compatibility strategy remains:
  - shared Dart runtime parser + per-platform adapter execution
  - fallback-safe behavior when target capability is not available
