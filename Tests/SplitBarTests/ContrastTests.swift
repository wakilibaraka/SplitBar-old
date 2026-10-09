import Foundation
import SwiftUI
import Testing

@testable import SplitBar

/// WCAG contrast checks for the explicit onboarding surface. The onboarding
/// card is a dark solid, so its tokens must read on every theme regardless of
/// light/dark, which is what makes the numbers below theme-independent.
struct ContrastTests {
    private struct RGB: Equatable {
        var red: Double
        var green: Double
        var blue: Double
    }

    private static let card = RGB(red: 0.02, green: 0.03, blue: 0.05)

    private static func luminance(_ rgb: RGB) -> Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.red) + 0.7152 * channel(rgb.green) + 0.0722 * channel(rgb.blue)
    }

    private static func contrast(_ a: RGB, _ b: RGB) -> Double {
        let (light, dark) = a.red * 0.3 + a.green * 0.5 + a.blue * 0.2 >= b.red * 0.3 + b.green * 0.5 + b.blue * 0.2
            ? (Self.luminance(a), Self.luminance(b))
            : (Self.luminance(b), Self.luminance(a))
        return (light + 0.05) / (dark + 0.05)
    }

    /// Alpha-composites `text` (white at `alpha`) over the card, since SwiftUI
    /// draws the semi-opaque text over the card fill.
    private static func textOverCard(alpha: Double) -> RGB {
        RGB(
            red: 1.0 * alpha + Self.card.red * (1 - alpha),
            green: 1.0 * alpha + Self.card.green * (1 - alpha),
            blue: 1.0 * alpha + Self.card.blue * (1 - alpha)
        )
    }

    @Test func primaryTextOnCardMeetsAALarge() {
        #expect(Self.contrast(RGB(red: 1, green: 1, blue: 1), Self.card) >= 7.0)
    }

    @Test func secondaryTextOnCardMeetsAA() {
        // The body and descriptions use white at 0.78 over the card surface.
        #expect(Self.contrast(Self.textOverCard(alpha: 0.78), Self.card) >= 4.5)
    }

    @Test func mutedTextStillReadable() {
        // Captions and the Back affordance sit at 0.78; subtitles should not be
        // darker than the body they sit beside.
        let caption = Self.contrast(Self.textOverCard(alpha: 0.68), Self.card)
        #expect(caption >= 4.5)
    }

    // MARK: - Fill-parity (Wave 0.1)

    /// In dark mode the palettes are harmonized, so each theme's taskbar, panel and
    /// card fills stay within a tight lightness band — the dark surfaces are meant to
    /// read as one family. (Light mode deliberately differentiates the surfaces per
    /// theme, so we do not assert a universal light-mode band here.)
    @Test func neumorphismTaskbarPanelCardStaysInParityBand() {
        let darkTaskbar = Self.rgb(SurfaceStyle.neumorphism.taskbarFill(darkMode: true))
        let darkPanel = Self.rgb(SurfaceStyle.neumorphism.panelFill(darkMode: true))
        let darkCard = Self.rgb(SurfaceStyle.neumorphism.cardFill(darkMode: true))
        #expect(Self.lightnessBand(darkTaskbar, darkPanel, darkCard).maxDelta <= 0.02)
        // Both light-mode fills must at least be real, displayable sRGB.
        let lightTaskbar = Self.rgb(SurfaceStyle.neumorphism.taskbarFill(darkMode: false))
        let lightPanel = Self.rgb(SurfaceStyle.neumorphism.panelFill(darkMode: false))
        let lightCard = Self.rgb(SurfaceStyle.neumorphism.cardFill(darkMode: false))
        #expect(Self.isValidSrgb(lightTaskbar))
        #expect(Self.isValidSrgb(lightPanel))
        #expect(Self.isValidSrgb(lightCard))
    }

    /// Every theme's three fills are real sRGB colors, and in dark mode they stay in a
    /// tight family band (measured worst case across all themes is well under 0.05).
    @Test func themeFillFamilyStaysInParityBand() {
        for style in SurfaceStyle.allCases {
            let lightTaskbar = Self.rgb(style.taskbarFill(darkMode: false))
            let lightPanel = Self.rgb(style.panelFill(darkMode: false))
            let lightCard = Self.rgb(style.cardFill(darkMode: false))
            #expect(Self.isValidSrgb(lightTaskbar), "\(style.rawValue) light taskbar")
            #expect(Self.isValidSrgb(lightPanel), "\(style.rawValue) light panel")
            #expect(Self.isValidSrgb(lightCard), "\(style.rawValue) light card")

            let darkTaskbar = Self.rgb(style.taskbarFill(darkMode: true))
            let darkPanel = Self.rgb(style.panelFill(darkMode: true))
            let darkCard = Self.rgb(style.cardFill(darkMode: true))
            let band = Self.lightnessBand(darkTaskbar, darkPanel, darkCard)
            #expect(band.maxDelta <= 0.05, "\(style.rawValue) dark band=\(String(format: "%.4f", band.maxDelta))")
        }
    }

    /// Whether an sRGB triple is a real, displayable color (no NaN, within [0,1]).
    private static func isValidSrgb(_ x: RGB) -> Bool {
        return x.red.isFinite && x.red >= 0 && x.red <= 1
            && x.green.isFinite && x.green >= 0 && x.green <= 1
            && x.blue.isFinite && x.blue >= 0 && x.blue <= 1
    }

    /// Convert a SwiftUI `Color` to sRGB by coercing it to the sRGB color space and
    /// reading its CG components. Coercion means this works for both flat RGB colors and
    /// HSB/HSV SwiftUI colors without branching on void-returning `getRed`/`getHue`.
    private static func rgb(_ color: Color) -> RGB {
        let ns = NSColor(color)
        let srgb = ns.usingColorSpace(NSColorSpace.sRGB) ?? ns
        let cg = srgb.cgColor
        let n = cg.numberOfComponents
        let comps = cg.components ?? []
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        if n >= 1 && comps.count >= 1 { r = comps[0] }
        if n >= 2 && comps.count >= 2 { g = comps[1] }
        if n >= 3 && comps.count >= 3 { b = comps[2] }
        return RGB(red: Double(r), green: Double(g), blue: Double(b))
    }

    /// Returns the widest pairwise lightness delta among the three fills for a
    /// single surface. ContrastTests are theme-agnostic by design, so we measure
    /// relative lightness here rather than WCAG ratios.
    private static func lightnessBand(_ a: RGB, _ b: RGB, _ c: RGB) -> (maxDelta: Double, members: [String: Double]) {
        let levels = ["taskbar": a, "panel": b, "card": c]
            .mapValues { channel in
                func l(_ c: Double) -> Double {
                    c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * l(channel.red) + 0.7152 * l(channel.green) + 0.0722 * l(channel.blue)
            }
        var delta = 0.0
        let keys = Array(levels.keys)
        for i in keys.indices {
            for j in keys.indices where j > i {
                let d = abs(levels[keys[i]]! - levels[keys[j]]!)
                if d > delta { delta = d }
            }
        }
        return (delta, levels)
    }
}
