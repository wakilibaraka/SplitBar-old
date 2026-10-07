# SplitBar — Settings Unification Plan

Goal: one settings surface for a concise, coherent SplitBar that contains both
the EdgeDeckBar (edge dock) and the bottom Splitbar; no duplicate tabs; one
theme engine.

## Atlas: where the duplication lives (verified in code)

Two settings windows exist today:

- **Legacy `SettingsView`** — opened from menu → Settings... →
  `AppRuntimeController.openSettingsWindow()`. Sidebar tabs:
  General, Dock, Appearance, Shortcuts, Clipboard, Widgets, Privacy,
  Backup, Diagnostics. Controls the legacy EdgeDeck (`EdgeDockView` via
  `isLegacyEdgeDockEnabled`, `syncPanels` gated at the call site, magnifier,
  placement icon size, autohide) and the clipboard/diagnostics knobs.
- **New `SettingsFlyout`** “Personalisation” — opened from the live bar's gear.
  Tabs: Taskbar, Themes, Widgets & Wallpaper, Flyouts, Advanced, Privacy.
  Driven by the new `TaskbarConceptState` and the `SurfaceStyle` theme model.

Duplicated today (must collapse): Privacy, Widgets, Appearance↔Themes,
Shortcuts↔Advanced·hotkeys, clipboard gates. The legacy window renders as a
native System Settings view while the new one is a dark card, so the app
visually forks too.

## Guiding decisions

- **One canonical settings surface:** `SettingsFlyout` survives and absorbs the
  useful legacy controls. `SettingsView` (and its `SettingsTab` enum) is deleted.
- **Both products remain:** EdgeDeckBar stays as an edge dock and is enabled by
  an explicit toggle, and the bottom Splitbar stays. They are two mode tabs of
  the same app, not two apps.
- **One theme:** `SurfaceStyle` is the single source of truth for both
  `TaskbarConceptView`/strip materials and `EdgeDockView`; `DockMaterialStyle`
  is kept only as the dock's material hint, never as a second theme.

## Slice-by-slice, one PR each, build+test+smoke green before commit

### P0 — Audit matrix (docs only)
Build a table of every legacy control → destination tab, mark
*migrate / fold / drop*. Confirm in writing which overlaps are true (e.g. the
gates in legacy Privacy vs new Privacy tab) so nothing silently disappears.

### P1 — Make Personalisation host all settings (no deletion yet)
- Add a required top-level “General” and “Dock (edge)” section plus the clipboard
  and backup/diagnostics cards, sourcing their controls from the legacy
  `SettingsView` tab implementations (move, not copy).
- Add an explicit **Edge dock** on/off control that sets
  `AppRuntimeController.isLegacyEdgeDockEnabled` through a proper method (the
  current hard flip at line ~790 becomes a real toggle).
- Keep the legacy window reachable for one release but point the menu-bar
  Settings item at the Personalisation window *first*, so new users land in the
  unified surface.
- Duplicate tabs (Privacy/Widgets/Shortcuts) inside the legacy window are left
  as-is for this PR; they are removed in P4.

### P2 — Merge the tabs' contents
- Merge old Dock controls into the new “Dock (edge)” card.
- Merge old Appearance + Themes + Widgets & Wallpaper into one Appearance tab
  fed only by `SurfaceStyle` (no separate DockMaterialStyle fork).
- Move old Shortcuts editing into Advanced, next to the hotkeys.
- Merge legacy Privacy into the new Privacy tab; keep the same
  `*Enabled`-gate semantics and default off.

### P3 — Theming unifies EdgeDockBar and Splitbar
- Drive `EdgeDockView` backgrounds/typography from `SurfaceStyle`/MotionTokens
  instead of its own Material fallback, so both bars share the same look.
- Audit clear-color/system-material usages in both. One style engine.

### P4 — Delete the old surface
- Remove `SettingsView.swift`, `SettingsTab`, `openSettingsWindow()`,
  `settingsWindow`, `settingsHostingView`, `makeSettingsView()`.
- Remove the now-dead legacy Privacy/Widgets/Shortcuts code paths.
- Update README, IMPROVEMENT_PLAN.md, RENDERING_FIX_PLAN.md and CLAUDE.md.

### P5 — Verification & test additions
- Add `SettingsRoundTrip`-style tests for the new cards' persistence.
- Smoke test passes; both bars still render; edge-dock toggle shows/hides only
  the edge dock (never touches `hideMacDock` unless the user opts in).

### P6 — Release
- Full `-warnings-as-errors` build, `swift test`, `lint_logging`, smoke test.
- `build_app.sh 0.3.X --release`, `make_release_dmg.sh`, upload DMG + zip to a
  new GitHub release.

## Do not

- Do not delete `EdgeDockView`/magnification or `DockController` behaviour; both
  stay, only their settings change address.
- Do not touch the Dock mutation/restore invariant while doing this.
- Do not land the legacy `SettingsView` removal (P4) before the new Personalisation
  covers the same knobs (P1–P3).
