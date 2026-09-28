import AppKit
import SwiftUI

public struct AILogoView: View {
    public let agentType: AIAgentType
    public let size: CGFloat
    public let isMonochrome: Bool

    public init(
        agentType: AIAgentType,
        size: CGFloat,
        isMonochrome: Bool
    ) {
        self.agentType = agentType
        self.size = size
        self.isMonochrome = isMonochrome
    }

    public var body: some View {
        Group {
            switch agentType {
            case .claude:
                claudeAsterisk
            case .codex:
                openAIRosette
            case .opencode:
                openCodeTerminal
            case .ollama:
                ollamaSilhouette
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Anthropic Claude Asterisk Logo

    private var claudeAsterisk: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)
            let spokeCount = 12
            let baseLength = canvasSize.width * 0.42
            let spokeWidth = canvasSize.width * 0.12

            for i in 0..<spokeCount {
                let angle = Double(i) * (2.0 * .pi / Double(spokeCount))
                let lengthVariation = (i % 2 == 0) ? baseLength : (baseLength * 0.72)
                var path = Path()

                let start = center
                let end = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * lengthVariation,
                    y: center.y + CGFloat(sin(angle)) * lengthVariation
                )

                path.move(to: start)
                path.addLine(to: end)

                let color = isMonochrome
                    ? Color.white
                    : Color(red: 0.85, green: 0.47, blue: 0.34) // Anthropic Terracotta

                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: spokeWidth, lineCap: .round)
                )
            }
        }
    }

    // MARK: - OpenAI Spiral Rosette Logo

    private var openAIRosette: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)
            let radius = canvasSize.width * 0.36
            let armCount = 6
            let lineWidth = canvasSize.width * 0.10

            for i in 0..<armCount {
                let startAngle = Double(i) * (2.0 * .pi / Double(armCount))
                let p1 = CGPoint(
                    x: center.x + CGFloat(cos(startAngle)) * (radius * 0.4),
                    y: center.y + CGFloat(sin(startAngle)) * (radius * 0.4)
                )
                let p2 = CGPoint(
                    x: center.x + CGFloat(cos(startAngle + 0.6)) * radius,
                    y: center.y + CGFloat(sin(startAngle + 0.6)) * radius
                )
                let p3 = CGPoint(
                    x: center.x + CGFloat(cos(startAngle + 1.2)) * (radius * 0.85),
                    y: center.y + CGFloat(sin(startAngle + 1.2)) * (radius * 0.85)
                )

                var path = Path()
                path.move(to: p1)
                path.addQuadCurve(to: p3, control: p2)

                let color = isMonochrome
                    ? Color.white
                    : Color(red: 0.10, green: 0.80, blue: 0.55) // OpenAI Emerald

                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
    }

    // MARK: - Ollama Mascot Silhouette Logo

    private var ollamaSilhouette: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            var path = Path()

            // Stylized llama profile
            // Ears
            path.move(to: CGPoint(x: w * 0.32, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.30))
            path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.32))

            // Snout and head
            path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.35))
            path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.48))
            path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.50))

            // Neck down
            path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.68))

            // Back & tail
            path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.68))
            path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.60))
            path.addLine(to: CGPoint(x: w * 0.20, y: h * 0.72))

            // Legs
            path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.76))
            path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.76))
            path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.88))
            path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.52))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.42))
            path.closeSubpath()

            let color = isMonochrome
                ? Color.white
                : Color(red: 0.95, green: 0.95, blue: 0.95)

            context.fill(path, with: .color(color))
        }
    }

    // MARK: - OpenCode Terminal Logo

    private var openCodeTerminal: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .strokeBorder(
                    isMonochrome ? Color.white.opacity(0.85) : Color(red: 0.40, green: 0.65, blue: 1.0),
                    lineWidth: size * 0.08
                )

            HStack(spacing: size * 0.06) {
                Text(">")
                    .font(.system(size: size * 0.48, weight: .bold, design: .monospaced))
                    .foregroundColor(isMonochrome ? .white : Color(red: 0.40, green: 0.65, blue: 1.0))

                Rectangle()
                    .fill(isMonochrome ? Color.white : Color(red: 0.40, green: 0.65, blue: 1.0))
                    .frame(width: size * 0.16, height: size * 0.08)
                    .offset(y: size * 0.12)
            }
        }
    }
}
