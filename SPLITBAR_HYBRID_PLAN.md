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

## 5. What ports vs. what stays

| From SplitBar-old (port) | From DockBar (keep as base) |
|---|---|
| `TaskbarMode` → `BarLayoutMode` (4 required cases) | All of `Sources/DeskBar` (window mgmt, AX, tray, launcher) |
| `TaskbarSection` + `islands(for:)` | `TaskbarStyleSpec` / `TaskbarLayoutStrategy` (6 styles) |
| `TaskbarStrip.layoutIslands` → `IslandLayoutSolver` | `TaskbarPanel` + `BarPanelLayout` (edges, float, hug) |
| Per-island panel controller logic | `FlyoutPanel`, `QuickSettings`, `Launchpick`, `DockManager` |
| `TaskbarStrip.pruned` divider composition (later, if dividers wanted) | `WeatherService` (Open-Meteo), calendar, connectivity |
| Mode picker thumbnails/onboarding re-drawn in AppKit | `SettingsWindowController` + searchable settings (add a "Layout" page) |
| Tests: `TaskbarStripTests` island/overflow cases | Existing `DeskBarTests` (style specs, planners) |

**Not ported** (superseded or out of scope): SplitBar's SwiftUI themes/wallpaper
engine/personalisation flyouts, its `splitbar.html` prototype, its Dock-restore helper
(DockBar's `DockManager` covers hide/restore), ProcessRunner/secrets/AI-usage/clipboard
features (unrelated to the splitter). SplitBar's visual themes can become phase 7 later as
AppKit appearance tokens if wanted.

## 6. Build & identity

- New repo: `Splitbar` (proposal: bundle id `com.splitbar.app`, product `Splitbar`).
- SwiftPM package (no `.xcodeproj`), swift-tools 6.0 / language mode v5 like SplitBar-old,

## 7. Phases (each = shippable, testable slice)

**Phase 0 — Bootstrap**
- Create repo, import DockBar `main` as the baseline (clean, in sync with origin).
- Rename `DockBar` → `Splitbar` (target, bundle id, `Sources/DeskBar` → `Sources/SplitBar`,
  uninstall strings). Build green: `swift build && swift test`.

**Phase 1 — Layout model (pure, no UI)**
- Add `BarLayoutMode`, `BarSection`, `IslandLayoutSolver` (port of `layoutIslands`).
- Port/adapt `TaskbarStripTests` island cases: islands-per-mode coverage, every section in
  some island, in-screen bounds, crowded-apps overflow.
- Add `layoutMode` field to `TaskbarStyleSpec` + resolution helper + equality update.

**Phase 2 — Sectioned content view**
- Refactor `TaskbarContentView` to take a `BarSection` set; extract `WeatherZoneView`,
  `TrayZoneView`, `ClockZoneView` hosts around the existing widget views.
- Widget placement resolution rule (§4) + tests.
- Everything still renders in one strip panel — visually unchanged.

**Phase 3 — Multi-panel islands**
- `BarLayoutController` replaces the flat `panels` dictionary; strip → islands rebuild;
  weather-left / apps-center / tray-right frame math per mode.
- Island chrome (rounded, gap, shadow), fullscreen hiding across all panels, screen-change
  re-layout (reuse `TaskbarScreenMode`).
- Wire the 4 modes behind a hidden `barLayoutMode` defaults key for dogfooding.

**Phase 4 — Mode picker & settings**
- Settings page "Layout": 4 mode cards with live mini-previews (extend
  `TaskbarStylePreviewView` to draw from `IslandLayoutSolver` — preview = real geometry),
  centered-width slider (`centeredWidth`, persisted), gap/inset knobs.

## 8. Risks & open questions

| Risk | Mitigation |
|---|---|
| Coordinate-space mismatch porting `layoutIslands` (SplitBar is SwiftUI/screen-absolute) | Unit-test island frames against DockBar's `BarPanelLayout` output on a synthetic 1728×1117 screen before wiring UI (Phase 1). |
| `TaskbarContentView` refactor regressions (2,400 lines of ordering/grouping logic) | Phase 2 keeps single-strip rendering; visual diff before Phase 3; existing `DeskBarTests` must stay green. |
| Menu-bar vs bar widget placement flips for existing DockBar installs | Explicit rule in `WidgetPlacement.resolve` (§4) + migration stamp, mirroring the v0.6 pattern already in that file. |
| More panels → idle CPU cost | Max 4 panels/display; panels share services, no duplicated timers; verify with DockBar's existing off-screen reduction in Phase 3. |
| Scope creep from SplitBar's 7.5k-line monolith | Port *algorithms only* — §5 table is the allow-list. |
| License mixing | Combined `NOTICE` (§6); both sides MIT, attribution carried verbatim. |

**Open question for owner (non-blocking):** final app/repo name and bundle id — plan
assumes `Splitbar` / `com.splitbar.app`.

## 9. Acceptance criteria

1. All four required modes render on the built-in display, switchable from Settings without
   relaunch, persisted across restarts.
2. `swift build` and `swift test` green with the ported island tests + all DockBar tests.
3. Islands are non-activating, survive Space switches, hide for fullscreen, and reflow on
   resolution change; flyouts anchor to their own island.
4. Dock hide/restore, window switching, launcher, quick settings behave exactly as DockBar
   does today (no regression).
5. NOTICE covers both codebases; no GPL code; zero third-party dependencies.

## References

- SplitBar-old: `Sources/SplitBar/Views/TaskbarConcept/TaskbarConceptView.swift`
  (`TaskbarMode`, `TaskbarSection.islands(for:)`, `TaskbarStrip.layoutIslands`),
  `Sources/SplitBar/Services/TaskbarPanelController.swift`,
  `Tests/SplitBarTests/TaskbarStripTests.swift`.
- DockBar: `Sources/DeskBar/Models/TaskbarStyleSpec.swift`, `TaskbarLayoutStrategy.swift`,
  `TaskbarSettings.swift`, `BarEdge.swift`, `WidgetPlacement.swift`,
  `Sources/DeskBar/Views/TaskbarPanel.swift`, `TaskbarContentView.swift`, `FlyoutPanel.swift`,
  `Sources/DeskBar/App/AppDelegate.swift` (panel dictionary).
- Screenshots (owner's Desktop): `Screenshot 2026-10-06 at 02.03.12.png` (split-3 target),
  `Screenshot 2026-10-06 at 00.15.28.png` / `...00.46.50.png` (Windows full / mode picker),
  `Screenshot 2026-10-07 at 07.16.08.png` (onboarding), weather/widgets flyout shots.

- Onboarding: port SplitBar's "Pick a layout" step in AppKit (reference screenshots:
  `Screenshot 2026-10-06 at 02.03.12.png`, `...00.15.28.png`).

**Phase 5 — Visual parity with the reference**
- Rounded island surfaces matching the reference shots (floating split-3: weather pill left,
  centered app icons, tray+clock pill right — `Screenshot 2026-10-06 at 02.03.12.png`),
  icon sizing presets, running-indicator styles per mode, corner/material tokens.
  macOS-style icons — DockBar already uses real app icons, keep.
- Menu-bar-only agent behaviour; Dock hide opt-in (`DockManager`
  independent/autoHide/hidden already matches SplitBar's `hideMacDock` contract).

**Phase 6 (optional)** — `macOS` pill mode, SplitBar-style dividers (data + orphan
pruning), widgets board / personalisation ports.

  **platforms: macOS 14+** (DockBar's floor; raise only if a 15-only API is adopted).
- Targets: `Splitbar` (app), `SplitbarTests`. Reuse DockBar's `scripts/package.sh` +
  `Info.plist.template`, renamed to `Splitbar.app`.
- Zero third-party dependencies — preserved.
- **Licensing (must-do)**: combined `NOTICE` containing:
  - SplitBar-old MIT © 2026 senoldogann + its Status Trio (Apache-2.0 inspired) and
    AppleSiliconDDC MIT attribution lines — carried over verbatim when porting code.
  - DockBar/DeskBar MIT attribution (rajeshgoli/deskbar lineage, wakilibaraka/dockbar).
  - Keep DockBar's license rules: SketchyBar/yabai remain study-only; Stats is MIT-ok.

