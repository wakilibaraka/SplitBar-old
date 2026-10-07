import Foundation
import Testing

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
}
