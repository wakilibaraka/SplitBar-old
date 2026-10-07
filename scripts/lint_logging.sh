#!/bin/bash
# Fails when an OSLog interpolation is marked `privacy: .public` without being
# justified in scripts/logging_allowlist.txt.
set -uo pipefail
cd "$(dirname "$0")/.."
ALLOWLIST="scripts/logging_allowlist.txt"
status=0

echo "==> Inventory of public interpolations"
python3 - "$ALLOWLIST" <<'PY' || status=1
import pathlib, re, sys
allowlist = pathlib.Path(sys.argv[1])
allowed = set()
for line in allowlist.read_text().split("\n"):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split()
    if len(parts) >= 2:
        allowed.add((parts[0], parts[1]))

sensitive_hint = re.compile(
    r"(url|path|host|email|address|token|secret|clipboard|pasteboard|"
    r"body|content|title|name|label|query|error|reason|message|"
    r"account|ssid|bundleIdentifier)",
    re.IGNORECASE,
)

problems = []
total = 0
for path in sorted(pathlib.Path("Sources").rglob("*.swift")):
    for number, line in enumerate(path.read_text().split("\n"), 1):
        if "privacy: .public" not in line or "Logger" not in line:
            continue
        for expr in re.findall(r"\\\(([^,]+),\s*privacy:\s*\.public\)", line):
            total += 1
            expr = expr.strip()
            if (path.name, expr) not in allowed:
                problems.append(f"{path.name}:{number}  {expr}")
                continue
            # Judge only the final property: enum names such as
            # `account.provider.rawValue` expose no personal data.
            leaf = expr.rsplit(".", 1)[-1]
            if leaf != "rawValue" and sensitive_hint.search(leaf):
                problems.append(f"{path.name}:{number}  {expr}  (allowlisted but looks sensitive)")

print(f"    {total} public interpolation(s)")
if problems:
    print("FAIL: unjustified or sensitive public interpolations:")
    for p in problems:
        print("   ", p)
    sys.exit(1)
print("    all justified in", allowlist)
PY

if [ "$status" -ne 0 ]; then
  echo "FAIL: logging privacy policy violated"
  exit 1
fi
echo "PASS: logging privacy policy satisfied"
