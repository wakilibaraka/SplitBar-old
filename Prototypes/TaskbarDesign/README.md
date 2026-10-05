# Taskbar Design Prototype

This standalone SwiftUI app captures the Windows-inspired taskbar, launcher,
widgets, calendar, Quick Settings, and appearance controls as a visual prototype.
It is intentionally separate from the SplitBar app target and does not hide,
replace, or otherwise control the macOS Dock.

Run from this directory:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run
```

The controls use local mock state. Native system integration should be planned
and reviewed separately before implementation.
