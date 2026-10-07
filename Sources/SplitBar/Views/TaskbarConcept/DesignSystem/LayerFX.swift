import AppKit
import SwiftUI

// MARK: - LayerFX
//
// Phase 2 of the hybrid architecture plan: theme surface decorations that
// SwiftUI expresses poorly (true dual-axis inner shadows, pixel-crisp 3D
// bevels, specular sheens, inner glass ridges) are drawn with Core Graphics
// inside an `NSViewRepresentable`, one drawing pass per layout change.
//
// LayerFX draws *in-bounds decoration only*: fills/translucent materials stay
// in SwiftUI (`GlassProvider`) and outer drop shadows stay in the SwiftUI
// surface modifiers, so panels keep their existing compositing. The renderer
// is pure `CGContext` code (`LayerFXRenderer`) so tests can rasterize it into
// a bitmap and sample pixels.
enum LayerFX {

    /// Styles the CG renderer takes over. Everything else keeps the legacy
    /// SwiftUI stroke/gradient overlays.
    static let supportedStyles: Set<SurfaceStyle> = [
        .neumorphism, .windowsAero, .classic98, .claymorphism, .neobrutalism
    ]

    /// Surface role — mirrors the three SwiftUI surface modifiers.
    enum Role: Equatable {
        case panel
        case card
        case taskbar
    }

    /// Kill switch: `SPLITBAR_LAYERFX=0` in the environment or the
    /// `layerfx.enabled` user default reverts every surface to the legacy
    /// SwiftUI rendering without recompiling.
    static var isEnabled: Bool {
        if let env = ProcessInfo.processInfo.environment["SPLITBAR_LAYERFX"], env == "0" {
            return false
        }
        return UserDefaults.standard.object(forKey: "layerfx.enabled") as? Bool ?? true
    }

    /// True when this style is drawn by LayerFX *and* LayerFX is enabled.
    static func supports(_ style: SurfaceStyle) -> Bool {
        isEnabled && supportedStyles.contains(style)
    }

    /// Pure spec builder: nil for styles LayerFX does not own.
    /// Ignored by the kill switch so tests can always build specs.
    static func spec(
        style: SurfaceStyle,
        darkMode: Bool,
        role: Role,
        cornerRadius: CGFloat,
        showsBorder: Bool = true
    ) -> LayerFXSpec? {
        guard supportedStyles.contains(style) else { return nil }

        var spec = LayerFXSpec(cornerRadius: cornerRadius)

        switch style {
        case .neumorphism:
            // Plan: authentic dual-axis inner shading — light top-left,
            // dark bottom-right — for the soft extruded edge.
            spec.innerShadows = [
                LayerFXSpec.InnerShadow(
                    color: .white.opacity(darkMode ? 0.09 : 0.85),
                    offset: CGSize(width: 3, height: 3),
                    blur: 5
                ),
                LayerFXSpec.InnerShadow(
                    color: .black.opacity(darkMode ? 0.55 : 0.20),
                    offset: CGSize(width: -3, height: -3),
                    blur: 7
                )
            ]
            spec.borderWidth = showsBorder ? 1 : 0
            spec.borderColor = cardBorder(role: role, style: .neumorphism)

        case .windowsAero:
            spec.sweep = aeroSweep(role: role)
            if showsBorder {
                spec.ridge = Color.white.opacity(darkMode ? 0.28 : 0.55)
                spec.borderWidth = 1
                spec.borderColor = .white.opacity(role == .taskbar ? 0.38 : (role == .card ? 0.9 : 0.76))
            }

        case .classic98:
            if showsBorder {
                spec.bevel98 = true
            }

        case .claymorphism:
            spec.topHighlight = .white.opacity(darkMode ? 0.16 : 0.45)
            spec.bottomRim = .white.opacity(darkMode ? 0.08 : 0.22)
            if showsBorder {
                spec.borderWidth = 1
                spec.borderColor = .white.opacity(role == .taskbar ? 0.2 : 0.9)
            }

        case .neobrutalism:
            if showsBorder {
                spec.borderWidth = role == .card ? 2 : 3
                spec.borderColor = .black
            }

        default:
            return nil
        }

        return spec
    }

    /// Spec honoring the kill switch — what the surface modifiers consume.
    static func activeSpec(
        style: SurfaceStyle,
        darkMode: Bool,
        role: Role,
        cornerRadius: CGFloat,
        showsBorder: Bool = true
    ) -> LayerFXSpec? {
        guard isEnabled else { return nil }
        return spec(
            style: style,
            darkMode: darkMode,
            role: role,
            cornerRadius: cornerRadius,
            showsBorder: showsBorder
        )
    }

    /// Per-role card border colours, matching the legacy SwiftUI modifiers.
    private static func cardBorder(role: Role, style: SurfaceStyle) -> Color {
        switch style {
        case .neumorphism:
            switch role {
            case .card: Color.black.opacity(0.035)
            case .taskbar: Color.white.opacity(0.2)
            case .panel: Color.white.opacity(0.76)
            }
        default:
            .white.opacity(0.9)
        }
    }

    /// Specular sweep stops per role — lifted from the legacy SwiftUI
    /// Windows Aero overlays so the look is unchanged.
    private static func aeroSweep(role: Role) -> [Color] {
        switch role {
        case .panel: [.white.opacity(0.4), .white.opacity(0.0), .white.opacity(0.0), .white.opacity(0.15)]
        case .card: [.white.opacity(0.3), .white.opacity(0.0), .white.opacity(0.1)]
        case .taskbar: [.white.opacity(0.5), .white.opacity(0.0), .white.opacity(0.0), .white.opacity(0.2)]
        }
    }
}

// MARK: - Spec

/// Everything LayerFX draws for one surface, in screen coordinates
/// (origin top-left, y grows downward).
struct LayerFXSpec: Equatable {
    struct InnerShadow: Equatable {
        /// Shadow colour; the visible band inside the surface uses this alpha.
        var color: Color
        /// Screen-space offset (y down). A positive offset puts the inner
        /// band along the top-left edges; negative puts it bottom-right.
        var offset: CGSize
        var blur: CGFloat
    }

    var cornerRadius: CGFloat
    /// Solid border stroke (ignored when `bevel98` is set).
    var borderWidth: CGFloat = 0
    var borderColor: Color = .clear
    /// True dual-axis inner shadows (Neumorphism).
    var innerShadows: [InnerShadow] = []
    /// Diagonal top-leading → bottom-trailing specular stops (Windows Aero).
    var sweep: [Color] = []
    /// Bright 1 pt inner glass ridge along the edge (Windows Aero).
    var ridge: Color?
    /// Claymorphism: specular highlight fading down from the top edge.
    var topHighlight: Color?
    /// Claymorphism: rim light fading up from the bottom edge.
    var bottomRim: Color?
    /// Windows 98 four-tone bevel; replaces the solid border.
    var bevel98: Bool = false

    func path(in bounds: CGRect) -> CGPath {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: bounds)
            .cgPath
    }
}

// MARK: - Renderer

enum LayerFXRenderer {

    /// Draws `spec` decoration into `bounds`. Assumes a Core Graphics
    /// context with the standard y-up (bottom-left origin) space, as
    /// provided by `NSView.draw(_:)` and `CGBitmapContext`.
    static func draw(_ spec: LayerFXSpec, in ctx: CGContext, bounds: CGRect) {
        guard bounds.width >= 2, bounds.height >= 2 else { return }

        let path = spec.path(in: bounds)

        if !spec.sweep.isEmpty {
            drawSweep(spec.sweep, path: path, bounds: bounds, ctx: ctx)
        }
        if let top = spec.topHighlight {
            drawVerticalFade(top, path: path, bounds: bounds, ctx: ctx, fromTop: true, depth: 30)
        }
        if let bottom = spec.bottomRim {
            drawVerticalFade(bottom, path: path, bounds: bounds, ctx: ctx, fromTop: false, depth: 18)
        }
        for shadow in spec.innerShadows {
            drawInnerShadow(shadow, path: path, bounds: bounds, ctx: ctx)
        }
        if let ridge = spec.ridge {
            drawRidge(ridge, spec: spec, path: path, bounds: bounds, ctx: ctx)
        }
        if spec.bevel98 {
            drawBevel98(spec: spec, path: path, bounds: bounds, ctx: ctx)
        } else if spec.borderWidth > 0 {
            drawBorder(spec: spec, path: path, bounds: bounds, ctx: ctx)
        }
    }

    // MARK: Inner shadow (inverted-clip technique)

    private static func drawInnerShadow(
        _ shadow: LayerFXSpec.InnerShadow,
        path: CGPath,
        bounds: CGRect,
        ctx: CGContext
    ) {
        ctx.saveGState()
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()

        // Screen y-down → CG y-up.
        let cgOffset = CGSize(width: shadow.offset.width, height: -shadow.offset.height)
        ctx.setShadow(
            offset: cgOffset,
            blur: shadow.blur,
            color: cgColor(shadow.color)
        )

        // Fill the region *outside* the shape with an opaque colour: only its
        // shadow can fall inside the clip, producing a true inner shadow.
        let bleed = shadow.blur * 2 + abs(shadow.offset.width) + abs(shadow.offset.height) + 8
        let outer = bounds.insetBy(dx: -bleed, dy: -bleed)
        ctx.beginPath()
        ctx.addPath(CGPath(rect: outer, transform: nil))
        ctx.addPath(path)
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.drawPath(using: .eoFill)

        ctx.restoreGState()
    }

    // MARK: Aero specular sweep + inner ridge

    private static func drawSweep(_ colors: [Color], path: CGPath, bounds: CGRect, ctx: CGContext) {
        guard let gradient = cgGradient(colors) else { return }
        ctx.saveGState()
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        // y-up: top-leading is (minX, maxY).
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: bounds.minX, y: bounds.maxY),
            end: CGPoint(x: bounds.maxX, y: bounds.minY),
            options: []
        )
        ctx.restoreGState()
    }

    private static func drawRidge(_ color: Color, spec: LayerFXSpec, path: CGPath, bounds: CGRect, ctx: CGContext) {
        // The ridge sits just *inside* the solid border (1…2 pt from the edge),
        // so it reads as the bright inner glass line without doubling the stroke.
        ctx.saveGState()
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        ctx.setStrokeColor(cgColor(color))
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.addPath(insetPath(spec, depth: 1.5, bounds: bounds))
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Claymorphism fades

    private static func drawVerticalFade(
        _ color: Color,
        path: CGPath,
        bounds: CGRect,
        ctx: CGContext,
        fromTop: Bool,
        depth: CGFloat
    ) {
        guard let gradient = cgGradient([color, .clear]) else { return }
        ctx.saveGState()
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        let start: CGPoint
        let end: CGPoint
        if fromTop {
            start = CGPoint(x: bounds.midX, y: bounds.maxY)
            end = CGPoint(x: bounds.midX, y: bounds.maxY - depth)
        } else {
            start = CGPoint(x: bounds.midX, y: bounds.minY)
            end = CGPoint(x: bounds.midX, y: bounds.minY + depth)
        }
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        ctx.restoreGState()
    }

    // MARK: Windows 98 four-tone bevel

    private static func drawBevel98(spec: LayerFXSpec, path: CGPath, bounds: CGRect, ctx: CGContext) {
        // Built in sRGB explicitly: `CGColor(red:green:blue:alpha:)` lands in
        // Apple's generic calibrated space and shifts tones (0.875 → 0.898)
        // when drawn into an sRGB bitmap, breaking the pixel-exact bevel.
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        func tone(_ value: CGFloat) -> CGColor {
            CGColor(colorSpace: srgb, components: [value, value, value, 1])!
        }
        let white = tone(1)                 // #FFFFFF
        let df = tone(0.875)                // #DFDFDF
        let grey = tone(0.502)              // #808080
        let black = tone(0)                 // #000000

        // Drawn black → grey → df → white so top/left tones own the corners
        // where the edge strips meet.
        bevelTone(depth: 0, edges: [.bottom, .right], color: black, spec: spec, path: path, bounds: bounds, ctx: ctx)
        bevelTone(depth: 1, edges: [.bottom, .right], color: grey, spec: spec, path: path, bounds: bounds, ctx: ctx)
        bevelTone(depth: 1, edges: [.top, .left], color: df, spec: spec, path: path, bounds: bounds, ctx: ctx)
        bevelTone(depth: 0, edges: [.top, .left], color: white, spec: spec, path: path, bounds: bounds, ctx: ctx)
    }

    private enum BevelEdge { case top, left, bottom, right }

    private static func bevelTone(
        depth: CGFloat,
        edges: [BevelEdge],
        color: CGColor,
        spec: LayerFXSpec,
        path: CGPath,
        bounds: CGRect,
        ctx: CGContext
    ) {
        ctx.saveGState()
        ctx.setShouldAntialias(false)

        // Ring between `depth` and `depth + 1` from the edge.
        ctx.beginPath()
        ctx.addPath(path)
        ctx.addPath(insetPath(spec, depth: depth + 1, bounds: bounds))
        ctx.clip(using: .evenOdd)

        // Restricted to the requested edges so each side gets its tone.
        ctx.beginPath()
        for edge in edges {
            switch edge {
            case .top: ctx.addPath(CGPath(rect: CGRect(x: bounds.minX, y: bounds.maxY - depth - 1, width: bounds.width, height: 1), transform: nil))
            case .bottom: ctx.addPath(CGPath(rect: CGRect(x: bounds.minX, y: bounds.minY + depth, width: bounds.width, height: 1), transform: nil))
            case .left: ctx.addPath(CGPath(rect: CGRect(x: bounds.minX + depth, y: bounds.minY, width: 1, height: bounds.height), transform: nil))
            case .right: ctx.addPath(CGPath(rect: CGRect(x: bounds.maxX - depth - 1, y: bounds.minY, width: 1, height: bounds.height), transform: nil))
            }
        }
        ctx.clip()

        ctx.setStrokeColor(color)
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.addPath(insetPath(spec, depth: depth + 0.5, bounds: bounds))
        ctx.strokePath()

        ctx.restoreGState()
    }

    // MARK: Solid border

    private static func drawBorder(spec: LayerFXSpec, path: CGPath, bounds: CGRect, ctx: CGContext) {
        let inset = spec.borderWidth / 2
        ctx.saveGState()
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        ctx.setStrokeColor(cgColor(spec.borderColor))
        ctx.setLineWidth(spec.borderWidth)
        if spec.cornerRadius == 0 {
            ctx.setShouldAntialias(false)
        }
        ctx.beginPath()
        ctx.addPath(insetPath(spec, depth: inset, bounds: bounds))
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Helpers

    private static func insetPath(_ spec: LayerFXSpec, depth: CGFloat, bounds: CGRect) -> CGPath {
        RoundedRectangle(
            cornerRadius: max(0, spec.cornerRadius - depth),
            style: .continuous
        )
        .path(in: bounds.insetBy(dx: depth, dy: depth))
        .cgPath
    }

    static func cgColor(_ color: Color) -> CGColor {
        NSColor(color).usingColorSpace(.deviceRGB)?.cgColor ?? CGColor(gray: 0, alpha: 1)
    }

    private static func cgGradient(_ colors: [Color]) -> CGGradient? {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let resolved: [CGColor] = colors.map {
            NSColor($0).usingColorSpace(.sRGB)?.cgColor ?? CGColor(gray: 0, alpha: 0)
        }
        return CGGradient(colorsSpace: space, colors: resolved as CFArray, locations: nil)
    }
}

// MARK: - View

/// SwiftUI bridge: a transparent, click-through `NSView` that renders one
/// `LayerFXSpec` per draw pass. Redraws only when the spec or bounds change.
struct LayerFXView: NSViewRepresentable {
    let spec: LayerFXSpec

    func makeNSView(context: Context) -> LayerFXNSView {
        let view = LayerFXNSView()
        view.spec = spec
        return view
    }

    func updateNSView(_ nsView: LayerFXNSView, context: Context) {
        nsView.spec = spec
    }
}

final class LayerFXNSView: NSView {
    var spec: LayerFXSpec? {
        didSet {
            if spec != oldValue {
                needsDisplay = true
            }
        }
    }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.needsDisplayOnBoundsChange = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isOpaque: Bool { false }

    /// Decoration must never intercept clicks destined for the SwiftUI content.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let spec, let ctx = NSGraphicsContext.current?.cgContext else { return }
        LayerFXRenderer.draw(spec, in: ctx, bounds: bounds)
    }
}
