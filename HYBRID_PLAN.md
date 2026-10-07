# SplitBar Hybrid Architecture: Next-Gen Shell & Theming Plan

Status: IN PROGRESS · Saved 2026-10-08 · Owner-approved direction.

> Note: this is **not** `SPLITBAR_HYBRID_PLAN.md` (the older three-repo merge
> plan). This document is the AppKit + SwiftUI hybrid direction for *this*
> repo: shell mechanics in AppKit, faces in SwiftUI, theme decoration in a
> Core Graphics `LayerFX` engine.

## 1. Executive Summary & Core Objectives

SplitBar is evolving from an all-SwiftUI prototype into a **Pragmatic Hybrid
(AppKit + SwiftUI) Desktop Shell**.

While SwiftUI provides unmatched developer velocity for menus, forms, and
reactive data flow, an OS-level taskbar with extreme stylistic fidelity
requires the low-level rendering precision of **`CALayer`**, Core Graphics
(**`CGContext`**), and AppKit (**`NSPanel`**).

### Primary Objectives

1. **Zero-Glitch Shell Mechanics:** window tracking, panel lifecycle, and
   desktop struts in native AppKit to eliminate focus glitches, click-through
   issues, and multi-monitor stutter.
2. **Hardware-Accelerated Visual Fidelity:** a `LayerFX` engine using
   `CALayer`/Core Graphics via `NSViewRepresentable` — authentic Neumorphism
   (true dual-directional inner shadows), Windows Aero (specular reflections
   and hover glows), Windows 98 (pixel-perfect 3D bevels).
3. **Modular Taskbar Island Architecture:** break the rigid taskbar into
   independent, pluggable, reorderable modules (Start, Apps, Status Tray,
   Clock, Widgets).

### Division of Labor

```
AppKit (The Engine)
  • Floating desktop panels (zero-glitch, all Spaces)
  • Window focus & mouse click handling
  • CALayer / CGContext (hardware-accelerated shadows & 3D bevels)
        │ hosts via NSHostingView
SwiftUI (The Face)
  • Settings Flyout & Personalisation UI
  • Start Menu grid & search
  • Reactive state (changing a theme updates instantly)
```

## 2. Pillar 1: Modular Taskbar Architecture

Refactor `TaskbarStripViews.swift` (937 lines) from mixed layout/section
conditional trees into a **Slot-and-Module Architecture**.

### 2.1 Island Module Protocol

```swift
public protocol TaskbarIslandModule: View {
    var id: String { get }
    var preferredAlignment: IslandAlignment { get } // .leading, .center, .trailing
    var intrinsicWidth: CGFloat? { get }
    var dragOrderIndex: Int { get set }
}
```

### 2.2 Decoupled Modules

* **`StartIsland`** — Start button, search trigger, OS emblems.
* **`AppTilesIsland`** — pinned/running apps, badges, jump-lists, dots.
* **`SystemTrayIsland`** — Wi-Fi, Bluetooth, battery, volume, input, status.
* **`ClockIsland`** — time, date, notification bell, calendar trigger.
* **`WidgetIsland`** — weather badge, now-playing pill, telemetry.

### 2.3 Dynamic Layout Engine

`ModularTaskbarContainer` arranges active modules per layout mode:

* **Unified Floating** — one continuous surface shell.
* **Split Islands** — each module its own floating shell + spacing.
* **Windows Edge** — edge-to-edge docked strip.

## 3. Pillar 2: The `LayerFX` Engine (Phase 2 — DONE)

`LayerFXView` (`NSViewRepresentable`) renders in-bounds theme decoration with
Core Graphics, one pass per layout change:

| Theme | `LayerFX` technique |
| :--- | :--- |
| **Neumorphism** | inverted-clip dual-axis inner shadows (light top-left, dark bottom-right) + extruded drop shadows in SwiftUI |
| **Windows Aero** | 45° diagonal specular sweep gradient + 1 pt bright inner glass ridge |
| **Windows 98** | crisp four-tone bevel: `#FFFFFF` / `#DFDFDF` / `#808080` / `#000000`, antialiasing off, sRGB-explicit tones |
| **Claymorphism** | specular top highlight + bottom rim light vertical fades |
| **Neobrutalism** | 2–3 pt solid black borders; hard offset shadow (radius 0, offset 4) in SwiftUI |

Design contract:

* **Fills stay in SwiftUI** (`GlassProvider`); outer drop shadows stay in the
  SwiftUI surface modifiers. LayerFX draws *in-bounds decoration only*.
* Spec is pure/`Equatable` (`LayerFXSpec`); renderer is pure `CGContext`
  (`LayerFXRenderer`), testable via bitmap rasterization.
* Screen coords y-down in the spec, converted to CG y-up for shadow offsets.
* **Kill switch:** `SPLITBAR_LAYERFX=0` env or `layerfx.enabled` UserDefaults
  (default true) reverts every surface to the legacy SwiftUI rendering.
* Hookup: all three modifiers in `SurfaceModifiers.swift`
  (`.flyoutSurface` / `.widgetCard` / `.taskbarSurface`) consume
  `LayerFX.activeSpec(...)`; legacy stroke/gradient overlays remain behind
  `layerFX == nil`.

## 4. Pillar 3: AppKit Window & Shell Hardening (Phase 3 — TODO)

1. **Window levels & collections:** taskbar `NSPanel.level = .floating`;
   `collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle,
   .fullScreenAuxiliary]`. (Audit anchor: `taskbarStripCollectionBehavior()`
   in `Support/PanelGeometry.swift` currently omits `.fullScreenAuxiliary`
   vs `edgePanelCollectionBehavior()`.)
2. **Key window & focus:** taskbar strictly non-activating
   (`canBecomeKey = false`); flyouts take key only while open, dismiss on
   `resignKey()`.
3. **Multi-monitor sync:** hook `NSApplication.didChangeScreenParametersNotification`
   to re-anchor islands without screen flash or coordinate drift.

## 5. Phase 4: Theme Expansion & Polish (TODO)

* Remaining visual-atlas styles: Skeuomorphism (stitched leather/paper), Aqua
  (gel/candy), Frutiger Aero (glossy nature glass), Y2K (chrome/metal).
* Final smoke tests + Instruments profiling (Core Animation FPS, memory).

## 6. Phased Roadmap & Status

| Phase | Scope | Status |
| :--- | :--- | :--- |
| 1 | Taskbar modularization (`StartIsland` etc. + `ModularTaskbarContainer`) | TODO |
| 2 | `LayerFX` surface engine + `SurfaceModifiers` hookup | **DONE** (build green, 88 tests) |
| 3 | Shell & panel hardening audit | TODO (pre-findings above) |
| 4 | Theme expansion + Instruments profiling | TODO |
