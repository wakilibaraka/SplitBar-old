# Splitbar — Hybrid Merge Plan (DeskBar base + SplitBar split modes)

Status: PLANNED · Date: 2026-10-07
Decisions locked with the owner:

1. **New repo from scratch** (not a branch of either project) — working name `Splitbar`.
2. **Pure AppKit** core (DockBar-style `NSPanel` + `NSStackView` zones). No SwiftUI in the
   bar itself; SwiftUI may still appear inside settings windows if convenient, but the bar,
   islands and flyouts are AppKit.

---

## 1. Goal

A macOS dock/taskbar replacement called **Splitbar** whose bar can render in four layouts
(taken from SplitBar-old, see `Sources/SplitBar/Views/TaskbarConcept/TaskbarConceptView.swift`):

| Mode | Layout | Sections (left → right) |
|---|---|---|
| `windows` | **Windows full** — full-width strip | `[weather] … [apps centered] … [tray, clock]` |
| `split3` | Floating islands ×3 | `[weather]` `[apps]` `[tray, clock]` |
| `split4` | Floating islands ×4 | `[weather]` `[apps]` `[tray]` `[clock]` |
| `centered` | Narrow, width-adjustable centered bar | `[weather, apps, tray, clock]` (hug/centered) |

Optional phase-6 extra (present in SplitBar-old, not required by the brief): `macOS`
pill/dock mode — DockBar's existing `mac`/`floatingCenter` styles already cover most of it.

Base architecture = **DeskBar/DockBar** (`~/dockbar`, `wakilibaraka/dockbar`, a fork of
rajeshgoli/deskbar): window management, per-window task buttons, launcher, tray, quick
settings, thumbnails, multi-monitor, settings window. SplitBar-old contributes the
**splitter**: section/island model, island geometry, per-island panels, mode picker UI.

## 2. Why this split of work

- DockBar already owns the hard, mature parts: `WindowManager` (AX + CGWindowList),
  `TaskbarLayoutStrategy`/`TaskbarStyleSpec` (data-driven styles), `TaskbarPanel` (one per
  display, edge-aware `BarPanelLayout`), `FlyoutPanel` (anchors `relativeTo:of:` any view —
  works unchanged for islands), `WidgetPlacement`, `QuickSettings`, `Launchpick`,
  `WeatherService` (Open-Meteo), `CalendarTrayButton`, `ConnectivityTrayView`,
  `WindowsTrayClusterView`, `DockManager` (Dock hide/restore), `UpdateService`.
- SplitBar-old already solved the splitter: `TaskbarSection` (weather/apps/tray/clock),
  `TaskbarSection.islands(for:)`, pure `TaskbarStrip.layoutIslands(...)` with overflow
  collapsing, `TaskbarPanelController` managing `displayID#index` panels, and the mode
  picker/onboarding thumbnails. All of it is pure logic + thin panels → portable to AppKit.
- SplitBar-old is one 7,567-line SwiftUI file (`TaskbarConceptView.swift`) — port its
  *algorithms and model*, not its structure.

## 3. Naming (avoid the collision)

## 4. Target architecture

```
AppDelegate
 ├─ BarLayoutController            (NEW — port of SplitBar TaskbarPanelController logic)
 │    ├─ panels: [displayID: [IslandSlot: TaskbarPanel]]
 │    │     IslandSlot == 0 → the single "strip" panel (windows/centered modes)
 │    │     IslandSlot 0..n → one panel per island (split3/split4)
 │    ├─ IslandLayoutSolver        (NEW — pure, testable geometry; port of TaskbarStrip.layoutIslands)
 │    └─ applies frames from BarPanelLayout + island frames, per screen
 ├─ TaskbarContentView (refactored)
 │    ├─ now renders a *subset* of sections: BarSectionSet (its slot's sections)
 │    ├─ WeatherZoneView   ← existing WeatherWidgetView (forced .dock placement)
 │    ├─ AppsZoneView      ← launcher + WindowsTrayClusterView + task zone
 │    ├─ TrayZoneView      ← ConnectivityTrayView + battery + quick settings
 │    └─ ClockZoneView     ← CalendarTrayButton
 └─ everything else unchanged (WindowManager, flyouts, quick settings, settings, dock hide)
```

Key mechanics:

- **Panel keys**: `"#<displayID>#<slot>"`, mirroring SplitBar's `"displayID#index"`.
  Mode switch = rebuild the panel set (cheap; SplitBar does exactly this in
  `TaskbarPanelController.show(_:)`).
- **Island chrome**: each island panel is its own `NSPanel` with rounded
  `NSVisualEffectView` chrome, `collectionBehavior = [.canJoinAllSpaces, .stationary]`,
  non-activating (`canBecomeKey = false`), level `.statusBar` — DockBar's `TaskbarPanel`
  already does all of this; islands only change the frame + corner radius (its `isFloating`
  path already exists).
- **Geometry**: port `IslandLayout.layout(...)` inputs from SplitBar
  (`screenWidth, tileStride, appCount, weatherWidth, trayWidth, clockWidth, clusterWidth,
  gap, margin, barHeight, bottomMargin`) and output AppKit screen coordinates.
  ⚠️ Coordinate check: SplitBar frames measure `y` from the screen **bottom**
  (`bottomMargin`), and DockBar's `BarPanelLayout` also uses screen coords with origin at
  bottom-left — verify with a test before trusting it (see §8 risks).
- **Horizontal distribution**: DockBar's `TaskbarContentView` already has
  `leftTaskZoneStackView / neutralTaskZoneStackView / rightTaskZoneStackView` plus
  flexible cluster spacers — the weather-left / apps-center / tray-right plumbing is
  half-built; the refactor promotes those to per-slot zone hosts.
- **Overflow**: port the "shrink visible app tiles until they fit, set `showsOverflow`"
  loop from `layoutIslands`.
- **Flyouts**: unchanged — `FlyoutPanel.show(contentViewController:relativeTo:of:)` anchors
  to whichever island view asks, so the weather flyout opens from island 1 and the calendar
  from island 4 automatically.
- **Fullscreen**: DockBar hides panels when a fullscreen window covers a screen — apply the
  same rule to every island panel of that screen (SplitBar's `FullscreenMonitor` behaviour).
- **Widget placement**: in the four layout modes the weather, tray and calendar widgets are
  **forced into the bar** regardless of their `WidgetPlacement` menu-bar default (v0.6
  installs keep menu-bar placement only when layout mode resolves to a plain single-strip
  style). This must be an explicit resolution rule in `WidgetPlacement.resolve`, not a
  silent default flip.


Both projects define `TaskbarMode` with different meanings. In the new repo:

- `TaskbarMode` → **keep DockBar's meaning** (style: custom/windows/mac/classic/eskele/hybrid).
- SplitBar's mode → **`BarLayoutMode`**: `windows | split3 | split4 | centered` (+ optional `macOS`).
- SplitBar's `TaskbarSection` → **`BarSection`**: `weather | apps | tray | clock`.
- SplitBar's `TaskbarStrip.layoutIslands` → **`IslandLayoutSolver.layout(...)`**.

Conceptually: *style × layout mode × edge* are three independent axes.
`TaskbarStyleSpec` gains a `layoutMode` override field (same pattern as its existing
`layoutMode`/`edge`/`dockPosition` overrides).
