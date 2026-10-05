# Phase 1: Skeleton Checklist

> Historical checklist. The current implementation and future build sequence
> are maintained in [MIGRATION_AND_BUILD_PLAN.md](./MIGRATION_AND_BUILD_PLAN.md).
> In particular, real Dock mutation is deferred until its opt-in and recovery
> gates in that plan are satisfied.

1. **App shell**
   - LSUIElement app, menu-bar item with Quit and Settings placeholders. App launches with no dock icon.

2. **PanelManager + GlassBackground**
   - Reusable glass `NSPanel`s targeting the primary display.
   - Implement per-panel focus policies: Dock/Widgets = `canBecomeKey: false`; Launcher/Search = `canBecomeKey: true`, dismiss on ESC.
   - Verify Space switch survival (`.canJoinAllSpaces`).

3. **DockController**
   - Read/persist real Dock's state (orientation, autohide) to a saved-state file.
   - Temporarily move real Dock to left/right and auto-hide on launch.
   - Trap `SIGTERM`/`SIGINT` for clean restore, and restore on launch if a crash stranded the user (check for saved-state file).
   - Add a dev flag to skip `killall Dock` for rapid iteration.

4. **Dock panel (functional)**
   - Bottom glass panel.
   - **Bootstrapping**: Bundle a default `config.json` (e.g., Safari, Messages, System Settings) and copy to `~/Library/Application Support/SplitBar/` on first launch if empty.
   - **Tracking**: Use `NSWorkspace.shared.runningApplications` (no accessibility prompts needed yet) to track running states and bind UI dot indicators.
   - **Action**: Use `NSWorkspace.shared.openApplication` / `activate()` to launch pinned apps or bring running apps to front.
   - **Focus**: Must use the non-activating focus policy so clicking an app icon doesn't steal focus from the app you just launched.

5. **Theme tokens**
   - Extract colors, corner radius, blur (`NSVisualEffectView` -> fallback for `NSGlassEffectView` later), and spacing so all surfaces match the glassmorphism aesthetic.

6. **Widgets panel (dummy)**
   - Slide-up card grid matching the screenshot layout, static placeholder cards (Performance, Weather, Calendar, To-Do).

7. **HotkeyManager**
   - Add `KeyboardShortcuts` SPM dependency.
   - Wire global hotkey to toggle the widgets panel.

8. **Launcher panel (dummy)**
   - Two-pane glass (pinned grid + app list), dummy data, summoned by hotkey.
   - Must take key focus on show.

9. **Search bar (UI only)**
   - Floating pill, hotkey summon, focus + accept text, no results.

10. **Polish pass**
    - Animations, dismiss behavior, testing across Space switches and Full Screen apps.
