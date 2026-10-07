# SplitBar — Structural Refactor Plan (C1, C2, C3, C5, C6)

Status: **in progress** (C1 executing) · Baseline: v0.3.0 · Measured 2026-10-07

This expands the five structural tasks in `IMPROVEMENT_PLAN.md` into executable
work. It changes no behaviour. Every phase is a sequence of small PRs that keep
`swift build -Xswiftc -warnings-as-errors` and `swift test` green.

## 0. Measured baseline

| Metric | Value |
|---|---|
| Swift files | 108, 27,992 lines |
| `Views/TaskbarConcept/TaskbarConceptView.swift` | **7,800 lines, 89 top-level types** |
| `App/AppRuntimeController.swift` | **2,762 lines, 70 methods** |
| Third largest file | `Services/AIUsageService.swift`, 922 lines |
| Lines per directory | Views 15,229 · Services 5,853 · App 3,150 · Support 1,930 · Models 1,586 · Stores 244 |
| `@unchecked Sendable` | 10 (ProcessRunner, SecretsStore, WidgetIconResolver, WindowManagerService, AppWindowPreviewService, ClipboardMonitor, GlobalShortcutService, ScreenService, ApplicationCatalogService, DisplayBrightnessService) |
| `DispatchQueue.main.async` | 17 |
| `Timer.scheduledTimer` | 8 |
| `try?` | **68** (DockController 9, ProviderLimitParsing 7, TaskbarConceptView 6, ClaudeStatusLineBridge 6, AIUsageService 6, DockRestore 5, ConfigurationPersistence 5, others ≤3) |
| `fatalError` / force-casts | 1 / 0 |
| Language mode | `.v5` forced on all three targets |
| Tests | 45 functions, 536 lines, single target importing `SplitBar` |
| Files in Models/Support/Stores importing AppKit or SwiftUI | 3 |

Two facts shape the ordering: the giant view file already contains 89 cleanly
separable top-level types (so C1 is mostly file moves), and the runtime
controller has **no test coverage at all** today (so C2 must extract logic before
it can be tested).

## 1. Sequencing and why

```
C1 (split the view)  →  C2 (split the runtime)  →  C3 (module targets)
                                    ↓
                          C4 tests grow alongside
                                    ↓
                    C5 (Swift 6)  →  C6 (error handling)
```

- **C1 before C2** — C2's coordinators hold SwiftUI state and call the view
  types, so it is much cheaper once those types live in predictable files.
- **C2 before C3** — target boundaries follow responsibilities; splitting files
  first reveals the real seams, and it keeps every C3 PR a pure `Package.swift`
  plus import change.
- **C4 runs throughout**, not as its own phase — each C1/C2 extraction that moves
  testable logic must bring its test.
- **C5 after C3** — strict concurrency produces far better diagnostics once types
  are in separate modules, because the compiler can then see module boundaries.
- **C6 last** — replacing `try?` means choosing error-surfacing behaviour, and
  that choice is easiest once everything else has stopped moving.

Do **not** start these during a security or release push. A 7,800-line mechanical
move in the same PR as a behaviour change makes the behaviour change unreviewable.

---

## 2. C1 — Split `TaskbarConceptView.swift` (P1, L, ~8 PRs)

**Goal:** no file over ~1,200 lines. Zero behaviour change.

The file holds 89 top-level types, so this is file moves plus visibility fixes,
not a redesign.

| PR | Contents | Target file | Est. lines |
|---|---|---|---|
| C1.1 | `OpenPanel`, `SurfaceStyle` (+14 theme cases), `CornerStyle`, `CornerScope`, `CornerSurface`, `ThemeTokens`, `MotionTokens`, `GlassProvider`, environment keys | `DesignSystem/` | ~900 |
| C1.2 | `TaskbarMode`, `TaskbarSection`, `TaskbarStrip`, `TaskbarDivider`, `StripItem`, `TaskbarStripMetrics`, `IconShape`, `StatusIconPreset`, `WidgetState` | `DesignSystem/StripModel.swift`, `WidgetProvider.swift` | ~500 |
| C1.3 | `TaskbarConceptState` and its helpers | `TaskbarState.swift` | ~900 |
| C1.4 | Taskbar strip views: `Taskbar`, `TaskbarSplitRow`, `TaskbarIslandContent`, `TaskbarTiles`, `AppTile`, dividers, weather/clock sections | `TaskbarStrip/` | ~1,200 |
| C1.5 | Launcher: `StartFlyout` and its cells | `Launcher/` | ~1,100 |
| C1.6 | Widgets board: `WidgetsPanel`, `WidgetCard` and every widget | `Widgets/` | ~1,900 (split into two PRs) |
| C1.7 | Quick Settings, Bluetooth, volume/brightness, system monitor | `QuickSettings/` | ~1,700 (two PRs) |
| C1.8 | Calendar, clock, `ClockStyleSettings`, media | `Calendar/` | ~1,000 |
| C1.9 | `SettingsFlyout` (now ~1,400 lines with the Privacy tab) | `Settings/` (three files) | ~1,400 |

**Rules**
- Moves only. Verify each PR with `git diff --color-moved` and reject any hunk
  that changes a non-whitespace character.
- `private` becomes `internal` only where the new file boundary requires it; do
  not widen access "while you're there".
- `TaskbarConceptState` keeps its current name and `@MainActor` isolation so
  `AppRuntimeController` and the tests are unaffected.
- After every PR: `swift build -Xswiftc -warnings-as-errors && swift test`.

**Done when:** no file exceeds ~1,200 lines; all five entry types
(`TaskbarConceptView`, `TaskbarPanelContentView`, `TaskbarFlyoutContentView`,
`WindowPreviewContent`, `TaskbarIslandContent`) keep their signatures; tests green.

**Risk:** low, mechanical. **Cost:** the real cost is reviewer fatigue — keep PRs
small and mechanical so they can be approved quickly.

---

## 3. C2 — Split `AppRuntimeController.swift` (P1, L, ~6 PRs)

**Goal:** `AppRuntimeController` becomes a composition root under ~600 lines.
Currently 70 methods owning dock state, taskbar panels, flyouts, clipboard,
weather, AI usage, shortcuts, settings window, launch-at-login, and command
palette.

| PR | Extracted type | Responsibility | Testable now? |
|---|---|---|---|
| C2.1 | `ClipboardCoordinator` | monitor lifecycle, pause, retention, persistence, pruning | yes — pure policy already extracted |
| C2.2 | `WeatherCoordinator` | Open-Meteo refresh, weather widget state, cache | yes — backdrop mapping is tested |
| C2.3 | `ShortcutCoordinator` | bindings, conflict reporting, dispatch | yes — chord labels and conflicts are tested |
| C2.4 | `PanelCoordinator` | taskbar strip/island panels, flyout framing, previews | partly — geometry is pure |
| C2.5 | `AIUsageCoordinator` | AI refresh cadence and the account-access gate | yes — gate logic is pure |
| C2.6 | `DockCoordinator` | hide/restore orchestration, menu items | yes — state round-trip is tested |

Each coordinator gets a protocol (`ClipboardCoordinating`, …) so `AppRuntimeController`
depends on abstractions, and each holds its subscriptions in one place instead of
sharing the runtime's `Set<AnyCancellable>`.

**Sequencing note:** do C2.1–C2.3 first. They are the ones that can ship real
tests, which pays for the refactor. Panel and Dock coordinators move later because
their behaviour is hard to test without a running UI.

**Done when:** runtime under ~600 lines, each coordinator protocol-conformed with
at least one test, no behaviour change, tests green.

---

## 4. C3 — Extract SwiftPM modules (P2, L, ~4 PRs)

**Goal:** conservative builds possible; clear dependency direction.

```
SplitBarCore          SplitBarIntegrations        SplitBar (UI + wiring)
  Models, Support,       AI/Bluetooth/Clipboard/     taskbar, flyouts,
  pure geometry,         Weather integrations         AppRuntimeController
  reducers
        ↑                       ↑                        ↑
        └─────────────── SplitBar ────────────────────────┘
SplitBarDockRestore    (depends on Foundation only — unchanged)
```

| PR | Contents | Notes |
|---|---|---|
| C3.1 | `SplitBarCore` | move Models, Support, Stores. **Blocker:** 3 files import AppKit/SwiftUI (`ClipboardRetentionPolicy` for `NSPasteboard.PasteboardType`, `DockViewState`, `PanelGeometry`) — replace with plain strings / move the type |
| C3.2 | `SplitBarIntegrations` | AI (2,551 lines), Bluetooth, clipboard, weather. Backed by the B4 gate so the module can be omitted |
| C3.3 | `SplitBar` | views + app wiring, imports the other two |
| C3.4 | Split the test target | one target per module; tests move with their code |

**Rules:** `SplitBarCore` must not import AppKit or SwiftUI — enforce with a CI
grep (`grep -rl "import AppKit\|import SwiftUI" Sources/SplitBarCore` must be
empty). No cycles. No new dependencies.

**Value:** a build that omits `SplitBarIntegrations` is the "conservative build"
the plan asks for, and it is only possible after this task.

**Risk:** medium — mostly mechanical, but `Package.swift` changes ripple into CI,
`run.sh`, and the release script.

---

## 5. C5 — Swift 6 concurrency (P2, L, ~5 PRs)

**Goal:** build in Swift 6 language mode without `@unchecked Sendable`, except
documented exceptions.

Start: 10 `@unchecked Sendable`, 17 `DispatchQueue.main.async`, 8
`Timer.scheduledTimer`, 62 `@MainActor`, 22 `nonisolated`.

| PR | Work |
|---|---|
| C5.1 | Enable `-strict-concurrency=complete` while **staying in language mode 5**; fix warnings per module. Pure warning-clearing, no semantic change. |
| C5.2 | Replace the 10 `@unchecked Sendable` types: `ProcessRunner` and `SecretsStore` become actors or lock-based final classes; `ScreenService`, `GlobalShortcutService`, `ApplicationCatalogService` become `@unchecked`-free value/lock types; UI-bound ones become `@MainActor`. |
| C5.3 | Fold the 17 `DispatchQueue.main.async` hops into `@MainActor` functions; keep only genuine background hops. |
| C5.4 | Flip `SplitBarDockRestore` to `.v6` (Foundation-only, so it should be quick), then `SplitBarCore`, then the rest. |
| C5.5 | Flip tests; delete any remaining suppression with a justification or fix it. |

**Rules:** no blanket suppression; the invariant "no blanket suppression" still
holds. Keep `-warnings-as-errors` on so each warning must be dealt with, not muted.

**Verification:** a concurrency bug here can be a data race, not a crash, so each
PR needs a manual pass over the affected feature (clipboard, panels, shortcuts).

---

## 6. C6 — Replace silent `try?` (P2, M, ~3 PRs)

Start: 68 occurrences, concentrated in `DockController` (9), `ProviderLimitParsing`
(7), `TaskbarConceptView` (6), `ClaudeStatusLineBridge` (6), `AIUsageService` (6),
`DockRestore` (5), `ConfigurationPersistence` (5).

Three outcomes, decided per call site:

| Category | Rule | Examples |
|---|---|---|
| **Persistence** | must surface failure: log privately, quarantine/retain a copy, and show a non-blocking notice | `ConfigurationPersistence`, `ClipboardPersistence`, Dock state file |
| **User-visible action** | must throw or return a typed failure the UI renders | session lock/sleep, panel geometry, launch failures |
| **Best-effort cleanup** | keep `try?`, add a one-line comment saying why it is safe | deleting a stale temp file, removing an optional backup |

| PR | Scope |
|---|---|
| C6.1 | `ConfigurationPersistence` + clipboard: failures reported, corrupt files quarantined. Add a test that a failed save is reported and the previous copy survives. |
| C6.2 | `DockController` + `DockRestore` + `ClaudeStatusLineBridge`: Dock state failures are fatal-to-the-hide-path (never hide without a saved state), bridge writes verified. |
| C6.3 | Everything else: each remaining `try?` gets a justification comment or becomes a typed error. |

**Done when:** every `try?` is either gone or has a comment; a test proves a failed
config save is surfaced.

---

## 7. What must not regress

These are the invariants in `IMPROVEMENT_PLAN.md` §1, and they are the acceptance
criteria for every PR above:

- Dock state persisted atomically **before** mutation; restored on quit,
  SIGTERM/SIGINT, next launch and by the login agent; `SPLITBAR_SKIP_DOCK` honoured.
- Panels stay non-activating; only launcher panels take key focus.
- Secrets never in logs, argv or disk in plaintext.
- No binaries in git; no GPL code; no new dependencies; `-warnings-as-errors` green.
- Every behavioural change ships with a test and a README update when it is
  user-visible.

## 8. Effort and sequencing reality

| Task | PRs | Rough size | Blocking for |
|---|---|---|---|
| C1 | 8–9 | L | C2 readability, reviewer fatigue |
| C2 | 6 | L | C3 seams, runtime testability |
| C3 | 4 | L | conservative builds |
| C5 | 5 | L | Swift 6 readiness, future Xcode versions |
| C6 | 3 | M | honest failure reporting |

A sensible order is **C1 → C2.1–C2.3 → C4 growth → C3 → C6 → C5**, with C1's
mechanical PRs deliberately spread across releases rather than landed as one
large branch.

## 9. Blocked on a person

- **A3** licence and `Reference/` provenance, **E1** Developer ID: unchanged, still
  owner decisions.
- **D1** VoiceOver walkthrough and **D5** hot-plug verification need a human on a
  physical machine.
- **B5** remainder (CoreLocation, SSID authorisation) needs a device.

## 10. Progress log

Each slice is one commit, verified with `swift build -Xswiftc -warnings-as-errors`
and `swift test` before the commit.

| Slice | Commit | Result |
|---|---|---|
| C1.3 | see log | State extracted: `TaskbarState.swift` (803) holds `TaskbarConceptState` with `LauncherApp`, `LauncherFolder`, `LauncherDefaults`, `TopProcess`; `DesignSystem/ClockStyle.swift` (74) takes the clock style enums, `clockTime`, and the `Date`/`Calendar` helpers. Source file 6,546 → 5,687 lines. Build clean, 45 tests pass, move verified. |
| C1.2 | see log | Strip model extracted: `DesignSystem/StripModel.swift` (615), `WallpaperPreset.swift` (52), `WidgetChrome.swift` (12); the widget catalogue appended to `WidgetProvider.swift` (61 → 142). Source file 7,252 → 6,546 lines. Build clean, 45 tests pass, move verified. |
| C1.1 | see log | Design system extracted to `DesignSystem/`: `SurfaceStyle.swift` (452), `PanelStyle.swift` (97), `ColorExtensions.swift` (34). Source file 7,800 → 7,252 lines. Build clean, 45 tests pass. |

**Mechanics.** `scripts/split_swift.py` performs the moves. It finds top-level
declarations by column-0 indentation rather than brace counting, because string
literals in this file contain braces. Doc comments and attributes directly above
a declaration are moved with it, so `@MainActor` never detaches from its type.
Moved declarations lose `private`, since they become module-internal.

**Access-level rule.** Anything that was `fileprivate` or `private` because it
was scoped to the old single file must become module-internal when its owner
moves to another file, or the build fails. Two cases recur:

- top-level declarations: the splitter drops the keyword automatically;
- members of a moved type, e.g. 48 `fileprivate` members of
  `TaskbarConceptState`: these are widened by hand per slice, since
  automatically widening every member would expose internals that no other
  file needs. `private` members of a moved type stay `private`, because that
  keyword is scoped to the type, not the file.

The reconstruction check treats these access-level changes as mechanical and
fails on any other difference.
