import Testing

@testable import SplitBar
import CoreGraphics
import Foundation

/// Wave 8 (HYBRID_PLAN I1): headless micro-baseline for the LayerFX engine.
/// This measures pure CGContext render cost per spec — the *GUI* baseline
/// (Core Animation FPS during theme switch / island drag / Space switch,
/// memory) still needs a manual Instruments session; see HYBRID_PLAN I1.
///
/// No wall-clock assertions (flaky on CI) — it prints the measurement so a
/// human can record it.
struct LayerFXBenchmarkTests {

    @Test func measurePerSpecRenderCost() throws {
        let spec = try #require(
            LayerFX.spec(style: .neumorphism, darkMode: false, role: .panel, cornerRadius: 16)
        )
        let width = 600, height = 80
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let iterations = 500

        let start = DispatchTime.now()
        try pixels.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { throw BenchmarkError.noContext }
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            for _ in 0..<iterations {
                ctx.saveGState()
                LayerFXRenderer.draw(spec, in: ctx, bounds: bounds)
                ctx.restoreGState()
            }
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let microsPerRender = Double(elapsed) / Double(iterations) / 1000
        print(String(format: "LayerFX benchmark: %.1f µs/render (%dx%d, neumorphism panel spec)", microsPerRender, width, height))
    }

    private enum BenchmarkError: Error { case noContext }
}
