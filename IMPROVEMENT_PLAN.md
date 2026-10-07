# SplitBar — Improvement Plan

Baseline: v0.2.0, analysed from source and the shipped binary (Oct 2026).
This file supersedes the "Code review notes" in `MIGRATION_AND_BUILD_PLAN.md` where
they differ, and complements its Phase 8 (Dock) and Phase 9 (release) gates.

Status legend: **done** · **partial** · **todo** · **blocked** (needs a person).

## 0. How an agent should use this file

1. Pick the lowest-numbered unblocked task (see the dependency table). One task = one branch = one PR.
2. Run every command under **VERIFY FIRST** before editing. If reality differs from this file, trust the code and note the difference in the PR description.
3. Make the smallest change that meets **Done when**. Do not refactor beyond the task.
4. Before finishing: `swift build -Xswiftc -warnings-as-errors && swift test` must pass (macOS 15+, Xcode Swift 6.x). CI runs `macos-26`.
5. Add or update tests for every behaviour change. Update `README.md` if user-visible behaviour or permissions change.
6. Anything marked **HUMAN** needs a person's decision or a physical-machine check. Stop and ask rather than guessing.

## 1. Invariants (never break these)

- **Dock safety** (`Services/DockController.swift`, `Sources/SplitBarDockRestore/main.swift`): original Dock state is persisted atomically *before* any mutation; restored on terminate, SIGTERM/SIGINT, next launch, and by the login-time helper. `SPLITBAR_SKIP_DOCK` bypasses all mutation. Real-Dock changes stay opt-in (`hideMacDock`).
- **Panel focus**: taskbar and flyout panels are non-activating with `canBecomeKey == false`. Only launcher/search panels may take key focus (`KeyablePanel`).
- **Licensing**: no GPL code (study-only list in `CLAUDE.md` and the plan). Keep every attribution in `NOTICE`.
- **No new third-party dependencies** without human approval (`Package.swift` has none).
- **Private APIs** stay isolated, runtime-probed and opt-in (DDC in `Services/DisplayBrightnessService.swift`).
- **Secrets** are never logged, never placed in process arguments, never written to disk in plaintext.
- **No binaries in git**.
- Keep `-warnings-as-errors` green; never silence a warning with a blanket suppression.

## 2. Baseline facts (verified from source)

| Area | Fact |
|---|---|
| Size | ~27k lines Swift. `Views/TaskbarConcept/TaskbarConceptView.swift` ~7.6k lines; `App/AppRuntimeController.swift` ~2.7k. Together ~38% of the code. |
| Build | SwiftPM only: tools 6.0, macOS 15, all targets `.swiftLanguageMode(.v5)`, zero dependencies, no `.xcodeproj`. `run.sh` assembles a debug `.app`. |
| CI | `.github/workflows/build.yml`: build + test on `macos-26`. No bundle/signing/release job. |
| Tests | 22 test functions in 2 files. Nothing covers keychain, clipboard, config migration, status-line bridge, or Dock state I/O. |
| Logging | ~52 `privacy: .public`, no `.private`. Includes the weather URL (carries lat/long) and response-body dumps. |
| Clipboard | Monitoring starts at launch, polls every 0.6 s, persists pretty-printed JSON + image blobs. Retention is count/bytes only. Default exclusions: 1Password and Apple Keychain Access. |
| Credentials | `AIAccountStore` reads Claude Code's keychain item, `~/.claude.json`, `~/.codex/auth.json` and implements account switching. `SecurityKeychain` shells out to `/usr/bin/security` and passes secrets as hex in `argv` (visible in `ps`). |
| Other AI | `ClaudeStatusLineBridge` rewrites `~/.claude/settings.json` `statusLine` (with backup). `ClaudeTokenOwnerLookup` calls `api.anthropic.com/api/oauth/profile`. `AIUsageService` runs `osascript` → Terminal, plus `ps`, and talks to Ollama on `127.0.0.1:11434`. |
| Network | `WeatherService` → `ipwho.is` (IP geolocation) and open-meteo. `FaviconService` → DuckDuckGo, Google s2, then the host. |
| Location | `Info.plist` declares a Location usage string but no source imports CoreLocation. `SystemStatusService` reads `CWInterface.ssid()` without requesting authorisation. |
| Dock safety | Good: atomic state file, signal `DispatchSource`s, env bypass, Foundation-only restore helper. |
| Docs | `CLAUDE.md` was stale (Xcode project, macOS 14, "Phase 1 skeleton only"). `README.md` current. |
| Shipped binary | Ad-hoc signed, no hardened runtime/entitlements/Team ID; contained `/Users/<name>/…` build paths, an Xcode `swift-6.2` rpath, and a hash-based helper identifier; plist said 0.1 while the tag was v0.2.0; no icon, no `Resources/`. |

## 3. Task overview

| ID | Task | Pri | Status | Depends on |
|---|---|---|---|---|
| A1 | Refresh `CLAUDE.md`, add this plan | P0 | done | – |
| A2 | Repo hygiene | P0 | done | – |
| A3 | `LICENSE` + provenance | P0 | **blocked (HUMAN)** | – |
| A4 | Bundle metadata + `scripts/build_app.sh` | P0 | done | – |
| B1 | Log privacy + lint | P0 | done | – |
| B2 | Clipboard: opt-in, concealed types, expiry, perms | P0 | done | B1 |
| B3 | `SecretsStore` (no argv secrets) | P0 | done | B1 |
| B4 | Gate AI credential features, status-line first | P1 | done | B3 |
| B5 | Location/network: CoreLocation, favicons, inventory | P1 | partial | B1 |
| B6 | Process + Terminal dispatch hardening | P1 | done | – |
| C1 | Split `TaskbarConceptView.swift` | P1 | todo | A1 |
| C2 | Split `AppRuntimeController.swift` | P1 | todo | C1 |
| C3 | Extract SwiftPM modules | P2 | todo | C1, C2 |
| C4 | Test expansion | P1 | done (grows) | B2, B3 |
| C5 | Swift 6 concurrency migration | P2 | todo | C3 |
| C6 | Replace silent `try?` | P2 | todo | C4 |
| C7 | CI: bundle check, lint, coverage | P1 | done | A4, B1 |
| D1 | Accessibility + keyboard navigation | P1 | partial | C1 |
| D2 | Privacy and data center UI | P1 | done | B2, B5 |
| D3 | Taskbar state indicators + lazy prompts | P2 | partial | D1 |
| D4 | Localization via String Catalog | P2 | todo | C1 |
| D5 | Multi-display | P3 | todo | C2 |
| E1 | Developer ID signing + notarization | P1 | **blocked (no Team ID)** | A4, C7 |
| E2 | Restore agent via `SMAppService` | P2 | done | – |
| E4 | Logging-privacy lint, bundle CI, docs sync | P1 | done | B1, A4 |
| E3 | Binary hygiene (strip, rpath, prefix-map, helper ID) | P1 | done | A4 |

## 4. Task details

### A1 — Refresh `CLAUDE.md` and link this plan (done)
`CLAUDE.md` now describes SwiftPM as the canonical build, macOS 15, the real
architecture and the invariants from section 1, and links this file. The stale
"Phase 1 is SKELETON ONLY" and Xcode-project instructions are gone. License and
private-API rules are preserved verbatim.

### A2 — Repo hygiene (done)
Release binaries (`SplitBar.dmg`, `SplitBar.zip`, `dmg_stage/`) untracked and
gitignored; `port.py` moved to `tools/legacy/` with a warning header; ignores
added for `*.dmg`, `*.zip`, `dmg_stage/`, `*.dSYM`, `*.xcuserstate`.
`Reference/README.md` documents the status of each third-party image. Removing
the images entirely requires a provenance decision (**HUMAN**, see A3).

### A3 — LICENSE and provenance (blocked: HUMAN)
Owner must choose a licence for their own code and confirm the right to keep the
`Reference/` images. `NOTICE` keeps upstream EdgeDeck (senoldogann) MIT credit.

### A4 — Bundle metadata and build script (done)
`scripts/build_app.sh <version> [--release]` builds, injects the version into
`Info.plist`, assembles `SplitBar.app` (app binary, `Contents/Helpers`, `Resources`),
and fails if any piece is missing. `Info.plist` gained icon, category and
copyright keys. `run.sh` calls the script in debug mode.

### B1 — Log privacy and CI lint (done)
Interpolations default to `.private`; `.public` survives only on non-sensitive
scalars listed in `scripts/logging_allowlist.txt`. URLs with query strings, `$HOME`
paths, emails, tokens and response bodies are no longer logged. The weather
service logs host and status only. `scripts/lint_logging.sh` fails on unlisted
`.public` interpolations and runs in CI.

### B2 — Clipboard hardening (done)
`clipboardEnabled` (default **off**) gates monitoring; with it off no timer is
scheduled and nothing is written. Pasteboards declaring concealed, transient or
auto-generated types are skipped via a pure, tested filter. Default exclusions
cover 1Password (both bundle IDs), Bitwarden, Dashlane, KeePassXC, Apple
Keychain Access and Apple Passwords. Time-based retention (1 h / 24 h / 7 d /
until cleared, default 24 h) prunes on load and on a timer. Storage is `0700`
directories with `0600` files and compact JSON. "Pause for 1 hour" joins
"Clear all".

### B3 — `SecretsStore` (done)
`protocol SecretsStore` with `SystemKeychainSecretsStore` (native `SecItem*`
APIs, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, SplitBar-specific service
names), `ClaudeCodeKeychainBridge` for Claude Code's own item, and an in-memory
fake used by tests. Secrets no longer appear in `Process.arguments`
(`grep -rn '"-X"'` is empty).

### B4 — Gate AI credential features (done)
The status-line bridge is the default and always-available path (official
rate-limit data, no tokens). Account switching, `~/.codex/auth.json` reads,
OAuth profile lookups and OpenAI auth references sit behind
`aiAccountSwitchingEnabled` (default **false**) with an explicit consent sheet
naming every file and keychain item touched. When off, none of them are accessed.
The bridge's disconnect restores the original `statusLine`, covered by a temp-home
test. **HUMAN**: provider terms of service must be reviewed before enabling this
for anyone.

### B5 — Location and network (partial)
Done: favicons try the host's own `/favicon.ico` first, with DuckDuckGo/Google
only when `faviconServiceEnabled` (default off), and results are cached on disk;
IP geolocation is opt-in with an explicit "your IP address is sent to ipwho.is"
disclosure; `NETWORK.md` inventories every host contacted, why, and what is sent;
`Info.plist` usage strings were corrected.
Remaining: replacing IP geolocation with `CLLocationManager` + `CLGeocoder`, and
requesting authorisation before `CWInterface.ssid()`.

### B6 — Process and Terminal hardening (done)
All `Process()` use goes through `Support/ProcessRunner.swift`: absolute
executable path, argument array, no shell, timeout and output-size cap. Terminal
dispatch of agent CLIs now shows the exact command and requires confirmation.
Timeout and large-output behaviour are unit tested.

### C1/C2/C3/C5/C6 — Structural work (todo)
Splitting the two large files, extracting SPM modules, migrating to Swift 6
language mode and replacing silent `try?` are multi-PR mechanical programmes,
sequenced C1 → C2 → C3 → C5 → C6. Do not start them piecemeal.

### C4 — Test expansion (done, grows with B and C)
Covers: layout/dividers, Dock state round-trip and legacy-payload refusal,
weather backdrop mapping, shortcut chord labels and binding round-trip, the
clipboard type filter, expiry pruning and exclusions, `SecretsStore` fake
round-trips, status-line connect/disconnect on a temp home, provider-limit
parsing fixtures, and `ProcessRunner` timeout/output caps. CI publishes a
coverage report.

### C7 — CI (done)
`build.yml` runs build + test with coverage, `scripts/lint_logging.sh`, and a
bundle check that builds the app and asserts the helper, required plist keys and
`codesign --verify`.

### D1 — Accessibility and keyboard navigation (partial)
Done: arrow-key tile navigation with focus state, a record/rebind flow for global
hotkeys, VoiceOver labels on taskbar controls and badge/window-count
accessibility values. Remaining: full labelling sweep across all five flyouts and
a VoiceOver walkthrough (**HUMAN**).

### D2 — Privacy and data center (done)
A "Privacy and data" page lists every capability with real status read from
`AXIsProcessTrusted`, `CGPreflightScreenCaptureAccess`, CoreLocation status and
Bluetooth authorisation, why it is needed, what leaves the Mac, and a deep link
to the matching System Settings pane. Status is conveyed by text and icon, never
colour alone.

### D3 — Taskbar indicators and lazy prompts (partial)
Done: active pill, running dot, stacked multi-window indicator, window-count
badge, visible focus ring. Remaining: 44 pt minimum targets on tall bars and
lazy first-use permission prompts.

### D4 — Localization (todo)
Move strings to a String Catalog, migrate `AppLocalization.swift`, keep EN/TR,
translate Turkish comments, add a pseudo-localization pass.

### D5 — Multi-display (todo)
`DisplayCoordinator` already owns the panel screen set and reacts to screen
changes, and remains primary-only by policy. Extending it to one panel set per
screen is a preference change plus per-display app filtering.

### E1 — Signing and notarization (blocked: no Team ID)
Until a Developer ID exists, `scripts/build_app.sh` produces an ad-hoc signed
app that will trigger Gatekeeper on other machines. When an ID is available:
add `entitlements.plist`, sign both binaries with hardened runtime, notarize and
staple, and upload release artifacts from CI.

### E2 — Restore agent via `SMAppService` (done)
The agent plist is embedded in the bundle and registered with
`SMAppService.agent(plistName:)`, so it survives app moves, appears in Login
Items, and is removed when disabled. Fallback plist writing is retained for
non-app-bundle launches.

### E3 — Binary hygiene (done)
Release builds use `-Xswiftc -file-prefix-map`, binaries are stripped, the Xcode
toolchain rpath is deleted with `install_name_tool`, and the helper is signed
with the stable identifier `com.baraka.splitbar.dockrestore`. Verified: no
`/Users/` paths in the binary, no Xcode rpath.

## 4a. Execution notes (2026-10 session)

- `B5` is deliberately **partial**: the favicon and IP-geolocation gates are in
  place, but the app still derives weather coordinates from `ipwho.is` when the
  gate is on rather than from `CLLocationManager`, and `CWInterface.ssid()` is
  still read without requesting authorisation. Both need a device to validate.
- `A3` and `E1` are blocked on the owner: a licence choice for this code, a
  provenance decision for `Reference/`, and a paid Apple Developer ID.
- `C1`/`C2` (splitting the two large files), `C3`, `C5` and `C6` were left alone
  deliberately: they are multi-PR mechanical programmes and interleaving them
  with security work would have made review harder, not easier.
- The debug-path leak and Xcode rpath issues are fixed for release builds only.
  `scripts/build_app.sh` prints a warning when building without `--release` so a
  debug bundle is never mistaken for a distributable one.
- CI runs `macos-26` and now includes a logging-privacy job and a bundle job that
  asserts the helper, required plist keys, icon, signature, and the absence of
  `/Users/` paths and Xcode rpaths. That job caught the debug-bundle path leak
  during this session.

## 5. HUMAN decisions (agents must not decide these)

1. Licence for the owner's own code (A3) and provenance for `Reference/` images (A2).
2. Whether credential reading and account switching ship at all, and provider terms review (B4).
3. Apple Developer ID account, notarization credentials, repository secrets (E1).
4. Physical-device QA (section 6).

## 6. Manual QA matrix (run before each release)

| Scenario | Expected |
|---|---|
| Launch with `hideMacDock` on, `kill -9`, then log out/in | Real Dock restored by the helper |
| Switch Spaces; enter/leave a full-screen app | Taskbar persists and hides/reveals correctly |
| First launch on a clean user | No permission prompts; clipboard off; onboarding explains opt-ins |
| Deny Screen Recording / Location | Fallbacks render; no crash |
| VoiceOver walkthrough | Every control reachable and described |
| Reduce Transparency + Increase Contrast + Reduce Motion | Solid, legible, non-animated surfaces |
| Disconnect Claude Code usage | `~/.claude/settings.json` `statusLine` restored exactly |
| Network capture with default prefs | Only hosts listed in `NETWORK.md` |
| Hot-plug a second display (after D5) | Panels follow the display configuration |

## 7. Pull request template for agents

```
Task: <ID> — <title>
Changed files: <list>
Behaviour change: <none | describe>
Verify-first findings that differed from IMPROVEMENT_PLAN.md: <list or none>
Tests added/updated: <list>
Commands run: swift build -Xswiftc -warnings-as-errors; swift test; scripts/lint_logging.sh
Privacy/permission impact: <none | describe>
Manual checks still needed (HUMAN): <list or none>
```