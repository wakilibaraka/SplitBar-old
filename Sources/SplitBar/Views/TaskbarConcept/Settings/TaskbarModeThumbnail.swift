import SwiftUI

import SwiftUI

struct TaskbarModeThumbnail: View {
    let mode: TaskbarMode
    let isSelected: Bool

    private let width: CGFloat = 66
    private let height: CGFloat = 26
    private let referenceWidth: CGFloat = 120

    private var scale: CGFloat { (width - 6) / referenceWidth }

    private var previewIslands: [CGRect] {
        let layout = TaskbarStripMetrics.layout(
            screenWidth: referenceWidth,
            mode: mode,
            barHeight: 16,
            gap: 5,
            appCount: 4
        )
        guard !layout.islands.isEmpty else {
            let inset: CGFloat = mode == .macOS ? 26 : mode == .centered ? 18 : 0
            return [CGRect(x: inset, y: 0, width: referenceWidth - inset * 2, height: 16)]
        }
        return layout.islands.map(\.frame)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.roseAccent.opacity(0.18) : Color.primary.opacity(0.06))
            ForEach(Array(previewIslands.enumerated()), id: \.offset) { _, frame in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(isSelected ? Color.roseAccent : Color.primary.opacity(0.34))
                    .frame(width: max(4, frame.width * scale), height: max(4, frame.height * scale))
                    .offset(x: 3 + frame.minX * scale, y: 4 + frame.minY * scale)
            }
        }
        .frame(width: width, height: height)
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(isSelected ? Color.roseAccent : Color.primary.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
        }
    }
}
