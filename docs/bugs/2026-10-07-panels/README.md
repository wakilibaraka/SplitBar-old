# Panel & rendering bugs — 2026-10-07

Root causes and the per-task fixes are in [`RENDERING_FIX_PLAN.md`](../../RENDERING_FIX_PLAN.md).
Status: **R1–R6 implemented and merged** via commits `1514edf` (R1), `a6886cb`
(R2), `8c91994` (R3), `6dade3d` (R4), `03e6362` (R5) and `d6733f3` (R6).

## Reproduction steps (R0)

Launch the app, open the preview window from the menu-bar item, and in
onboarding step "Pick a layout" click Windows → macOS → Split 3 → Split 4 →
Centered → Windows. Screenshot after each selection; the live bar at the screen
edge must match the selected layout and there must be exactly one bar per
display.

Expected panel counts (per display, excluding flyouts): Windows 1, macOS 1,
Centered 1, Split 3 → 3, Split 4 → 4.

## What was verified here and what was not

Verified in this session (compile, unit tests, and/or smoke test):

- **R1**: `show(_:)` now closes/removes unwanted panels; `PanelPlan` is
  unit-tested. Smoke test paints no ghost panels on layout switches (process
  counts checked via the in-window run).
- **R2**: with the live panel on, the in-window strip is replaced by "The live
  bar is running on your screen"; preview window opens on first run only.
- **R3**: onboarding tokens are explicit (white over a dark card), and new
  `ContrastTests` assert the ratios; the hero headline no longer renders behind
  the card.
- **R4**: panel content is given `.environment(\.controlActiveState, .key)` so
  materials render active.
- **R5**: the centered bar width is `max(user width, intrinsic content width)`
  clipped to the screen; `TaskbarStripMetricsTests` cover 5/12/19 apps.
- **R6**: the Split 4 tray island now renders the downloads/trash/status cluster;
  the apps island is apps-only.

Not captured here (needs a clean desktop): before/after screen frames for S1–S5
from the repro. The capture pass is deferred until the taskbar is unobstructed;
drop the PNGs in this directory when you have them.

## Regression rule

Because removal bugs were reintroduced once, any change to the panel lifecycle in
`TaskbarPanelController` or `FlyoutPanelController` must be reflected in
`TaskbarPanelPlanTests`; the plan helper is the contract.
