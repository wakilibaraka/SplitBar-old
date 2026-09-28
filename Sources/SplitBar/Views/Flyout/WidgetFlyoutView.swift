import SwiftUI

public struct WidgetFlyoutView<Content: View>: View {
    public let title: String
    public let onClose: () -> Void
    public let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @State private var isCloseHovered: Bool = false

    public init(
        title: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            // Modern Liquid Glass Header Bar
            HStack(spacing: 8.0) {
                // Subtle status accent dot
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 7.0, height: 7.0)
                    .shadow(color: Color.accentColor.opacity(0.6), radius: 3.0)

                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                // Frosted Glass Close Button
                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isCloseHovered ? 0.20 : 0.08))
                            .frame(width: 22.0, height: 22.0)

                        Image(systemName: "xmark")
                            .accessibilityLabel("Close")
                            .font(.system(size: 9.0, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isCloseHovered = hovering
                    }
                }
                .help("Close Card (Esc)")
            }
            .padding(.bottom, 2.0)

            content
        }
        .padding(16.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassSurface(
            cornerRadius: 22.0,
            tintColor: nil,
            isHovered: false
        )
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }
}
