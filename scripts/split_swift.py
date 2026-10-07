#!/usr/bin/env python3
"""Move top-level declarations out of a Swift file into a new file.

Usage:
  scripts/split_swift.py <source.swift> <destination.swift> <selector>...

Selectors are `Name` (every top-level block with that name) or `Name#line`
(one specific block, disambiguating names like `View` that appear several
times). Declarations are found by indentation, not brace counting: in Swift
every top-level declaration starts at column 0 and everything inside a type
body is indented, whereas string literals routinely contain braces.

Moved declarations lose a leading `private`, because after the move they are
module-internal and used from other files. Nothing else is rewritten.
"""

import re
import sys
import pathlib

DECL = re.compile(
    r"^(?:@[\w()., ]+\s+)*(?:public |private |fileprivate |internal |final |indirect )*"
    r"(?:struct|class|enum|extension|protocol|actor|func|var|let)\s+([A-Za-z_][A-Za-z0-9_]*)"
)


def top_level_declarations(lines):
    """Return [(start, end_exclusive, name, text)] using column-0 boundaries."""
    starts = []
    for index, line in enumerate(lines):
        # Column 0 only: no leading whitespace, and not a comment.
        if line and not line[0].isspace() and not line.startswith("//"):
            match = DECL.match(line)
            if match:
                starts.append((index, match.group(1)))

    # Pull doc comments and attributes (e.g. `@MainActor`) that sit directly
    # above a declaration into that declaration's block, so they travel with it.
    adjusted = []
    for start, name in starts:
        cursor = start - 1
        while cursor >= 0:
            previous = lines[cursor]
            if previous.startswith("//") or (previous.startswith("@") and not previous[0].isspace()):
                cursor -= 1
                continue
            break
        adjusted.append((cursor + 1, name))

    blocks = []
    for position, (start, name) in enumerate(adjusted):
        end = adjusted[position + 1][0] if position + 1 < len(adjusted) else len(lines)
        while end > start and lines[end - 1].strip() == "":
            end -= 1
        blocks.append((start, end, name, "\n".join(lines[start:end])))
    return blocks


def strip_private(text):
    """Drop a leading `private` from the declaration line only."""
    lines = text.split("\n")
    for index, line in enumerate(lines):
        if DECL.match(line):
            lines[index] = re.sub(r"^(private|fileprivate)\s+", "", line)
            break
    return "\n".join(lines)


def select(blocks, selector):
    """Resolve one selector into the blocks it names."""
    name, _, line = selector.partition("#")
    matches = [b for b in blocks if b[2] == name]
    if not matches:
        return []
    if line:
        wanted_line = int(line)
        matches = [b for b in matches if b[0] + 1 == wanted_line]
        if not matches:
            return []
    return matches


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    source = pathlib.Path(sys.argv[1])
    destination = pathlib.Path(sys.argv[2])
    selectors = sys.argv[3:]

    lines = source.read_text().split("\n")
    blocks = top_level_declarations(lines)

    # Map each block's own start index to its extent, so a move always advances
    # by the block actually removed rather than by a same-named block elsewhere.
    chosen = []
    taken = set()
    for selector in selectors:
        for start, end, name, text in select(blocks, selector):
            if start in taken:
                continue
            taken.add(start)
            chosen.append((start, end, name, text))

    if not chosen:
        print(f"error: no declarations matched {selectors}")
        print("available:", ", ".join(sorted({b[2] for b in blocks})))
        return 1

    # Emit in source order regardless of selector order, so the new file reads
    # the way the old one did and the diff stays reviewable.
    chosen.sort(key=lambda block: block[0])
    wanted_starts = {start for start, _, _, _ in chosen}
    moved_text = []
    kept = []
    index = 0
    cursor = 0
    while index < len(lines):
        if cursor < len(chosen) and index == chosen[cursor][0]:
            start, end, name, text = chosen[cursor]
            moved_text.append(strip_private(text))
            cursor += 1
            index = end
            continue
        if index in wanted_starts:
            index += 1
            continue
        kept.append(lines[index])
        index += 1

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n\n\n".join(moved_text) + "\n")
    source.write_text("\n".join(kept))

    print(f"moved {len(chosen)} declaration(s) to {destination}:")
    for start, end, name, _ in sorted(chosen):
        print(f"    {name} (lines {start + 1}..{end})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
