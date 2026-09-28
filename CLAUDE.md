# SplitBar

A macOS "Windows-shell" experience: a floating glass dock + widgets + launcher +
top search, built native. Background agent app that hides the real Dock and floats
its own always-on-top panels.

## Stack
- Swift, SwiftUI for views, AppKit (NSPanel/NSHostingView) for windowing.
- Min target: macOS 14. Enhance with NSGlassEffectView on macOS 26 (feature-detect,
  fall back to NSVisualEffectView).
- Xcode project. Build: `xcodebuild -scheme SplitBar build`. Run from Xcode.

## Architecture rules
- App is LSUIElement (no dock icon of its own). Menu-bar item only.
- All surfaces are borderless panels via `PanelManager`.
- Panels use `collectionBehavior = [.canJoinAllSpaces, .stationary]` so they persist
  across Spaces and stay out of Mission Control.
- Phase 1 targeting: Primary display only.
- SwiftUI content is hosted in `NSHostingView` inside each panel.
- **Focus Policy**: Requires per-panel behavior:
  - Dock / Widgets: Non-activating, `canBecomeKey = false` (clicking the Dock must not deactivate the frontmost app).
  - Search / Launcher: `canBecomeKey = true`, take key on show, resign on ESC.
- **DockController constraints**:
  - Must persist original Dock orientation + autohide state to disk *before* mutating.
  - On launch, if the saved-state file exists, restore it first (crash recovery).
  - Restore on `applicationWillTerminate` and trap `SIGTERM`/`SIGINT`.
  - Provide a dev flag to bypass Dock manipulation (prevents flickering `killall Dock` during rapid iteration).
  - (Note: The real Dock revealing on left/right-edge hover is an accepted Phase 1 tradeoff).

## License rules (WE DISTRIBUTE THIS — DO NOT GET THIS WRONG)
- exelban/Stats is MIT: OK to adapt code with attribution.
- FelixKratz/SketchyBar and koekeishiya/yabai are GPL: STUDY ONLY. Reimplement
  clean. Never paste GPL code into this repo.
- Anything in Reference/ is read-only inspiration, not a dependency.

## Private APIs
- Any private API (SkyLight/SLS, IOBluetooth, NSGlassEffectView) must be isolated
  in Core/ behind a protocol, feature-detected, and flagged in the PR description.
  These are what break notarization later.

## Working style
- One surface / one capability per PR. Vertical slices.
- Phase 1 is SKELETON ONLY: placeholder data, no real system integration beyond
  launching pinned apps and hiding the Dock. Do not wire real CPU/weather/calendar/
  search data — that's Phase 2.
