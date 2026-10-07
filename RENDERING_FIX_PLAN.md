# SplitBar — Rendering Fix Plan (from screenshots)

Evidence: screenshots of v0.2.0 on a 1710×1112 pt display plus the source in
`Sources/SplitBar`. Confidence labels: CONFIRMED = read in code, MEASURED =
measured from screenshot pixels, HYPOTHESIS = plausible, verify first.

> Operational notes
> - The macOS Dock on the right edge is the user's own Dock setting, not a bug.
> - The old CLAUDE.md told agents things that are no longer true, so it drifts.
>   Update CLAUDE.md whenever the architecture changes.

## 1. What the screenshots show

| # | Symptom (where) | Evidence |
|---|---|---|
| S1 | Two taskbars at once: one in the "Taskbar Preview" window, one at the real screen bottom. | Same icon strip appears twice, in-window and at the screen edge. |
| S2 | Ghost panels after switching layout: the screen-bottom bar always shows the Windows layout whatever is selected. | The in-window bar is correct for the chosen layout; the real bar is not. |
| S3 | Flat, dark tiles on the real bar; in-window tiles are translucent. | Tile colour vs the wallpaper behind it. |
| S4 | Centered layout overflows its own bar; clock text on the trash icon. | Bar chrome spans x≈650–1650 but content spans x≈610–1690. |
| S5 | Split 4 shows an empty third tile (tray island); the "32" ring stays in the app strip. | In-window Split 4 shot. |
| S6 | Onboarding text nearly unreadable (subtitle, descriptions, Back). | Contrast table below. |
| S7 | Not a bug: the macOS Dock on the right edge is the user's own setting (`hideMacDock` defaults to false). | TaskbarConceptState.swift. |

Measured contrast (WCAG, ~from pixel sampling; AA needs 4.5:1 for body text):
Subtitle "One bar or floating islands" ≈1.0:1, row descriptions ≈1.0:1,
"Back" ≈1.3:1, row labels ≈3.6:1, title "Pick a layout" ≈3.9:1,
hero subtitle ≈3.1:1.

## 2. Root causes

- RC1 — Stale panels are resurrected (CONFIRMED, S2).
  `TaskbarPanelController.show(_:)` orderOuts unwanted panels but keeps them in
  `panels`/`hostingViews`, then `refreshFullscreenVisibility()` re-shows every
  panel in that dictionary. Each layout switch leaves the old bars on screen.
- RC2 — Two renderers of one state (CONFIRMED, S1).
  The runtime opens the "Taskbar Preview" window (`openTaskbarConceptWindow()`)
  AND shows real panels (`setupTaskbarPanel()`), both driven by the same
  `taskbarConceptState`.
- RC3 — Materials on a non-key panel look flat (HYPOTHESIS, S3).
  Non-key panels never get active-state SwiftUI materials; test with
  `.environment(\.controlActiveState, .key)` or an explicit
  NSVisualEffectView at `.active`.
- RC4 — Centered bar width is independent of its content (HYPOTHESIS, S4).
  `centeredBarWidth` preference may be narrower than the pinned-item count.
- RC5 — Onboarding uses semantic colours on an unpredictable background
  (CONFIRMED usage, MEASURED result, S6). `.secondary`/`.primary` resolve to a
  mid-grey on a teal card; hero headline renders behind it.
- RC6 — Split 4 tray island is empty (UNKNOWN cause, S5).

## 3. Tasks (do in order; one PR each)

- R0 — Reproduce and instrument. Debug builds with `SPLITBAR_DEBUG_PANELS=1` and
  a menu-bar item to list panels; store before/after screenshots.
- R1 — Fix stale panels. CONFIRMED done in this slice: `show(_:)` now orders out,
  closes and removes unwanted panels from all three dictionaries;
  `refreshFullscreenVisibility()` iterates `activeKeys` only; `hide()` clears
  everything incl. `panels`/`hostingViews`; `isReleasedWhenClosed = false`;
  `PanelPlan.transition(wanted:existing:)` extracted and unit-tested.
- R2 — One surface. The live panel is the product; the preview window becomes a
  personalisation surface, not a second taskbar (hide the in-window strip when
  the live bar is on, stop auto-opening the window after onboarding). Human
  decision needed on the exact surface split.
- R3 — Onboarding readability + hero headline behind the card.
- R4 — Glass materials on non-key panels.
- R5 — Centered bar fits its content (clamp to content width, no overlap).
- R6 — Split 4 tray island content.
- R7 — Regression pass + docs (screenshot set under docs/bugs/…, CLAUDE.md note).

## 4. Don't

Don't fix by disabling panels or deleting the preview window.
Don't rewrite `TaskbarConceptView`-bearing surfaces wholesale; surgical changes
only. Don't touch Dock mutation code for these bugs. One root cause per PR.

## 5. Per-task prompt

Read RENDERING_FIX_PLAN.md. Work only on task <ID>.
First do the VERIFY FIRST steps and tell me what you found.
Then the smallest change that meets "Done when", with the named tests.
Run `swift build -Xswiftc -warnings-as-errors && swift test`.
Report: files changed, why, how to see it, and what you deliberately did NOT change.
