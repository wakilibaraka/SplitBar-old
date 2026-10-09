import AppKit
import SwiftUI

/// Abstraction over panel translucency. Views keep calling the
/// `panelBackground` / `cardBackground` helpers, which delegate to the active
/// provider: system materials by default, solid fills when the user requests
/// Reduce Transparency or Increase Contrast. A Liquid Glass provider can slot
/// in later behind an availability check without touching call sites.
protocol GlassProviding {
    func panelBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle
    func cardBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle
    func taskbarBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle
}

/// Current behavior: system materials with per-theme opacity curves.
struct SystemMaterialGlass: GlassProviding {
    func panelBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        let opacity = 1 - transparency * 0.68
        let tokens = ThemeTokens.resolve(style: style, darkMode: darkMode)
        switch style {
        case .glassmorphism:
            return AnyShapeStyle((transparency > 0.55 ? Material.ultraThin : Material.regular).opacity(opacity))
        case .liquidGlass:
            return AnyShapeStyle(Material.regular.opacity(opacity))
        case .windowsAero:
            return AnyShapeStyle(Material.ultraThin.opacity(opacity))
        case .visionOS:
            return AnyShapeStyle(Material.ultraThick.opacity(opacity))
        case .cyberdeck, .neobrutalism:
            return AnyShapeStyle(tokens.surface)
        case .minimalism:
            return AnyShapeStyle(tokens.surface.opacity(min(1.0, opacity * 1.1)))
        default:
            return AnyShapeStyle(tokens.surface.opacity(opacity))
        }
    }

    func cardBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        let opacity = 1 - transparency * 0.42
        let tokens = ThemeTokens.resolve(style: style, darkMode: darkMode)
        switch style {
        case .glassmorphism:
            return AnyShapeStyle((transparency > 0.55 ? Material.ultraThin : Material.regular).opacity(opacity))
        case .liquidGlass:
            return AnyShapeStyle(Material.ultraThin.opacity(opacity))
        case .windowsAero:
            return AnyShapeStyle(Material.ultraThin.opacity(opacity))
        case .visionOS:
            return AnyShapeStyle(Material.thick.opacity(opacity))
        case .cyberdeck, .neobrutalism:
            return AnyShapeStyle(tokens.card)
        case .minimalism:
            return AnyShapeStyle(tokens.card.opacity(min(1.0, opacity * 1.1)))
        default:
            return AnyShapeStyle(tokens.card.opacity(opacity))
        }
    }

    func taskbarBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        let opacity = 1 - transparency * 0.45
        switch style {
        case .glassmorphism:
            return AnyShapeStyle((transparency > 0.55 ? Material.ultraThin : Material.regular).opacity(opacity))
        case .liquidGlass:
            return AnyShapeStyle(Material.regular.opacity(opacity))
        case .windowsAero:
            return AnyShapeStyle(Material.ultraThin.opacity(opacity))
        case .visionOS:
            return AnyShapeStyle(Material.ultraThick.opacity(opacity))
        case .cyberdeck, .neobrutalism, .windowsXP, .aqua, .frutigerAero, .y2k:
            return AnyShapeStyle(style.taskbarFill(darkMode: darkMode))
        case .minimalism:
            return AnyShapeStyle(style.taskbarFill(darkMode: darkMode).opacity(min(1.0, opacity * 1.1)))
        default:
            return AnyShapeStyle(style.taskbarFill(darkMode: darkMode).opacity(opacity))
        }
    }
}

/// Opaque fallback for accessibility display settings.
struct SolidFillGlass: GlassProviding {
    func panelBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        AnyShapeStyle(ThemeTokens.resolve(style: style, darkMode: darkMode).surface)
    }

    func cardBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        AnyShapeStyle(ThemeTokens.resolve(style: style, darkMode: darkMode).card)
    }

    func taskbarBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
        AnyShapeStyle(style.taskbarFill(darkMode: darkMode))
    }
}

/// Global glass family material toggle. Default `.frosted`; `.clear` keeps the
/// wallpaper even more visible by using the pure theme fill at a lighter opacity.
enum GlassMaterial: String, CaseIterable, Identifiable {
    case frosted
    case clear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .frosted: "Frosted"
        case .clear: "Clear (see-through)"
        }
    }

    var subtitle: String {
        switch self {
        case .frosted: "Soft blurred glass with wallpaper bleed"
        case .clear: "Stronger bleed for stronger wallpaper colour"
        }
    }
}

struct GlassProviderState: @unchecked Sendable {
    private init() {}

    static var current: GlassMaterial {
        get { GlassMaterial(rawValue: UserDefaults.standard.string(forKey: "ui.glassMaterial") ?? "") ?? .frosted }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "ui.glassMaterial") }
    }
}

extension GlassMaterial {
    func taskbar(style: SurfaceStyle, darkMode: Bool) -> AnyShapeStyle {
        if appliesTo(style: style) {
            return GlassProviders.current.taskbarBackground(style: style, darkMode: darkMode, transparency: 0)
        }
        return AnyShapeStyle(style.taskbarFill(darkMode: darkMode))
    }

    func background(style: SurfaceStyle, darkMode: Bool) -> AnyShapeStyle {
        if appliesTo(style: style) {
            return GlassProviders.current.panelBackground(style: style, darkMode: darkMode, transparency: 0)
        }
        return AnyShapeStyle(style.panelFill(darkMode: darkMode))
    }

    fileprivate func appliesTo(style: SurfaceStyle) -> Bool {
        guard GlassProviderState.current == .clear else { return false }
        return style == .glassmorphism || style == .liquidGlass || style == .windowsAero || style == .visionOS
    }
}

enum GlassProviders {
    static var current: GlassProviding {
        let workspace = NSWorkspace.shared
        if workspace.accessibilityDisplayShouldReduceTransparency || workspace.accessibilityDisplayShouldIncreaseContrast {
            return SolidFillGlass()
        }
        return SystemMaterialGlass()
    }
}
