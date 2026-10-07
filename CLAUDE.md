# SplitBar

A macOS Windows-style taskbar: five taskbar modes, launcher, widgets, calendar,
Quick Settings and Personalisation, built with SwiftUI views hosted in
non-activating `NSPanel` surfaces. The app is an LSUIElement agent (menu-bar item
only) that can optionally hide the real macOS Dock, with full restore on quit,
crash recovery and a login-time restore helper.

For the review-driven improvement backlog, invariants and per-task status, read
[IMPROVEMENT_PLAN.md](./IMPROVEMENT_PLAN.md).

## Stack
- Swift + SwiftUI for views, AppKit (`NSPanel` / `NSHostingView`) for windowing.
- Swift Package Manager is the canonical build; there is no `.xcodeproj`.
  Min target: macOS 15. Zero third-party dependencies.
- Build/test:
  ```sh
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
    /usr/bin/arch -arm64 xcrun swift build -Xswiftc -warnings-as-errors
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
    /usr/bin/arch -arm64 xcrun swift test
  ```
- App bundle: `./scripts/build_app.sh <version> [--release]` (or `./run.sh` for a
  debug wrapper).
- Smoke test (runs the real app): `./scripts/smoke_test.sh [--seconds 8] [--shot out.png]`.
  Launches with `SPLITBAR_SKIP_DOCK=1`, so the real Dock is never touched, and
  asserts the process survives, logs no error or fault, and exits cleanly on
  SIGTERM. Run this after any slice that moves or rewrites code: a build and the
  unit tests cannot catch a panel that never appears. Release artifacts are ad-hoc signed until a Developer ID is
  configured — see IMPROVEMENT_PLAN E1.

## Architecture rules
- App is LSUIElement (no dock icon of its own). Menu-bar item only.
- Surfaces are borderless panels; SwiftUI content is hosted in `NSHostingView`.
- Panels use `collectionBehavior = [.canJoinAllSpaces, .stationary]` so they persist
  across Spaces and stay out of Mission Control.
- **Focus Policy**: taskbar, widgets and flyout panels are non-activating with
  `canBecomeKey = false` so clicking them never deactivates the frontmost app.
  Only launcher/search panels may take key focus (`KeyablePanel`).
- **Panel hosts**: `TaskbarPanelController` (strip or per-island panels keyed by
  display), `FlyoutPanelController`, `EdgePanelController`. Display policy lives
  in `DisplayCoordinator` (primary display only for now).
- **DockController constraints** (never break these):
  - Persist original Dock orientation + autohide state to disk *before* mutating,
    atomically, in a versioned file.
  - On launch, if the saved-state file exists, restore it first (crash recovery).
  - Restore on `applicationWillTerminate`, SIGTERM and SIGINT.
  - `SPLITBAR_SKIP_DOCK=1` bypasses all mutation during development.
  - `SplitBarDockRestore` (a Foundation-only helper) restores after SIGKILL via
    an `SMAppService` login agent, removed on clean restore.
  - Real-Dock changes stay opt-in (`hideMacDock`). Revealing the Dock on
    left/right-edge hover is an accepted tradeoff.
- **Privacy rules**: secrets are never logged, never passed in process arguments
  and never written in plaintext; clipboard history is opt-in and off by default;
  network hosts are inventoried in `NETWORK.md`; logs default to `.private`.

## License rules (WE DISTRIBUTE THIS — DO NOT GET THIS WRONG)
- exelban/Stats is MIT: OK to adapt code with attribution.
- FelixKratz/SketchyBar and koekeishiya/yabai are GPL: STUDY ONLY. Reimplement
  clean. Never paste GPL code into this repo.
- Anything in Reference/ is read-only inspiration, not a dependency.
- Keep every attribution in `NOTICE`.

## Private APIs
- Any private API (SkyLight/SLS, IOBluetooth, NSGlassEffectView) must be isolated
  behind a protocol, feature-detected, opt-in, and flagged in the PR description.
  These are what break notarization later.

## Working style
- One surface / one capability per PR. Vertical slices.
- Keep `-warnings-as-errors` green; never silence a warning with a blanket
  suppression.
- Request permissions lazily, at first use of the feature, never at launch.
- Prefer opt-in defaults for anything that touches user data or the network.