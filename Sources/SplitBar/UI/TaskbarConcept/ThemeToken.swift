// ThemeToken.swift — Semantic design tokens for the SplitBar theme system.
// Views resolve surface/stroke/accent/text roles from these tokens instead of
// scattering raw colors and `if style == .classic98` checks. Motion tokens
// centralize spring curves and Reduce Motion fallbacks.

import SwiftUI

/// Shadow definition for a themed surface.
struct ShadowSpec: Equatable {
    /// Shadow tint colour.
    var color: Color
    /// Blur radius (0 = hard shadow, used by Neobrutalism).
    var radius: CGFloat
    var x: CGFloat = 0
    var y: CGFloat

    static func surfaceShadow(for style: SurfaceStyle, darkMode: Bool) -> ShadowSpec {
        switch style {
        case .neobrutalism:
            ShadowSpec(color: .black.opacity(0.85), radius: 0, x: 6, y: 6)
        case .minimalism:
            ShadowSpec(color: .black.opacity(0.06), radius: 10, y: 4)
        case .classic98:
            ShadowSpec(color: .black.opacity(0.25), radius: 0, x: 2, y: 2)
        default:
            ShadowSpec(color: .black.opacity(darkMode ? 0.30 : 0.16), radius: 22, y: 10)
        }
    }
}

/// Border stroke definition for a themed surface.
struct BorderSpec: Equatable {
    /// One colour = solid stroke; two colours = gradient stroke; empty = no border.
    var colors: [Color]
    /// Stroke width in points.
    var width: CGFloat
    /// True for Win 98 / Win XP-style two-tone bevel borders.
    var isBevel: Bool = false

    static func surfaceBorder(for style: SurfaceStyle, darkMode: Bool) -> BorderSpec {
        switch style {
        case .classic98:
            BorderSpec(colors: [.white], width: 2, isBevel: true)
        case .neobrutalism:
            BorderSpec(colors: [.black], width: 3)
        case .windowsXP:
            BorderSpec(colors: [.white.opacity(0.85)], width: 1, isBevel: true)
        case .minimalism:
            BorderSpec(colors: [Color.primary.opacity(0.10)], width: 1)
        default:
            BorderSpec(colors: [.white.opacity(darkMode ? 0.14 : 0.76)], width: 1)
        }
    }
}

/// Text weight / design intent for a theme.
enum TextEmphasisStyle: String {
    case regular    // SF Pro
    case rounded    // SF Pro Rounded — claymorphism, liquid glass
    case bold       // SF Pro Bold — neobrutalism
    case light      // SF Pro Light — minimalism
    case black      // SF Pro Black — Y2K

    static func emphasis(for style: SurfaceStyle) -> TextEmphasisStyle {
        switch style {
        case .claymorphism, .liquidGlass:
            .rounded
        case .neobrutalism:
            .bold
        case .minimalism:
            .light
        case .y2k:
            .black
        default:
            .regular
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .regular: .default
        case .rounded: .rounded
        case .bold: .default
        case .light: .default
        case .black: .default
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .rounded: .regular
        case .bold: .bold
        case .light: .light
        case .black: .black
        }
    }
}

/// Semantic color roles for one theme + appearance combination.
struct ThemeTokens: Equatable {
    var surface: Color
    var card: Color
    var bar: Color
    var accent: Color
    var wash: Color

    static func resolve(style: SurfaceStyle, darkMode: Bool) -> ThemeTokens {
        ThemeTokens(
            surface: style.panelFill(darkMode: darkMode),
            card: style.cardFill(darkMode: darkMode),
            bar: style.taskbarFill(darkMode: darkMode),
            accent: style.accent(darkMode: darkMode),
            wash: surfaceWash(style: style, darkMode: darkMode)
        )
    }
}

/// Motion curves with Reduce Motion fallbacks.
enum MotionTokens {
    static func spring(response: Double, dampingFraction: Double = 0.82, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.1) : .spring(response: response, dampingFraction: dampingFraction)
    }

    static func flyoutTransition(_ animation: FlyoutAnimation, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return animation.asTransition()
    }
}
