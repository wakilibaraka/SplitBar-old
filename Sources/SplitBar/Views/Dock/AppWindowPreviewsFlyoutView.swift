import AppKit
import CoreGraphics
import Foundation
import SwiftUI

public struct AppWindowPreviewsFlyoutView: View {
    public let appName: String
    public let bundleIdentifier: String
    public let appIconURL: URL?
    public let windows: [AppWindowInfo]
    public let previewService: AppWindowPreviewService
    public let onSelectWindow: (AppWindowInfo) -> Void
    public let onClose: () -> Void

    public init(
        appName: String,
        bundleIdentifier: String,
        appIconURL: URL?,
        windows: [AppWindowInfo],
        previewService: AppWindowPreviewService,
        onSelectWindow: @escaping (AppWindowInfo) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.appIconURL = appIconURL
        self.windows = windows
        self.previewService = previewService
        self.onSelectWindow = onSelectWindow
        self.onClose = onClose
    }

    @State private var hoveredWindowID: CGWindowID?

    public var body: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            // Header
            HStack(spacing: 10.0) {
                if let url = appIconURL {
                    let icon = IconCache.shared.image(key: "app-path:\(url.path)") {
                        NSWorkspace.shared.icon(forFile: url.path)
                    }
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24.0, height: 24.0)
                        .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
                } else {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 16.0, weight: .bold))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 1.0) {
                    Text(appName)
                        .font(.system(size: 14.0, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(windows.count) \(windows.count == 1 ? "Active Window" : "Active Windows")")
                        .font(.system(size: 11.0, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16.0))
                        .foregroundColor(.secondary.opacity(0.70))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.horizontal, 4.0)

            Divider()
                .overlay(Color.white.opacity(0.20))

            // Window Cards Grid / List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10.0) {
                    ForEach(windows) { window in
                        AppWindowCardView(
                            window: window,
                            previewService: previewService,
                            isHovered: hoveredWindowID == window.id,
                            onSelectWindow: onSelectWindow
                        )
                        .onHover { isHover in
                            hoveredWindowID = isHover ? window.id : nil
                        }
                    }
                }
                .padding(.vertical, 2.0)
            }
            .frame(maxHeight: 340.0)
        }
        .padding(16.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassSurface(
            cornerRadius: 22.0,
            tintColor: nil,
            isHovered: false
        )
    }
}

public struct AppWindowCardView: View {
    public let window: AppWindowInfo
    public let previewService: AppWindowPreviewService
    public let isHovered: Bool
    public let onSelectWindow: (AppWindowInfo) -> Void

    public init(
        window: AppWindowInfo,
        previewService: AppWindowPreviewService,
        isHovered: Bool,
        onSelectWindow: @escaping (AppWindowInfo) -> Void
    ) {
        self.window = window
        self.previewService = previewService
        self.isHovered = isHovered
        self.onSelectWindow = onSelectWindow
    }

    @State private var liveThumbnail: NSImage?

    public var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            onSelectWindow(window)
        }) {
            VStack(alignment: .leading, spacing: 8.0) {
                // Miniature Window Preview Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.16 : 0.08),
                                    Color.black.opacity(0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if let liveThumbnail = liveThumbnail {
                        Image(nsImage: liveThumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 78.0)
                            .clipped()
                            .cornerRadius(12.0)
                    } else {
                        VStack(spacing: 6.0) {
                            Image(systemName: "macwindow")
                                .font(.system(size: 26.0, weight: .light))
                                .foregroundColor(isHovered ? .accentColor : .white.opacity(0.60))

                            Text(window.title)
                                .font(.system(size: 11.0, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 12.0)
                        }
                    }
                }
                .frame(height: 78.0)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                        .strokeBorder(
                            isHovered ? Color.accentColor : Color.white.opacity(0.20),
                            lineWidth: isHovered ? 1.6 : 0.8
                        )
                )

                // Window Title & Bounds Info
                HStack {
                    Text(window.title)
                        .font(.system(size: 12.0, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(Int(window.bounds.width))×\(Int(window.bounds.height))")
                        .font(.system(size: 10.0, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 2.0)
            }
            .padding(8.0)
            .background(
                RoundedRectangle(cornerRadius: 14.0, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .contentShape(RoundedRectangle(cornerRadius: 14.0, style: .continuous))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .task {
            if liveThumbnail == nil {
                liveThumbnail = await previewService.captureThumbnail(forWindowID: window.id)
            }
        }
    }
}
