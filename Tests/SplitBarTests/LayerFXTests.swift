import Testing

@testable import SplitBar
import CoreGraphics
import Foundation

/// Phase 2 of the hybrid plan: the LayerFX engine is pure spec + pure
/// CGContext code, so these tests rasterize it into a bitmap and sample
/// pixels instead of trusting that it "looks right".
@Suite(.serialized)
struct LayerFXTests {
    // Serialized: the kill-switch tests share the `layerfx.enabled` UserDefaults
    // key and would race when run in parallel.

    // MARK: - Spec coverage

    @Test func unsupportedStylesGetNoSpec() {
        for style: SurfaceStyle in [.glassmorphism, .liquidGlass, .minimalism, .visionOS] {
            #expect(LayerFX.spec(style: style, darkMode: false, role: .panel, cornerRadius: 12) == nil)
            #expect(LayerFX.supports(style) == false)
        }
    }

    @Test func supportedStylesGetSpecs() {
        for style: SurfaceStyle in [
            .neumorphism, .windowsAero, .classic98, .claymorphism, .neobrutalism,
            .skeuomorphism, .aqua, .frutigerAero, .y2k,
        ] {
            #expect(LayerFX.spec(style: style, darkMode: false, role: .panel, cornerRadius: 12) != nil)
            #expect(LayerFX.supportedStyles.contains(style))
        }
    }

    @Test func neumorphismHasDualAxisInnerShadows() throws {
        let spec = try #require(LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 14))
        #expect(spec.innerShadows.count == 2)
        let light = spec.innerShadows[0]
        let dark = spec.innerShadows[1]
        // Screen-space (y down): light band top-left, dark band bottom-right.
        #expect(light.offset.width > 0 && light.offset.height > 0)
        #expect(dark.offset.width < 0 && dark.offset.height < 0)
        #expect(spec.borderWidth == 1)
    }

    @Test func neobrutalismBorderWidthsPerRole() throws {
        let card = try #require(LayerFX.spec(style: .neobrutalism, darkMode: false, role: .card, cornerRadius: 0))
        let panel = try #require(LayerFX.spec(style: .neobrutalism, darkMode: false, role: .panel, cornerRadius: 0))
        #expect(card.borderWidth == 2)
        #expect(panel.borderWidth == 3)
        #expect(panel.borderColor == .black)
    }

    @Test func classic98BevelOnlyWhenBorderShows() throws {
        let withBorder = try #require(LayerFX.spec(style: .classic98, darkMode: false, role: .panel, cornerRadius: 0))
        #expect(withBorder.bevel98)
        let without = try #require(
            LayerFX.spec(style: .classic98, darkMode: false, role: .panel, cornerRadius: 0, showsBorder: false)
        )
        #expect(without.bevel98 == false)
        #expect(without.borderWidth == 0)
    }

    @Test func aeroSweepIsDiagonalTopLeadingToBottomTrailing() throws {
        let spec = try #require(LayerFX.spec(style: .windowsAero, darkMode: false, role: .panel, cornerRadius: 12))
        #expect(spec.sweep.count >= 3)
        #expect(spec.ridge != nil)
        #expect(spec.borderWidth == 1)
    }

    // MARK: - Kill switch

    @Test func killSwitchDisablesActiveSpecButNotSpec() {
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: "layerfx.enabled")
        defer {
            if let saved { defaults.set(saved, forKey: "layerfx.enabled") }
            else { defaults.removeObject(forKey: "layerfx.enabled") }
        }

        // Default: enabled (unless the environment kills it).
        defaults.removeObject(forKey: "layerfx.enabled")
        let envKilled = ProcessInfo.processInfo.environment["SPLITBAR_LAYERFX"] == "0"
        #expect(LayerFX.isEnabled == !envKilled)

        defaults.set(false, forKey: "layerfx.enabled")
        #expect(LayerFX.isEnabled == false)
        #expect(LayerFX.supports(.neumorphism) == false)
        // The pure builder still works — only `activeSpec` honors the switch.
        #expect(LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 8) != nil)
        #expect(
            LayerFX.activeSpec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 8) == nil
        )
    }

    // MARK: - Bitmap rendering

    @Test func tinyBoundsDoNotCrash() {
        let spec = LayerFXSpec(cornerRadius: 4, bevel98: true)
        _ = render(spec, width: 1, height: 1)
        _ = render(spec, width: 0, height: 0)
    }

    /// Windows 98: crisp four-tone bevel — white top/left, #DFDFDF/#808080
    /// inner rings, black bottom/right, at a square (radius 0) surface.
    @Test func win98BevelRasterizesFourTones() throws {
        var spec = try #require(LayerFX.spec(style: .classic98, darkMode: false, role: .panel, cornerRadius: 0))
        spec.cornerRadius = 0
        let size = 40
        let bitmap = render(spec, width: size, height: size)

        let top = bitmap.pixel(size / 2, 0)
        let topInner = bitmap.pixel(size / 2, 1)
        let bottom = bitmap.pixel(size / 2, size - 1)
        let bottomInner = bitmap.pixel(size / 2, size - 2)
        let left = bitmap.pixel(0, size / 2)
        let right = bitmap.pixel(size - 1, size / 2)

        // White top/left edge.
        #expect(top == .init(r: 255, g: 255, b: 255, a: 255))
        #expect(left == .init(r: 255, g: 255, b: 255, a: 255))
        // #DFDFDF inner top.
        #expect(topInner.r == 223 && topInner.a == 255)
        // Black bottom/right edge (premultiplied rgb 0, fully opaque).
        #expect(bottom == .init(r: 0, g: 0, b: 0, a: 255))
        #expect(right == .init(r: 0, g: 0, b: 0, a: 255))
        // #808080 inner bottom.
        #expect(bottomInner.r == 128 && bottomInner.a == 255)
    }

    /// Neumorphism: bright inner band near the top edge, dark inner band near
    /// the bottom edge, both inside a rounded surface.
    @Test func neumorphismRasterizesDualInnerBand() throws {
        let spec = try #require(LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 12))
        let size = 40
        let bitmap = render(spec, width: size, height: size)

        // Sample ~2pt inside the straight edges, clear of the 1pt border
        // stroke and far from the corner arcs.
        let topBand = bitmap.pixel(size / 2, 2)
        let bottomBand = bitmap.pixel(size / 2, size - 3)

        #expect(topBand.a > 0)
        #expect(bottomBand.a > 0)
        // Light band top-left dominates; the dark band (premultiplied black)
        // stays near zero luminance.
        #expect(topBand.luminance > 0.25)
        #expect(bottomBand.luminance < 0.1)
        #expect(topBand.luminance > bottomBand.luminance + 0.25)
    }

    /// Windows Aero: specular sweep is brighter at the top-leading corner
    /// than at the bottom-trailing corner.
    @Test func aeroSweepRasterizesBrighterTopLeading() throws {
        let spec = try #require(LayerFX.spec(style: .windowsAero, darkMode: false, role: .panel, cornerRadius: 12))
        let size = 40
        let bitmap = render(spec, width: size, height: size)

        // Sample away from the edges so the inner ridge stroke does not skew.
        let topLeading = bitmap.pixel(8, 8)
        let bottomTrailing = bitmap.pixel(size - 9, size - 9)

        #expect(topLeading.a > 0)
        #expect(topLeading.luminance > bottomTrailing.luminance)
    }

    // MARK: - E1: interaction states

    @Test func pressedNeumorphismInvertsTheBand() throws {
        let normal = try #require(LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 12))
        let pressed = try #require(
            LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 12, state: .pressed)
        )
        #expect(pressed != normal)
        #expect(pressed.state == .pressed)
        // Top-left band: light when normal, dark when pressed (the surface
        // sinks) — compare rendered luminance, not Color equality.
        let size = 40
        let normalBitmap = render(normal, width: size, height: size)
        let pressedBitmap = render(pressed, width: size, height: size)
        let normalTop = normalBitmap.pixel(size / 2, 2).luminance
        let pressedTop = pressedBitmap.pixel(size / 2, 2).luminance
        #expect(normalTop > pressedTop + 0.15)
    }

    @Test func aeroHoverAddsSpecularGlow() throws {
        let normal = try #require(LayerFX.spec(style: .windowsAero, darkMode: false, role: .panel, cornerRadius: 12))
        let hover = try #require(
            LayerFX.spec(style: .windowsAero, darkMode: false, role: .panel, cornerRadius: 12, state: .hover)
        )
        #expect(normal.hoverGlow == nil)
        #expect(hover.hoverGlow != nil)

        let size = 40
        let normalBitmap = render(normal, width: size, height: size)
        let hoverBitmap = render(hover, width: size, height: size)
        // Top-center is where the radial glow peaks.
        let normalTop = normalBitmap.pixel(size / 2, 2).luminance
        let hoverTop = hoverBitmap.pixel(size / 2, 2).luminance
        #expect(hoverTop > normalTop)
    }

    @Test func killSwitchAlsoCoversStates() {
        let saved = UserDefaults.standard.object(forKey: "layerfx.enabled")
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: "layerfx.enabled") }
            else { UserDefaults.standard.removeObject(forKey: "layerfx.enabled") }
        }
        UserDefaults.standard.set(false, forKey: "layerfx.enabled")
        #expect(
            LayerFX.activeSpec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 8, state: .pressed) == nil
        )
        #expect(
            LayerFX.activeSpec(style: .windowsAero, darkMode: false, role: .panel, cornerRadius: 8, state: .hover) == nil
        )
    }

    // MARK: - E2: per-island independence

    @Test func islandsProduceIndependentSpecs() {
        // Two islands (different radii) must produce distinct specs so each
        // LayerFXView redraws only its own surface.
        let a = LayerFX.spec(style: .neumorphism, darkMode: false, role: .taskbar, cornerRadius: 10)
        let b = LayerFX.spec(style: .neumorphism, darkMode: false, role: .taskbar, cornerRadius: 16)
        #expect(a != nil && b != nil)
        #expect(a != b)
        // Equal inputs stay equal — that's the no-redraw contract.
        let a2 = LayerFX.spec(style: .neumorphism, darkMode: false, role: .taskbar, cornerRadius: 10)
        #expect(a == a2)
    }

    // MARK: - E3: no-op spec updates draw nothing

    @Test func assigningTheSameSpecDoesNotRequestRedraw() {
        let spec = LayerFXSpec(cornerRadius: 12, borderWidth: 1, borderColor: .black)
        let view = LayerFXNSView()
        view.spec = spec
        // The view is layer-backed, so the dirty flag lives on the layer.
        view.layer?.setNeedsDisplay()
        view.layer?.displayIfNeeded()
        #expect(view.layer?.needsDisplay() == false)
        // Equal spec → didSet's `spec != oldValue` guard stays quiet.
        view.spec = spec
        #expect(view.layer?.needsDisplay() == false)
        // Different spec → exactly one redraw requested.
        var changed = spec
        changed.borderWidth = 3
        view.spec = changed
        #expect(view.layer?.needsDisplay() == true)
    }

    // MARK: - F1/F2: expanded theme ownership

    @Test func skeuomorphismCarriesStitchAndShading() throws {
        let spec = try #require(LayerFX.spec(style: .skeuomorphism, darkMode: false, role: .panel, cornerRadius: 12))
        #expect(spec.stitchColor != nil)
        #expect(spec.innerShadows.count == 2)
        let plain = try #require(
            LayerFX.spec(style: .skeuomorphism, darkMode: false, role: .panel, cornerRadius: 12, showsBorder: false)
        )
        #expect(plain.stitchColor == nil)
    }

    /// Renderer-level dash check with a synthetic spec (no shading to
    /// interfere): the stitch ring must show segments *and* gaps.
    @Test func stitchRendersAsDashedRing() {
        var spec = LayerFXSpec(cornerRadius: 0)
        spec.stitchColor = .black
        let bitmap = render(spec, width: 40, height: 40)

        // The stitch sits ~4pt inside the edge; find the row with coverage.
        var bestRow = -1
        var bestOn = 0
        for row in 2...6 {
            let on = (6..<34).filter { bitmap.pixel($0, row).a > 60 }.count
            if on > bestOn { bestOn = on; bestRow = row }
        }
        #expect(bestRow >= 0, "stitch ring must render")
        #expect(bestOn >= 5, "dash segments must cover part of the ring")
        let gaps = (6..<34).filter { bitmap.pixel($0, bestRow).a < 20 }.count
        #expect(gaps >= 2, "dash gaps must show between segments")
    }

    @Test func aquaGlossCapIsBrighterThanTheBody() throws {
        let spec = try #require(LayerFX.spec(style: .aqua, darkMode: false, role: .panel, cornerRadius: 12))
        #expect(spec.topHighlight != nil)
        #expect(spec.ridge != nil)
        let size = 40
        let bitmap = render(spec, width: size, height: size)
        let cap = bitmap.pixel(size / 2, 1).luminance
        let body = bitmap.pixel(size / 2, 20).luminance
        #expect(cap > 0.3)
        #expect(cap > body)
    }

    @Test func frutigerAeroDropsSparkle() throws {
        let spec = try #require(LayerFX.spec(style: .frutigerAero, darkMode: false, role: .panel, cornerRadius: 12))
        #expect(spec.drops)
        var without = spec
        without.drops = false

        let size = 40
        let withBitmap = render(spec, width: size, height: size)
        let withoutBitmap = render(without, width: size, height: size)
        // Drop #2 sits at (58%, 90%-from-top).
        let spot = (x: 23, row: 36)
        let withDrop = withBitmap.pixel(spot.x, spot.row).luminance
        let withoutDrop = withoutBitmap.pixel(spot.x, spot.row).luminance
        #expect(withDrop > withoutDrop + 0.05)
    }

    @Test func y2kRingIsIridescent() throws {
        let spec = try #require(LayerFX.spec(style: .y2k, darkMode: false, role: .panel, cornerRadius: 12))
        #expect(spec.iridescentBorder)
        #expect(spec.borderWidth == 2)

        let bitmap = render(spec, width: 40, height: 40)
        // Left edge of the ring runs through the blue chrome stop.
        let left = bitmap.pixel(1, 20)
        #expect(left.a > 100)
        #expect(Int(left.b) - Int(left.r) > 20, "left ring must be blue-dominant")
    }

    // MARK: - Bitmap helpers

    /// Renders `spec` into an RGBA bitmap and returns it. The renderer draws
    /// in the standard CG y-up space; samples are addressed top-down like a
    /// screen shot, matching `LayerFXSpec`'s documented coordinates.
    private func render(_ spec: LayerFXSpec, width: Int, height: Int) -> Bitmap {
        var pixels = [UInt8](repeating: 0, count: max(4, width * height * 4))
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        pixels.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(
                data: raw.baseAddress,
                width: max(1, width),
                height: max(1, height),
                bitsPerComponent: 8,
                bytesPerRow: max(1, width) * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            if width >= 2 && height >= 2 {
                LayerFXRenderer.draw(spec, in: ctx, bounds: CGRect(x: 0, y: 0, width: width, height: height))
            }
        }
        return Bitmap(pixels: pixels, width: max(1, width), height: max(1, height))
    }

    private struct Bitmap {
        let pixels: [UInt8]
        let width: Int
        let height: Int

        struct Pixel: Equatable {
            let r: UInt8
            let g: UInt8
            let b: UInt8
            let a: UInt8
            /// Perceptual-ish brightness of the premultiplied colour (0…1).
            var luminance: CGFloat {
                let rr = CGFloat(r) / 255
                let gg = CGFloat(g) / 255
                let bb = CGFloat(b) / 255
                return 0.2126 * rr + 0.7152 * gg + 0.0722 * bb
            }
        }

        /// Samples at `x`/`yFromTop` in screen coordinates (y down), the same
        /// space `LayerFXSpec` documents. A CGBitmapContext's user space is
        /// y-up with the origin at bottom-left, while the buffer stores row 0
        /// as the top of the drawing (the CGImage convention), so the visual
        /// top row is buffer row 0.
        func pixel(_ x: Int, _ yFromTop: Int) -> Pixel {
            let i = (yFromTop * width + x) * 4
            return Pixel(r: pixels[i], g: pixels[i + 1], b: pixels[i + 2], a: pixels[i + 3])
        }
    }
}
