# SplitBar

SplitBar is a macOS Dock-replacement project exploring a flatter Windows-style
taskbar, launcher, widgets, calendar, and Quick Settings while retaining native
macOS app launching and panel infrastructure.

## Run the app

Requirements: macOS 15 or later and Xcode with the Swift toolchain.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run
```

The app opens the taskbar design window and adds a menu-bar item. The design
window uses local preview state for appearance and quick-control examples;
pinned applications launch through SplitBar's app-launch service. The existing
edge dock remains available as a fallback from the menu bar while the taskbar
design is being integrated. No real Dock hiding or system-setting mutation is
performed by the design window.

The widget board has an Edit mode for drag reordering and per-widget Small,
Medium, Large, and Extra large sizing; layout choices persist locally. The
launcher supports up to eight pinned apps, and that same pin list drives the
taskbar launch icons. Taskbar icons render as full-height tiles with Small,
Medium, and Large size presets shared with the taskbar weather glyph. A Trash
tile with full/empty state sits beside a Downloads tile; its position (with the
app icons, before the tray, or far right) is a Personalisation setting. Each of
the five flyouts (Start, Widgets, Calendar, Quick Settings, Personalisation)
has a Windows 11-style narrow default width with its own slider back toward the
previous wide layout. Weather includes a 14-day forecast. The launcher shows
background activity separately from the widget board, and its second column
holds a Folders block (Desktop, Documents, Movies, Music, Pictures, Downloads)
that resolves real, iCloud-aware user directories and opens them in Finder.
Desktop wallpaper presets include pastel, ocean, sunset, midnight, graphite, and a
customizable gradient. Personalisation is laid out as a symmetric block grid.
The calendar flyout contains calendar and focus concepts only, not a mirror of
system notifications. macOS does not provide third-party apps a general API to
read or route other apps' notifications into a custom panel; the prototype
keeps those in Notification Center.

## Resource use

SplitBar is designed to stay cheap while idle:

- System metrics, playback, and AI-usage sampling drop to a slow baseline cadence
  when their surfaces are not on screen, and skip entirely when nothing is
  playing. Playback AppleScript runs off the main thread.
- App icons are resolved once through a cache instead of on every view update.
- The taskbar clock only ticks each second when seconds are displayed.
- Slider and colour changes are debounced before they touch `UserDefaults`.

macOS 28 compatibility is not yet verified: this project was last built against
the macOS 27 SDK. The deployment target stays at macOS 15 and the code uses
public API only, with one feature-detected private-framework exception noted in
the build plan.

## Code map

- `Sources/SplitBar/App/` — app lifecycle, runtime controller, and panel wiring.
- `Sources/SplitBar/Stores/` — reducer-driven dock state and actions.
- `Sources/SplitBar/Models/` — dock items, preferences, placement, and view state.
- `Sources/SplitBar/Services/` — app launching, panels, device/system services,
  shortcuts, and persistence.
- `Sources/SplitBar/Views/TaskbarConcept/` — integrated taskbar, launcher, widgets,
  Quick Settings, calendar, and visual customization prototype.

The runtime controller owns the legacy dock state and the taskbar concept's
observable UI state. The concept view is part of the sole `SplitBar` package
target; there is no separate prototype app target.

## Build and migration

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

See [MIGRATION_AND_BUILD_PLAN.md](./MIGRATION_AND_BUILD_PLAN.md) for the
architecture inventory, staged integration plan, validation gates, and rules
for evaluating code from other Dock/taskbar projects.
