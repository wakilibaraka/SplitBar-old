# SplitBar

A macOS Windows-style taskbar: five taskbar modes (Windows, macOS pill,
Centered, Split 3, Split 4), launcher, widgets, calendar, Quick Settings, and
Personalisation — built native with SwiftUI views hosted in non-activating
`NSPanel` surfaces. The app is an LSUIElement agent (menu-bar item only) that
can optionally hide the real macOS Dock, with full restore on quit, crash
recovery, and a login-time restore helper.

## Run the app

Requirements: macOS 15 or later and Xcode with the Swift toolchain.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/arch -arm64 xcrun swift build
./run.sh        # assembles SplitBar.app (debug) with the restore helper, then opens it
```

`run.sh` builds the debug binary, assembles `SplitBar.app` from `Info.plist`,
copies the `SplitBarDockRestore` helper into `Contents/Helpers`, ad-hoc signs,
and opens the app. `port.py` is a one-shot EdgeDeck→SplitBar rename script kept
for history; it is not part of the build. There is no `.xcodeproj` — SwiftPM is
the canonical build path.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/arch -arm64 xcrun swift test
```

## Current scope

- Taskbar in 5 modes with per-mode trash anchors, dividers, cluster ordering,
  running indicators (dot/dash/highlight, theme-aware or gradient), and 5 icon
  sizes.
- Start launcher (pins, folders, recents, full app catalog), widgets board,
  calendar, Quick Settings, and a 5-tab Personalisation flyout (14 themes,
  corners, flyout animations, height presets, weather-reactive wallpapers,
  onboarding).
- Live data: Open-Meteo weather, Now Playing, running apps with hover previews,
  volume/brightness (incl. DDC), Wi-Fi SSID, Bluetooth, top processes.
- Real-Dock hiding is **opt-in** (`hideMacDock`): the prior Dock state is saved
  to disk before any mutation, restored on quit/SIGTERM/SIGINT, on next launch
  after a crash, and by a login-time helper after SIGKILL. "Quit and Restore
  Dock" in the menu-bar menu is the manual escape hatch.
- Primary display only; multi-display is planned via a DisplayCoordinator.

## Permissions

| Capability | macOS prompt | Used for |
|---|---|---|
| Accessibility | on first minimize-by-click | Minimize windows from the taskbar |
| Screen Recording | on first hover preview | Live window thumbnails (icon fallback otherwise) |
| Location | on first SSID read | Wi-Fi network name |
| Bluetooth | via system prompt | Device list, tap-to-connect |
| DDC (private display API) | none, opt-in toggle | External display brightness, probed at runtime |

## Resource use

SplitBar stays cheap while idle: metrics/playback sampling drops to a slow
baseline when surfaces are off-screen; app icons resolve once through a cache;
the clock ticks per-second only when seconds are shown; slider/colour writes to
`UserDefaults` are debounced.

Built against the macOS 27 SDK, deployment target macOS 15, public API only
(one feature-detected private-framework exception documented in the build plan).

## Code map

- `Sources/SplitBar/App/` — lifecycle, runtime controller, panel wiring.
- `Sources/SplitBar/Services/` — launching, panels, Dock hide/restore, device
  and system services, shortcuts, persistence.
- `Sources/SplitBar/Views/TaskbarConcept/` — taskbar, launcher, widgets,
  Quick Settings, calendar, Personalisation, onboarding, wallpaper engine.
- `Sources/SplitBarDockRestore/` — login-time Dock-restore helper.
- `Reference/` — read-only design inspiration, not a dependency.
- `Tests/SplitBarTests/` — pure-logic tests (layout, dividers, state files).

See [MIGRATION_AND_BUILD_PLAN.md](./MIGRATION_AND_BUILD_PLAN.md) for the
architecture inventory and staged plan. License notes live in
[NOTICE](./NOTICE).
