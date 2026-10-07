// ThemeToken.swift — Shared token structs for the SplitBar theme system.
// These replace the scattered inline style checks (e.g. `if style == .classic98`)
// with structured, type-safe token objects.

import SwiftUI

/// Shadow definition for a themed surface.
struct ShadowSpec {
    /// Shadow tint colour.
    var color: Color
    /// Blur radius (0 = hard shadow, used by Neobrutalism).
    var radius: CGFloat
    var x: CGFloat = 0
    var y: CGFloat
}

/// Border stroke definition for a themed surface.
struct BorderSpec {
    /// One colour = solid stroke; two colours = gradient stroke; empty = no border.
    var colors: [Color]
    /// Stroke width in points.
    var width: CGFloat
    /// True for Win 98 / Win XP-style two-tone bevel borders.
    var isBevel: Bool = false
}

/// Text weight / design intent for a theme.
enum TextEmphasisStyle: String {
    case regular    // SF Pro
    case rounded    // SF Pro Rounded — claymorphism, liquid glass
    case bold       // SF Pro Bold — neobrutalism
    case light      // SF Pro Light — minimalism
    case black      // SF Pro Black — Y2K
}
