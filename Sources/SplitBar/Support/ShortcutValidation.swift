import Foundation

public func shortcutConflicts(bindings: [ShortcutBinding]) -> [ShortcutConflict] {
    var chordMap: [ShortcutChord: [UUID]] = [:]
    for binding in bindings {
        chordMap[binding.chord, default: []].append(binding.id)
    }

    var conflicts: [ShortcutConflict] = []
    for (chord, ids) in chordMap where ids.count > 1 {
        conflicts.append(
            ShortcutConflict(
                bindingIDs: Set(ids),
                chord: chord
            )
        )
    }

    return conflicts.sorted {
        if $0.chord.carbonKeyCode != $1.chord.carbonKeyCode {
            return $0.chord.carbonKeyCode < $1.chord.carbonKeyCode
        }
        return $0.chord.carbonModifiers < $1.chord.carbonModifiers
    }
}
