# SplitBar Migration and Build Plan

This document is the working source of truth for evolving SplitBar into a
maintainable macOS Dock replacement. Update the status and acceptance criteria
here as each vertical slice is completed. The earlier skeleton checklist in
`TASKS.md` is historical context; this plan supersedes it where they differ.

## Product direction

Build one native macOS app that presents a configurable bottom taskbar inspired
by the current SwiftUI design prototype. Keep the Windows-like layout and
surface/theme choices as the visual baseline, but make behavior and data native
to macOS where practical.

The initial target is a dependable, user-friendly base—not a feature-for-feature
clone of every inspiration project. Prototype the interactions and layouts with
sample data first; introduce system access only behind reviewed services and
explicit user controls.

## Current status

- [x] Keep the existing `SplitBar` Swift Package as the single executable target.
- [x] Integrate the taskbar, launcher, widgets, calendar, Quick Settings, and
  customization design into `Sources/SplitBar/Views/TaskbarConcept/`.
- [x] Make the taskbar design window the default visible app surface; keep the
  legacy edge dock hidden by default as a temporary fallback.
- [x] Route pinned-app launches through the existing `AppLaunchService`.
- [x] Centralize taskbar design interactions in the app-owned
  `TaskbarConceptState`; persist Quick Settings visibility and widget size.
- [x] Add bottom-edge geometry to the existing edge dock model and panel helpers.
- [x] Make app launching asynchronous so the UI does not wait on a blocking
  semaphore while macOS launches an application.
- [x] Remove the retired standalone `Prototypes/TaskbarDesign` package after the
  unified target is verified.
- [ ] Commit and publish this integration branch after final validation.

## Architecture inventory and disposition

| Existing area | Decision | Use in the unified app |
|---|---|---|
| `AppDelegate`, `SplitBarApp`, `AppRuntimeController` | Keep and adapt | Single lifecycle/composition root; owns panel services, dock reducer state, preferences, and the taskbar concept model. |
| `AppState`, `AppAction`, `AppReducer`, `DockItem` | Keep | Reducer-driven state for the existing functional dock and its items. Do not duplicate dock operations in view-local state. |
| `AppPreferences`, configuration persistence | Keep and consolidate | Preserve user configuration. Gradually connect approved taskbar preferences to the same app-owned settings/persistence boundary. |
| `AppLaunchService`, `ApplicationCatalogService` | Keep and reuse | Launch pinned apps and discover apps; keep callbacks asynchronous and report failures. |
| `EdgePanelController`, `FlyoutPanelController`, `KeyablePanel` | Keep and adapt | Retain focus/Space/panel behavior when the design becomes screen-edge panels; avoid replacing a mature panel lifecycle with ad-hoc windows. |
| Weather, Bluetooth, Now Playing, System Monitor, Notes services | Keep behind view models | Reuse only after defining service contracts, permissions, refresh cadence, and loading/error states. The concept window remains sample-data-driven for now. |
| `TaskbarConceptView.swift` | Keep as source of visual direction; split by feature as the next cleanup | Preserve its taskbar, launcher, weather, widgets, Quick Settings, calendar, and surface styling. Keep interactions in the app-owned concept state until production state models are ready. |
| `Prototypes/TaskbarDesign` | Retire after verification | It was useful for isolated iteration but must not remain a second app/entry point after the unified target builds and runs. |
| Legacy edge-dock presentation | Retain temporarily as fallback | Hidden by default while the new taskbar is reviewed. Remove only after parity, migration, and rollback checks pass. |

## State ownership

There must be one owner for each piece of behavior:

1. `AppRuntimeController` is the runtime composition root and owns long-lived
   app services and UI controllers.
2. `AppState` plus the reducer owns dock-item ordering, selection, placement,
   visibility, and active legacy flyout transitions.
3. `AppPreferences` and configuration persistence own durable app settings.
4. `TaskbarConceptState` owns the integrated taskbar prototype's panel selection,
   appearance controls, quick-setting selection, sliders, and widget-size choice.
5. Views render state and send actions/bindings to their owning model. Avoid
   shadow copies of app-wide settings in child `@State`.

Before enabling production use, converge durable taskbar preferences with
`AppPreferences` or a single app settings store. Keep temporary animation and
popover presentation state local to the view that presents it.

## Phased migration and build roadmap

### Phase 0 — Safe baseline and code provenance

- Keep the integration on a dedicated branch until the unified app is reviewed.
- Record the base commit and ensure the worktree is clean before each vertical
  slice.
- For every external inspiration repository, inspect its license, notices,
  provenance, and source of each candidate implementation before adaptation.
- Prefer behavioral study and clean reimplementation when licensing is
  incompatible or unclear. Never import code or assets from a repository until
  its license and required attribution are understood.
- Track adapted files and notices; preserve license/attribution requirements.

**Gate:** no unreviewed third-party source is copied into SplitBar.

### Phase 1 — Unified runnable base (current)

- Build one `SplitBar` executable; do not add another `@main` or package target.
- Launch the familiar taskbar design window by default with a menu-bar route to
  settings, preview, legacy fallback, and quit.
- Keep the old edge dock hidden, not deleted, while the new direction is
  validated.
- Route pinned app activation through the existing app-launch service.
- Keep all weather, stats, background-app, battery, network, VPN, and media
  sample data explicitly mock-backed.
- Provide run/build instructions and a single maintained migration plan.

**Gate:** `swift build` passes, app opens without the legacy dock covering the
design, and pinned apps either open or show an explicit error.

### Phase 2 — Decompose and normalize the design system

- Split `TaskbarConceptView.swift` into small feature files: taskbar, launcher,
  widgets, Quick Settings, calendar, settings, and shared surfaces.
- Extract theme tokens (palette, radius, typography, elevation, transparency)
  shared with the existing Liquid Glass surfaces.
- Preserve the current style set and interactions while extracting; visual-only
  refactors must be screenshot-compared at default and narrow window sizes.
- Ensure all buttons have meaningful accessibility labels and keyboard focus.
- Ensure flyouts dismiss predictably and do not overlap the taskbar or each
  other.

**Gate:** no behavior regression; all themes build and render in light and dark
appearance.

### Phase 3 — A single production state and persistence boundary

- Replace `TaskbarConceptState` with app-facing state/actions owned by the runtime
  store; keep `AppState` reducer behavior intact or migrate it in a deliberate
  tested change.
- Store taskbar height, pinned apps, widget sizing/visibility, clock formatting,
  appearance, and Quick Settings tile visibility in versioned configuration.
- Add migrations and safe defaults for existing users' `config.json`; malformed
  or unwritable configuration must be surfaced and logged, not silently treated
  as a successful save.
- Keep transient UI presentation state in views; keep durable preferences out
  of disconnected view-local state.

**Gate:** relaunch restores preferences; config migration and failure paths are
tested.

### Phase 4 — Dock/taskbar panel foundation

- Convert the approved bottom taskbar into a screen-edge `NSPanel` presentation
  using the existing panel manager and screen geometry code.
- Establish panel focus policy: taskbar must not steal focus from frontmost apps;
  launcher/search surfaces may take focus only where needed.
- Validate display bounds, safe/visible frame, menu bar, auto-hide, Spaces, and
  fullscreen behavior before adding Dock suppression.
- Support one display first; document limitations before adding multi-display
  placement.

**Gate:** taskbar positions correctly on all supported edges and survives Space
switches without focus theft.

### Phase 5 — Native app launch and running state

- Keep app catalog and launch logic in services; the UI sends identifiers/actions
  rather than calling AppKit directly.
- Add running-app indicators using public `NSWorkspace` APIs.
- Define launch, activate, open-window, and quit semantics separately.
- Add clear behavior for uninstalled apps and inaccessible locations.

**Gate:** pin, unpin, reorder, launch, activate, and running indicators work
without blocking the main thread.

### Phase 6 — Widgets and Quick Settings

- Convert placeholder Weather, System Resources, Background Apps, Now Playing,
  Photos, Sticky Notes, and Watchlist cards to view models with sample and live
  providers.
- Reuse existing `WeatherService`, `SystemMonitorService`,
  `NowPlayingService`, `BluetoothService`, and `QuickNotesService` only through
  explicit boundaries and permission-aware loading states.
- Implement the visual Quick Settings tiles first; wire one capability at a
  time. Never imply system mutation succeeded unless the service confirms it.
- Persist custom tile visibility and handle unsupported controls explicitly.
- Do not silently terminate, hide, restart, or mutate other apps/system settings
  behind a tile.

**Gate:** each live tile has permission, error, unavailable, and success states;
mock mode remains available for UI work.

### Phase 7 — Calendar, launcher, and customization

- Replace sample events/tasks/alarms with clear providers; request calendar
  access only when the feature is enabled.
- Search and launcher results must be asynchronous, cancellable, and
  keyboard-accessible.
- Keep the 32–48 pt taskbar range, scalable icon sizes, compact launcher, and
  persisted visual presets.
- Keep the prototype's Windows, macOS, Aero, and past-Windows styling as
  selectable user appearance—not as different implementations of system
  behavior.

**Gate:** calendar permissions, launcher keyboard flows, and persisted
customization pass manual checks.

### Phase 8 — Real Dock integration, only after explicit safety review

- Design a `DockController` protocol and a no-op/mock implementation first.
- Before any system Dock mutation, persist original settings and prove recovery
  on normal quit, forced termination, app crash, and relaunch.
- Require explicit opt-in, show a clear restore path, and keep a development
  bypass.
- Use public APIs where possible; isolate any private API behind a protocol,
  feature detection, license/security review, and a documented fallback.
- Do not ship Dock hiding, `killall Dock`, privileged commands, or permissions
  until the recovery tests pass.

**Gate:** a test matrix proves macOS returns to the original Dock state after all
failure/termination paths.

### Phase 9 — Release quality

- Add unit tests for reducers, config migrations, panel geometry, and preference
  validation.
- Add UI tests or recorded manual checks for launch, close, resizing, themes,
  accessibility, and multiple resolutions.
- Profile launch time, memory, battery impact, panel refresh, and background
  polling.
- Verify signing, notarization, permission descriptions, privacy disclosures,
  license notices, and a clean uninstall/restore flow.

**Gate:** release checklist passes on supported macOS versions and a clean user
profile.

## Code review notes and advice

- **Bottom-edge support:** app defaults already requested `.bottom` although the
  enum and geometry omitted it. The integration adds bottom geometry and
  horizontal layout so that default is coherent.
- **Launch responsiveness:** the prior app launch service waited on a semaphore
  on the main actor. It now uses async completion to avoid freezing the UI while
  an app opens. Preserve this property for all new integrations.
- **Persistence errors:** review `try?` configuration writes in startup/reset
  paths; future settings migration must surface failed saves and keep a recoverable
  copy instead of silently continuing.
- **Runtime size:** `AppRuntimeController` is a large orchestration type. Avoid
  adding more unrelated feature logic there; extract focused coordinators when
  each vertical slice is understood and covered by tests.
- **Prototype data:** resource/app names and network/device values are visual
  fixtures, not actual measurements. Keep their mock status obvious until live
  providers are implemented and reviewed.
- **Taskbar preview vs. replacement:** the integrated preview window is the
  current UI base; it is not yet an always-on-top edge replacement and does not
  hide the macOS Dock. Phase 4 and Phase 8 are separate gates for those
  behaviors.
- **Repository inspirations:** “DockBar”, Deskbar, Eskele, and other projects
  are research inputs only until their exact repository URLs, license terms,
  ownership, and reusable files are audited. Adapt ideas freely; copy code only
  when the license explicitly permits the intended use and attribution is kept.
