# Network inventory

Every host SplitBar contacts, why, what is sent, and which setting controls it.
Verified with `grep -rn "https\?://" Sources/SplitBar --include="*.swift"`.

## Default behaviour: two hosts

| Host | Why | What is sent | Setting |
|---|---|---|---|
| `api.open-meteo.com` | Weather and 14-day forecast | Latitude and longitude of the weather location | Always on; coordinates come from the location source below |
| `<host>` of each pinned link | The site's own favicon (`/favicon.ico`) | One HTTPS GET per pinned host | Always on |

## Opt-in only (off by default)

| Host | Why | What is sent | Setting |
|---|---|---|---|
| `ipwho.is` | Derives an approximate city and coordinates when no manual location is set | **The machine's IP address** | `ipGeolocationEnabled` |
| `icons.duckduckgo.com` | Favicon fallback | Every pinned host name | `faviconServiceEnabled` |
| `www.google.com` | Favicon fallback (`/s2/favicons`) | Every pinned host name | `faviconServiceEnabled` |
| `api.anthropic.com` | Maps a Claude Code token to its account email | A bearer token read from the Claude Code Keychain item | `aiAccountSwitchingEnabled` |
| `api.openai.com` | Codex limit lookup referenced by the parser | Provider auth | `aiAccountSwitchingEnabled` |

## Local only

| Address | Why |
|---|---|
| `127.0.0.1:11434` | Ollama, when a local model server is running |

## Not network calls

`http://www.apple.com` appears only as an AppleScript dictionary URL, and the
GitHub / YouTube / ChatGPT / X / Notion / Figma / Reddit / `example.com` strings
are pre-filled text for links the user types or adds. Nothing is requested from
them until the user opens the link.

## Rules

- Secrets are never sent to any host, and never placed in a URL.
- Coordinates are only sent to the weather host, and only for the location the
  user has configured.
- Turning a setting off takes effect immediately; the corresponding host is not
  contacted again.
- Favicon lookups always try the site itself first so a pinned host is not
  disclosed to a third party unless the user opted in.
