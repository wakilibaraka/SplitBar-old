# SplitBar

A macOS Windows-style taskbar: five taskbar modes (Windows, macOS pill,
Centered, Split 3, Split 4), launcher, widgets, calendar, Quick Settings, and
Personalisation — built native with SwiftUI views hosted in non-activating
`NSPanel` surfaces. The app is an LSUIElement agent (menu-bar item only) that
can optionally hide the real macOS Dock, with full restore on quit, crash
recovery, and a login-time restore helper.

## Build and run

Requirements: macOS 15 or later, Xcode with the Swift toolchain, and an arm64
shell (prefix commands with `/usr/bin/arch -arm64` if yours runs under Rosetta).

```sh
./run.sh                              # assemble and open a debug bundle
./scripts/build_app.sh 0.3.0 --release   # shippable build
open SplitBar.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  /usr/bin/arch -arm64 xcrun swift build -Xswiftc -warnings-as-errors
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  /usr/bin/arch -arm64 xcrun swift test
```

`scripts/build_app.sh` builds both binaries, injects the version into
`Info.plist`, assembles `SplitBar.app` (app, `Contents/Helpers` restore helper,
`Resources/AppIcon.icns`, `Contents/LoginItems` agent plist), and in release mode
maps build paths out of the binary, strips it, deletes the Xcode rpath, and signs
the helper with a stable identifier. Debug bundles keep symbols and local paths
and must not be distributed.

There is no `.xcodeproj` — SwiftPM is the canonical build path, and there are no
third-party dependencies. `tools/legacy/port_from_edgedeck.py` is a historical
script, not part of the build.

Until a Developer ID is configured, artifacts are ad-hoc signed and will trigger
Gatekeeper on other Macs (`IMPROVEMENT_PLAN.md` E1).

## Current scope

- Taskbar in 5 modes with per-mode trash anchors, dividers, cluster ordering,
  running indicators (dot/dash/highlight, theme-aware or gradient), and 5 icon
  sizes.
- Start launcher (pins, folders, recents, full app catalog), widgets board,
  calendar, Quick Settings, and a 6-tab Personalisation flyout (14 themes,
  corners, flyout animations, height presets, weather-reactive wallpapers,
  onboarding, and a Privacy & data page).
- Live data: Open-Meteo weather, Now Playing, running apps with hover previews,
  volume/brightness (incl. DDC), Wi-Fi SSID, Bluetooth, top processes.
- Real-Dock hiding is **opt-in** (`hideMacDock`): the prior Dock state is saved
  to disk before any mutation, restored on quit/SIGTERM/SIGINT, on next launch
  after a crash, and by a login-time helper after SIGKILL. "Quit and Restore
  Dock" in the menu-bar menu is the manual escape hatch.
- Primary display only; multi-display is planned via a DisplayCoordinator.
- Privacy defaults are opt-in: clipboard history off, IP geolocation off,
  third-party favicons off, and reading Claude Code / Codex credentials off.
  With those defaults the app contacts only the weather service and the sites
  you pinned. See `NETWORK.md` and Personalisation → Privacy.

## Permissions

| Capability | macOS prompt | Used for |
|---|---|---|
| Accessibility | on first minimize-by-click | Minimize windows from the taskbar |
| Screen Recording | on first hover preview | Live window thumbnails (icon fallback otherwise) |
| Location | on first SSID read | Wi-Fi network name |
| Bluetooth | via system prompt | Device list, tap-to-connect |
| DDC (private display API) | none, opt-in toggle | External display brightness, probed at runtime |

Every permission the app can trigger, its live status, and what leaves the Mac
are listed in **Personalisation → Privacy**. Permissions are requested at first
use of a feature, never at launch.

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
- `scripts/` — bundle assembly and the logging-privacy lint.
- `Reference/` — read-only design inspiration, not a dependency; see its README.
- `NETWORK.md` — every host the app contacts, why, and the setting that gates it.
- `IMPROVEMENT_PLAN.md` — the review backlog, invariants, and per-task status.
- `Tests/SplitBarTests/` — pure-logic tests (layout, dividers, state files).

See [MIGRATION_AND_BUILD_PLAN.md](./MIGRATION_AND_BUILD_PLAN.md) for the
architecture inventory and staged plan. License notes live in
[NOTICE](./NOTICE).
