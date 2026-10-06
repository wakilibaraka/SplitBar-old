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
  `TaskbarConceptState`; persist Quick Settings visibility, widget order/sizes,
  launcher pins, clock style, and wallpaper presets/custom gradient.
- [x] Add bottom-edge geometry to the existing edge dock model and panel helpers.
- [x] Make app launching asynchronous so the UI does not wait on a blocking
  semaphore while macOS launches an application.
- [x] Remove the retired standalone `Prototypes/TaskbarDesign` package after the
  unified target is verified.
- [x] Commit and publish the unified integration branch.
- [x] Replace the launcher's Recommended and Most-used sections with a Folders
  block (Desktop, Documents, Movies, Music, Pictures, Downloads) that resolves
  real iCloud-aware user directories and opens them in Finder.
- [x] Make the Personalisation panel a symmetric block grid with no dead space;
  Surface style and Taskbar height now use the same card and header treatment as
  every other section.
- [x] Stop background polling at presentation cadence while nothing is on screen,
  move AppleScript playback queries off the main actor, cache app icons, and
  debounce slider persistence. See "Resource budget and forward compatibility".
- [x] Render taskbar app icons as full-height tiles with Medium/Large/Extra
  large size presets (Medium default); the weather glyph uses the same sizing.
  Trash is a four-position setting (with apps by default, before the tray,
  before the clock, or far right) with a Downloads tile pinned to its left,
  full/empty state, and Open/Empty actions. Dividers render only in the
  Windows-like bar, including a divider after the weather widget; the macOS
  dock presentation shows none. Personalisation has a Reset button
  with confirmation that restores widths, icons, trash position, wallpaper,
  and taskbar appearance without touching pins or widgets.
- [x] Narrow the five flyouts to Windows 11-style default widths, each with its
  own width slider back up toward the previous wide layout.
- [x] Seat the quick-controls cluster immediately left of the date as one
  indivisible trailing unit.
- [x] Launcher identity and Windows power menu: footer shows the real account
  name with avatar (CBIdentity, initials fallback) instead of "Your profile",
  a gear button jumping straight to Personalisation, and a power menu with
  Lock, Sleep, Restart, Shut Down, and Log Out — icons on the left, destructive
  actions behind confirmation, failures surfaced in an alert. Power verbs run
  through public pmset/System Events off the main thread; first use may trigger
  the macOS Automation prompt.
- [x] Launcher All-Apps grid: pinned row shows 4 with a persisted "Show only
  4 pinned apps" toggle (default off = grid visible); the grid scans real
  catalog apps once per open with A-Z/Category grouping, live search filter,
  cached icons, and tap-to-launch. Categories come from
  LSApplicationCategoryType; dockbar patterns reimplemented cleanly.
- [x] Launcher layout fix: All-Apps is a flat Launchpad-style grid with no
  letter or category grouping; the columns scroll inside a capped floating
  Start panel (700 pt, Win11-like) with search pinned top and profile footer
  pinned bottom.
- [x] Pinned drag reorder in the launcher (unpin already exists via Edit mode
  and lands in context menus next).
- [x] Right-click tile menus in Native (Open/Activate, Show in Finder, Hide,
  Quit) and Windows (Open, new window, file location, window list, filtered
  recents, pin/unpin, Quit) styles, default Native; all actions on public API
  with per-window focus falling back to app activation.
- [x] Launcher Processes card replaces the static All-programs placeholder:
  live top-5 CPU table sampled every 5 s only while the launcher is open.
- [x] Widgets board gains Date, System rings, and Network widgets with live
  data (clock, CPU/memory/disk/battery rings + uptime + process count,
  up/down rates + session peaks); metrics forwarded from the runtime monitor,
  process count piggybacked on the existing ps sample at no extra spawn.
- [x] Widgets refinement pass: unified uppercase-micro headers on all cards
  and forecast sections; theme logic untouched (dark/XP/98/Aero keep working
  through the shared card backgrounds).
- [x] Running state with click cycle: NSWorkspace push notifications track
  running and frontmost apps; tiles show dot/dash/highlight indicators;
  clicking launches, activates, or hides, with AX true-minimize behind a
  permission-gated mode. Indicator style/size/colour and minimize mode persist;
  their settings controls land with the settings redesign.
  name with avatar (CBIdentity, initials fallback) instead of "Your profile",
  a gear button jumping straight to Personalisation, and a power menu with
  Lock, Sleep, Restart, Shut Down, and Log Out — icons on the left, destructive
  actions behind confirmation, failures surfaced in an alert. Power verbs run
  through public pmset/System Events off the main thread; first use may trigger
  the macOS Automation prompt.
- [x] Replace the three separate Wi-Fi/volume/battery glyphs with one dynamic
  system-status icon: battery ring with level/charging/low states, Wi-Fi
  on/off glyph, volume dots, and a Bluetooth power dot. Live data comes from
  public IOKit, CoreWLAN, CoreAudio, and IOBluetooth APIs through the new
  SystemStatusService (10 s cadence, off-main sampling, publishes only on
  change). The design is inspired by Status Trio (Apache-2.0, attributed in
  NOTICE); the renderer is an original implementation and no reference source
  is included. Deliberately excluded: display-brightness control via DDC
  private APIs, per-device Bluetooth batteries (needs a Bluetooth permission
   prompt), and Wi-Fi SSID text (needs a Location prompt).
- [x] Shrink the status icon to a regular app-sized tile in the trash cluster
  (battery ring plus Wi-Fi glyph at the shared icon preset) and wire the Quick
  Settings readout rows to the same live snapshot: battery level/charging
  state, Wi-Fi on/off with signal bars, and Bluetooth power.
- [x] Enforce a single running instance at launch (later launches activate the
  existing one and exit) so overlapping windows from divergent in-memory state
  can never composite on screen. Developers relaunching test builds must quit
  the running copy first. The fake Wi-Fi
  toggle and fake Bluetooth device percentages are gone; those rows are
  display-only until their action slices land. The quick-setting tile grid
  stays mock until one capability at a time is wired with confirmation.

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
   appearance controls, quick-setting selection, sliders, widget board layout,
   launcher pins, clock style, and wallpaper choices.
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

- [x] Make the launcher pin list the single catalog-backed source for both
  launcher tiles and taskbar app icons; keep launches on `AppLaunchService`.
- [x] Present the taskbar row in a bottom-edge screen panel
  (`TaskbarPanelController` + `TaskbarPanelContentView`) as an opt-in,
  independently reversible milestone. The panel is borderless and
  non-activating (`canBecomeKey`/`canBecomeMain` false), floats at
  `.floating`, joins all Spaces, spans the primary display's full visible
  width, and resizes live with the taskbar height. The macOS Dock is untouched
  and the preview window stays the default. Flyouts still render in the
  preview window during this milestone; per-flyout panels above the bar are the
  next slice.
- [x] Render all five flyouts as key-capable panels above the strip when panel
  mode is on (reusing the state-preserving flyout host, per-flyout widths,
  ESC and click-outside dismissal); the preview window renders them only when
  panel mode is off.
- [x] Dock-like floating behavior is live: the strip drops
  `.fullScreenAuxiliary` so fullscreen Spaces hide it, a `FullscreenMonitor`
  hides it per display on Space/app switches via `CGWindowList` scan (also
  dismissing open flyouts), and the controller is keyed per display with only
  the primary enabled — multi-display placement can switch the set on.
- [x] Window previews behind an opt-in toggle (default off): hovering a running
  app tile shows that app's windows above the strip with SCScreenshotManager
  thumbnails, icon fallback plus a Screen Recording hint when capture is
  unavailable, and click-to-activate. Preview dismisses on hover exit, flyout
  open, mode off, and fullscreen.
- [x] Settings redesign for taskbar behavior: one Taskbar behavior section
  owns indicator style/size/colour, click minimize mode, menu style, and the
  previews toggle in the established block-grid idiom.
- [x] Live weather provider: Open-Meteo current plus 14-day daily codes and
  hourly series behind the existing IP geolocation (no new permission),
  Codable disk cache served stale across launches and failures, offline/sample
  states in the UI, and the fabricated humidity/wind buttons removed. Verified
  live against the local area.
- [x] Live Now Playing binding: board card renders the polled AppleScript
  state with idle card, progress bar, and working play/pause through the
  existing off-main transport; updates publish only on change.
- [x] Dock persist/restore infrastructure with default-OFF opt-in: original
  orientation/autohide persist to disk before any mutation, restore on
  terminate plus SIGTERM/SIGINT traps plus launch-time crash recovery,
  SPLITBAR_SKIP_DOCK dev bypass. Verified the default path never touches the
  real Dock (no state file, defaults unchanged).
- [ ] Present the approved bottom taskbar as a screen-edge `NSPanel` using the
  existing panel manager and screen geometry code. Keep the macOS Dock visible
  during this first panel milestone; it must be independently reversible.
- Establish panel focus policy: taskbar must not steal focus from frontmost apps;
  launcher/search surfaces may take focus only where needed.
- Validate display bounds, safe/visible frame, menu bar, auto-hide, Spaces, and
  fullscreen behavior before adding Dock suppression.
- Support one display first; document limitations before adding multi-display
  placement.

**Gate:** taskbar positions correctly on all supported edges and survives Space
switches without focus theft.

The taskbar is still hosted in the preview window. The shared pin wiring is the
first functional slice toward a dock; the next implementation should move only
the taskbar surface into a non-activating bottom-edge panel, retain the preview
as a fallback, and validate multi-display and Space behavior before changing
the app's default presentation.

#### Dock-like floating behavior (committed)

App windows must float above and around the bar; the bar must never overlay
fullscreen content. Reference studied: deskbar hides its bar per display with a
fullscreen scan. Clean-room plan:

- Drop `.fullScreenAuxiliary` from the taskbar panel so fullscreen Spaces hide
  it by default, and add a `FullscreenMonitor` service that scans
  `CGWindowList` per display on `activeSpaceDidChange` plus frontmost-app
  change as belt-and-braces (covers non-Space fullscreen overlays). Hide only
  the affected display's panel when multi-display lands.
- Move the strip from `.floating` to `.statusBar` level (matches the reference
  and always-on-top expectations) only together with the hiding above; never
  raise the level while the bar can still overlay fullscreen content.
- macOS offers no public edge-reservation API (no AppBar equivalent), so a
  third-party bar cannot push windows up the way the real Dock does. Floating
  plus hide-on-fullscreen is the design, not a bug; a later "dodge windows
  touching the strip" mode needs `CGWindowList` polling and stays optional and
  off by default for the same resource reasons as all other polling.

### Phase 5 — Native app launch and running state

- Keep app catalog and launch logic in services; the UI sends identifiers/actions
  rather than calling AppKit directly.
- Add running-app indicators using public `NSWorkspace` APIs.
- Define launch, activate, open-window, and quit semantics separately.
- Add clear behavior for uninstalled apps and inaccessible locations.

#### Click semantics and context menus (committed)

Windows behavior to replicate: clicking a running app's icon activates it, and
clicking the frontmost app's icon minimizes it; right-click opens the app menu.
Reference studied: deskbar does per-window buttons with AX raise/minimize/close
plus Dock-style menus. Clean-room plan, no permission for the base layer:

- Track running state (`NSRunningApplication`) and frontmost state (also
  `NSWorkspace`, no permission) in the model; show running indicators on tiles.
- Click cycle, all public API: not running → launch; running but not frontmost
  → `activate()`; running and frontmost → `hide()` (hide, not minimize, needs
  no permission). True genie-minimize and per-window raise go behind
  Accessibility, requested lazily with a rationale the first time a gated
  action is used; public `AXUIElement` APIs only with a frame-matching
  fallback — the reference's private `_AXUIElementGetWindow` dlsym is
  explicitly not adopted.
- Right-click `NSMenu` per tile: Open/Activate, window list from
  `CGWindowListCopyWindowInfo` titles (no permission), Show in Finder, Hide,
  Quit (`terminate()`, public), Pin/Unpin. Per-window focus items appear only
  when Accessibility is granted; jump-list recent documents stay a later
  slice.

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

#### Weather, planned against the DatWeatherDoe pattern

- Verified: DatWeatherDoe (inderdhir/DatWeatherDoe) is Apache-2.0 and may be
  adapted with attribution, a license copy, and change notices.
- Its verified mechanism: a URL builder for WeatherAPI
  `forecast.json?key=&q=lat,lon&aqi=yes`; a repository factory choosing
  CoreLocation coordinates or an explicit lat/long; a cancellable `Task` loop
  sleeping a configurable refresh interval with a reachability-triggered retry;
  a condition-to-SF-Symbol map rendered as a template `Image(systemName:)` plus
  text in the status item. It ships no custom icon assets and performs no icon
  animation.
- SplitBar keeps its keyless Open-Meteo provider rather than adopting
  WeatherAPI, because WeatherAPI requires every user to supply a personal key
  that must never be bundled. Adopt the repository shape, the cancellable
  polling task, and the condition-to-SF-Symbol rendering instead.
- Store locally as a Codable snapshot (payload, fetchedAt, coordinates) under
  Application Support with a single writer; serve the stale snapshot on launch
  and on fetch failure, and mark it stale in the UI.
- The requested weather animation has no counterpart in the reference. If
  pursued, use SF Symbol variable-color effects on the taskbar glyph only, and
  keep them static while the widgets panel is closed.

#### Now Playing, planned against the BoringNotch approach

- Verified: BoringNotch (TheBoredTeam/boring.notch) is GPL-3.0: STUDY ONLY,
  reimplement clean, never paste.
- Its verified mechanism: Now Playing comes from the private
  `MediaRemote.framework`, bridged through a `mediaremote-adapter` framework
  and consumed out-of-process via an XPC helper, so the private API is isolated
  from the main app.
- SplitBar's Phase-2 default stays on the current AppleScript provider, which
  uses only public API for Music and Spotify and already runs off the main
  actor with a player-running gate. A MediaRemote provider for all-players
  coverage is optional later work, and if built it must live behind a protocol
  in Core/, be feature-detected, stay XPC-isolated like the reference, and be
  flagged in the PR description as a notarization risk. No private API in the
  default path.

### Phase 7 — Calendar, launcher, and customization

- Replace sample events/tasks/alarms with clear providers; request calendar
  access only when the feature is enabled.
- Search and launcher results must be asynchronous, cancellable, and
  keyboard-accessible.
- Keep the 32–48 pt taskbar range, scalable icon sizes, compact launcher, and
  persisted visual presets, including gradient, dark, and customizable
  wallpapers.
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

- Sign with a persistent local certificate before requesting Accessibility or
  Screen Recording: macOS keys TCC grants to the code identity, so every
  ad-hoc rebuild would re-prompt otherwise (lesson confirmed from the deskbar
  history). Assert bundle identifier and designated requirement at package
  time.
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

### Phase 10 — Window previews and switcher (planned, not started)

Chosen scope for now is plan-only. When implementation starts, each slice below
is its own PR, each independently reversible, and none of them changes macOS
Dock behavior implicitly.

- Verified references and their license verdicts: DockDoor (ejbills/DockDoor)
  and AltTab (lwouis/alt-tab-macos) are GPL-3.0; rajeshgoli/deskbar ships with
  no license grant. All three are STUDY ONLY: reimplement clean, never paste.
  OpenSwitchr (trsdn/OpenSwitchr) is MIT and may be adapted with attribution.
- The mechanism all four converge on: enumerate and raise/minimize/close
  windows through public Accessibility APIs (`AXUIElement`, `AXObserver`);
  capture thumbnails with ScreenCaptureKit behind the Screen Recording
  permission, with a short-lived cache (DeskBar uses ~2 s) and a
  `CGWindowList` fallback when capture is unavailable; show the preview in a
  hover `NSPanel` after a short hover delay.
- Follow the OpenSwitchr shape: one shared window index plus an event bus plus
  one thumbnail cache, with the hover preview and any switcher overlay as thin
  readers on top. Do not build a second enumeration path per surface.
- Slice order: (1) per-app window list with names and icons only, behind an
  explicit opt-in, requiring no new permission beyond what the slice needs;
  (2) live thumbnails behind Screen Recording, with a static-icon fallback when
  denied; (3) an Option-Tab style switcher overlay only after (1) and (2) are
  proven. Accessibility and Screen Recording are requested lazily, at the
  moment each slice is enabled, never at launch.
- Flagged risk carried over from the references: DeskBar resolves the private
  `_AXUIElementGetWindow` via dlsym. If SplitBar ever needs it, it goes behind
  a protocol in Core/, is feature-detected with a frame-matching fallback, and
  is flagged in the PR description as a notarization risk, exactly like the
  existing login.framework lock-screen lookup.

## Resource budget and forward compatibility

### Polling and cost rules

Background sampling must never run at presentation cadence while nothing is on
screen. The rules the code now follows:

- `SystemMonitorService` samples at 1 Hz only while the detailed monitor window
  or the system-monitor flyout is visible; otherwise it drops to a 15 s baseline
  so figures are never wholly absent.
- `NowPlayingService` polls at 2 s while something is playing or its flyout is
  open, and 10 s otherwise. It also skips the query entirely when neither Music
  nor Spotify is running.
- `AIUsageService` runs at 3 s only while its flyout is open, and 300 s otherwise,
  matching its own internal usage-scan interval. Each refresh shells out to `ps`
  and inspects four agent sessions, so it must not run at presentation cadence
  while closed.
- `AppRuntimeController.refreshLiveStreamingCadence()` is the single place that
  decides which cadence applies. Flyout open/switch/close and opening the
  detailed monitor all route through it; do not add a second interval decision
  elsewhere.
- AppleScript playback queries and transport commands run on a background queue
  with a single in-flight guard. Never call `NSAppleScript.executeAndReturnError`
  from the main actor on a repeating timer.

Measured on a debug build over a 120 s idle window: idle CPU fell from 10.2 s to
4.2 s (~59% less) and resident memory stayed flat. The largest remaining idle
cost is the 0.6 s clipboard change-count poll, which is inherent to clipboard
history.

### View-level cost rules

- App icons resolve once through `AppIconStore`, off the main thread, and are
  cached. Do not call `NSWorkspace.icon(forFile:)` from a view body.
- The taskbar clock ticks at 1 Hz only when seconds are shown; otherwise it uses
  a minute-aligned 60 s schedule.
- Slider and colour-picker changes debounce their `UserDefaults` write by 0.35 s
  rather than writing on every drag tick.
- `surfaceWash` must always be applied with the same rounded shape as
  `panelBackground`, or the wash squares off the panel's corners.

### macOS 28 status

macOS 28 compatibility is **not verified**. This machine runs macOS 27.0.1 with
Xcode 27, and the newest installed SDK is `MacOSX27.0.sdk`; there is no SDK 28 to
build or test against. What has been established instead:

- The deployment target stays at macOS 15 in both `Package.swift` and
  `Info.plist`. A low floor is the cheapest forward-compatibility guarantee, so
  do not raise it just to reach newer APIs.
- The code uses public API only. No SkyLight/SLS, no
  `NSVisualEffectView`/`NSGlassEffectView`, and no Objective-C runtime poking for
  window-server behavior.
- One exception remains and must be re-verified on every SDK bump:
  `lockScreenImmediately()` in `Support/SystemSessionActions.swift` dlopens
  `login.framework` from `/System/Library/PrivateFrameworks` and dlsyms
  `SACLockScreenImmediate`. It is feature-detected and fails soft with typed
  errors, so a future macOS that removes the symbol degrades rather than
  crashes, but it is a private-framework dependency and a notarization risk.
- When an SDK 28 becomes available, re-run: a clean build with
  `-warnings-as-errors`, a deprecation sweep for SDK 26-28, and a pass over
  `Info.plist` privacy keys.

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
- **Repository inspirations:** "DockBar", Deskbar, Eskele, and other projects
  are research inputs only until their exact repository URLs, license terms,
  ownership, and reusable files are audited. Adapt ideas freely; copy code only
  when the license explicitly permits the intended use and attribution is kept.
  Verified so far: DatWeatherDoe is Apache-2.0 (adaptable with attribution);
  BoringNotch, DockDoor, and AltTab are GPL-3.0 (study only, reimplement
  clean); rajeshgoli/deskbar carries no license grant (study only);
  OpenSwitchr is MIT (adaptable with attribution); Status Trio is Apache-2.0
  (design-adaptable with attribution, recorded in NOTICE); malvarezcastillo/
  deskbar is a byte-identical fork of the unlicensed rajeshgoli/deskbar
  (verified via commit history: all commits authored upstream), so the same
  study-only verdict applies — windowing patterns reimplemented cleanly, never
  pasted, including its private `_AXUIElementGetWindow` dlsym which is
  explicitly excluded.
