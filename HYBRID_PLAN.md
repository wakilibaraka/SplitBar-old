# SplitBar Hybrid Plan — Chunked Roadmap (v2)

Status: **WAVES 1–7 IMPLEMENTED · 2026-10-08** (commit on
`integrate-taskbar-prototype`). Per-chunk verification: `-warnings-as-errors`
build + full `swift test` + `smoke_test.sh` green after every wave.

> Note: this is **not** `SPLITBAR_HYBRID_PLAN.md` (the older three-repo merge
> plan). This document is the AppKit + SwiftUI hybrid direction for *this*
> repo: shell mechanics in AppKit, faces in SwiftUI, theme decoration in a
> Core Graphics `LayerFX` engine.

**Decisions locked:** 5 islands (Start / AppTiles / StatusTray / Clock /
Widget); maximize = window frame inset so the taskbar stays visible.

**Contracts never broken:** `TaskbarPanelPlanTests` (panel lifecycle),
`-warnings-as-errors`, LayerFX kill switch (`SPLITBAR_LAYERFX=0`), lazy
permissions, no secrets/window titles in logs.

---

## Wave 1 — Modular taskbar (Phase 1) ✅

- [x] **A1** — `TaskbarStripViews.swift` split 937 → 151 lines (facade) with
  `TaskbarStrip/Islands/{StartIsland,AppTilesIsland,StatusTrayIsland,ClockIsland,WidgetIsland}.swift`
  + `TaskbarTiles.swift`. Zero behavior change; tests green.
- [x] **A2** — `ModularTaskbarContainer` routes `.docked`/`.floating`/`.split`.
  Split islands are self-sizing `HStack` rows (user `islandGap` spacing, one
  `.taskbarSurface` per island); the old `TaskbarSplitRow` CGRect/offset math
  is gone. `TaskbarStripMetrics` remains for *capacity* + live panel frames
  (AppKit geometry, not view layout).
- [x] **A3** — `LayoutTokens` (8pt grid): islandInner=8, barOuter=16,
  docked=8, trailingTray=12, dividerGutter=8; live per-island panel padding
  uses the same token.
- [x] **A4** — `ModularLayoutTests`: mode routing, island composition per
  mode, token grid invariants. 93 → then 101 tests.

## Wave 2 — Platform/Core/UI (Tungsten Edge 3-tier) ✅

- [x] **B1** — folders: `Platform/` (WindowManager, Dock, Display, panels,
  Fullscreen, tooltip), `Core/` (TaskbarState, StripModel,
  ConfigurationPersistence), `UI/TaskbarConcept/` (islands, flyouts,
  DesignSystem). Single SPM target; folder = boundary.
- [x] **B2** — `Platform/WindowTracking.swift` protocol over AX
  (`frontmostWindowFrame`, `setFrontmostWindowFrame`, raise/minimize/tile);
  `WindowManagerService` is the single implementation. Private/undocumented
  APIs stay behind this seam.

## Wave 3 — Shell hardening (Phase 3) ✅

- [x] **C1** — `taskbarStripCollectionBehavior()` gained
  `.fullScreenAuxiliary` (parity with edge panels); audit table below.
  `PanelBehaviorTests` locks the parity.
- [x] **C2** — one shared rule `FlyoutDismissal.shouldDismiss(location:protected:)`
  used by *all four* monitor paths; taskbar flyout gained a **local mouse
  monitor** (own-app clicks) and **`resignKey` dismissal**
  (`KeyablePanel.onResignKey` → `openPanel = nil`). 6 unit tests.
- [x] **C3** — `didChangeScreenParametersNotification` → re-anchors open
  flyout (`syncTaskbarFlyout`) + edge dock (`syncPanels`) in place; strip
  already refreshes via `DisplayCoordinator`. 2 notification tests.

## Wave 4 — Maximized-window avoidance ✅

- [x] **D1** — `WindowTilingGeometry.calculateCocoaTargetFrame(..., bottomStrut:)`:
  `.maximize` reserves the strip band; other actions unchanged (4 tests).
  `WindowManagerService.bottomStrut` closure wired to the live strip frame,
  gated on the toggle, primary-screen only.
- [x] **D2** — `ZoomAvoidanceObserver` (AX: window created/resized/moved on
  the frontmost app) + pure `ZoomAvoidance` detection (7 tests incl. the
  no-loop guarantee). Toggle **"Maximize keeps taskbar visible"** in the
  taskbar context menu, default **on**, persisted
  (`taskbar.maximizeAvoids`). Observer attaches on *activation* (never at
  launch); the Accessibility prompt fires only when the user flips the
  toggle (lazy first use).
- [x] **D3** — `FullscreenMonitor` untouched; smoke green.

## Wave 5 — LayerFX parity + per-panel ✅

- [x] **E1** — `LayerFX.State {normal, pressed, hover}` through
  `spec`/`activeSpec` and all three modifiers (`layerFXState` param,
  default `.normal`). Neumorphism `.pressed` inverts the dual band (surface
  sinks); Aero `.hover` adds an in-bounds radial specular glow. Kill switch
  covers states.
- [x] **E2** — each island renders its own `LayerFXView` post-A2; test proves
  independent specs + equality contract.
- [x] **E3** — `LayerFXNSView` same-spec assignment requests **zero** redraws
  (layer `needsDisplay` test); different spec requests one.

## Wave 6 — Theme expansion (Phase 4) ✅

- [x] **F1** — Skeuomorphism (dual shading + dashed inset **stitch**, renderer
  dash test) and Aqua (gloss cap + inner ridge + rim light, bitmap test)
  now render through LayerFX.
- [x] **F2** — Frutiger Aero (deterministic water-drop glints, sparkle test)
  and Y2K (diagonal iridescent chrome ring, blue-dominance test).

> **Deviation from the original plan text:** the theme *cases* for these four
> already existed in `SurfaceStyle` (the 16-theme contract is unchanged);
> what they lacked was LayerFX ownership, which is what F1/F2 delivered.
> LayerFX now owns **9 of 16** styles; the rest keep legacy SwiftUI strokes.

## Wave 7 — Micro-interactions + previews ✅

- [x] **G1** — running-indicator pill springs in on app launch
  (scale+opacity transition, `MotionTokens.spring(0.3/0.6)`), disabled under
  Reduce Motion (`model.reduceMotion` threaded into `TaskbarTiles`).
- [x] **G2** — tile press/hover springs moved into
  `MotionTokens.spring(response:dampingFraction:reduceMotion:)` with
  `accessibilityReduceMotion` read from the environment.
- [x] **H1** — *verified already implemented*: `AppWindowPreviewService`
  captures live `SCScreenshotManager` thumbnails per window; preview card
  shows up to 6 windows, title + click-to-select (switch), icon fallback.
- [x] **H2** — *verified*: capture starts only when the preview opens
  (hover-driven, never at launch); denial shows "Grant Screen Recording for
  live thumbnails."; **no window titles or images are ever logged** (grep-
  verified; the only title log carries `privacy: .private`).

## Wave 8 — Measure (Phase 4 tail)

- [~] **I1 · partial (headless baseline done; GUI Instruments session
  pending)** — automated micro-benchmark recorded:
  - **LayerFX render cost: 492.8 µs/spec** (600×80 panel, neumorphism dual
    inner shadows, *debug* build — release will be lower; benchmark:
    `LayerFXBenchmarkTests`, prints, no flaky assertion).
  - Test suite: **124 tests in 0.62 s**; smoke test PASS (launch → 6 s →
    clean SIGTERM).
  - **Manual checklist for the Instruments session** (needs GUI):
    Core Animation FPS while switching all 9 LayerFX themes on a flyout;
    FPS while dragging the split-bar resize handle; memory (leaks) over
    10 min with previews hovering; Space-switch frame time. Record numbers
    here; any regression fails the wave.

---

## Appendix · NSPanel audit table (C1, done)

| Panel | File | level | collectionBehavior | canBecomeKey | hidesOnDeactivate |
|---|---|---|---|---|---|
| Taskbar strip (`NonActivatingTaskbarPanel`) | Platform/TaskbarPanelController | .floating | all four incl. **`.fullScreenAuxiliary` (fixed)** | false / main false | false |
| Taskbar flyouts (`KeyablePanel`) | Platform/FlyoutPanelController | .floating | all four | true (search input) | false |
| Edge dock + activation handle | Platform/EdgePanelController | .floating | all four | false (borderless) | false |
| Dock tooltip | Platform/DockTooltipPanelController | .popUpMenu | all four (inline) | false | false |

## Appendix · I1 Instruments checklist

See Wave 8. Baseline: 492.8 µs/spec render (debug), 124 tests/0.62 s,
smoke PASS. GUI numbers TBD.
