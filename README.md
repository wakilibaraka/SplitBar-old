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
