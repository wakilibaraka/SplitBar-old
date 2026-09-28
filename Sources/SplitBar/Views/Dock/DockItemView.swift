import AppKit
import Foundation
import SwiftUI

private struct TooltipPointerShape: Shape {
    let edge: DockEdge

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch edge {
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .top:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

public struct DockItemView: View {
    public let item: DockItemViewState
    public let edge: DockEdge
    public let animationPolicy: DockAnimationPolicy
    public let iconBaseSize: CGFloat
    /// Sürükle-bırak sonrası gelen sahte tıklamaları ayırt eder.
    public let isTapSuppressed: () -> Bool
    public let onSelect: () -> Void
    public let onActivate: () -> Void
    public let onRemove: () -> Void
    public let onChangeEdge: (DockEdge) -> Void
    public let onShowWindows: () -> Void

    @State private var bounceOffset: CGSize = .zero
    @State private var isDisappearing: Bool = false
    @State private var bounceTask: Task<Void, Never>?

    /// Zıplama, native Dock'taki gibi ekranın içine doğrudur: sağ kenarda sola, sol kenarda sağa, üstte aşağı.
    private func bounceDisplacement(amplitude: CGFloat) -> CGSize {
        switch edge {
        case .right:
            return CGSize(width: -amplitude, height: 0.0)
        case .left:
            return CGSize(width: amplitude, height: 0.0)
        case .top:
            return CGSize(width: 0.0, height: amplitude)
        }
    }

    private func runningInstances(bundleIdentifier: String) -> [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
    }

    /// Tek bir yukarı-aşağı zıplama; iptal edilirse `false` döner.
    private func bounceOnce(amplitude: CGFloat) async -> Bool {
        withAnimation(.easeOut(duration: 0.24)) {
            bounceOffset = bounceDisplacement(amplitude: amplitude)
        }
        do {
            try await Task.sleep(for: .milliseconds(240))
        } catch {
            bounceOffset = .zero
            return false
        }
        withAnimation(.easeIn(duration: 0.22)) {
            bounceOffset = .zero
        }
        do {
            try await Task.sleep(for: .milliseconds(260))
        } catch {
            return false
        }
        return true
    }

    /// Native Dock davranışı: çalışmayan bir uygulama açılırken yüklenmesi bitene kadar zıplar;
    /// zaten çalışan uygulamalar zıplamaz. macOS'ta olduğu gibi açılış zıplaması "Reduce Motion"dan
    /// bağımsızdır; widget ve bağlantıların kısa geri bildirim zıplaması ise bu ayara uyar.
    private func startActivationBounce() {
        bounceTask?.cancel()

        switch item.kind {
        case .application(let bundleIdentifier, _):
            guard runningInstances(bundleIdentifier: bundleIdentifier).isEmpty else { return }
            let amplitude = iconBaseSize * 0.5
            bounceTask = Task { @MainActor in
                let deadline = Date().addingTimeInterval(10.0)
                repeat {
                    guard await bounceOnce(amplitude: amplitude) else { return }
                } while Date() < deadline
                    && !runningInstances(bundleIdentifier: bundleIdentifier).contains(where: \.isFinishedLaunching)
            }
        case .link, .widget:
            if case .reducedMotion = animationPolicy { return }
            let amplitude = iconBaseSize * 0.22
            bounceTask = Task { @MainActor in
                _ = await bounceOnce(amplitude: amplitude)
            }
        }
    }

    public init(
        item: DockItemViewState,
        edge: DockEdge,
        animationPolicy: DockAnimationPolicy,
        iconBaseSize: CGFloat,
        isTapSuppressed: @escaping () -> Bool,
        onSelect: @escaping () -> Void,
        onActivate: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        onChangeEdge: @escaping (DockEdge) -> Void,
        onShowWindows: @escaping () -> Void
    ) {
        self.item = item
        self.edge = edge
        self.animationPolicy = animationPolicy
        self.iconBaseSize = iconBaseSize
        self.isTapSuppressed = isTapSuppressed
        self.onSelect = onSelect
        self.onActivate = onActivate
        self.onRemove = onRemove
        self.onChangeEdge = onChangeEdge
        self.onShowWindows = onShowWindows
    }

    private func resolveAppIcon(bundleIdentifier: String, applicationURL: URL) -> NSImage {
        let cacheKey = bundleIdentifier.isEmpty ? applicationURL.path : bundleIdentifier
        return IconCache.shared.image(key: cacheKey) {
            // 1. Try running instance icon from NSRunningApplication
            if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first,
               let runningIcon = running.icon {
                return runningIcon
            }

            // 2. Try URL for bundle identifier via NSWorkspace
            if let resolvedURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return NSWorkspace.shared.icon(forFile: resolvedURL.path)
            }

            // 3. Try direct application URL path if file exists
            if FileManager.default.fileExists(atPath: applicationURL.path) {
                return NSWorkspace.shared.icon(forFile: applicationURL.path)
            }

            // 4. Try scanning common system application directories
            let appName = applicationURL.lastPathComponent
            let commonPaths = [
                "/Applications/\(appName)",
                "/System/Applications/\(appName)",
                "/System/Applications/Utilities/\(appName)",
                "/System/Library/CoreServices/\(appName)"
            ]
            for path in commonPaths {
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            }

            // 5. Fallback to Finder icon to prevent blank document sheets
            return NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        }
    }

    private var iconContent: some View {
        let displaySize = max(24.0, iconBaseSize - 4.0)

        return Group {
            switch item.kind {
            case .application(let bundleID, let appURL):
                let icon = resolveAppIcon(bundleIdentifier: bundleID, applicationURL: appURL)
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: displaySize, height: displaySize)
                        .shadow(color: Color.black.opacity(0.35), radius: 3.5, x: 0.0, y: 2.0)

                    if item.isRunning {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 5.0, height: 5.0)
                            .shadow(color: Color.black.opacity(0.60), radius: 1.5, x: 0.0, y: 1.0)
                            .offset(x: -1.0, y: 1.0)
                    }
                }

            case .link(let url):
                WebFaviconView(url: url, size: displaySize)

            case .widget(let widgetIdentifier):
                ZStack(alignment: .bottomTrailing) {
                    WidgetIconView(identifier: widgetIdentifier, size: displaySize)

                    if item.isRunning {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 5.0, height: 5.0)
                            .shadow(color: Color.black.opacity(0.60), radius: 1.5, x: 0.0, y: 1.0)
                            .offset(x: -1.0, y: 1.0)
                    }
                }
            }
        }
    }

    private var tooltipText: String {
        if let badge = item.badgeText, !badge.isEmpty, badge != "AI", badge != "BT", badge != "Clip", badge != "Note", badge != "Music", badge != "PLAY", badge != "—°" {
            return "\(item.name) (\(badge))"
        }
        return item.name
    }

    public var body: some View {
        let containerDimension = iconBaseSize + 4.0
        let ringDimension = (iconBaseSize - 2.0) * item.transform.scale

        HStack(spacing: 0) {
            Button(action: {
                guard !isTapSuppressed() else { return }
                startActivationBounce()
                onSelect()
                onActivate()
            }) {
                ZStack {
                    // Selected active ring indicator
                    if item.isSelected {
                        RoundedRectangle(cornerRadius: 13.0, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.90), location: 0.0),
                                        .init(color: Color.white.opacity(0.35), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: ringDimension, height: ringDimension)
                            .animation(animationPolicy.animation, value: item.transform.scale)
                    }

                    // Native Icon Content (Razor Sharp, No Blurry Glow Artifact)
                    iconContent
                        .scaleEffect(item.transform.scale)
                        .offset(bounceOffset)
                        .animation(animationPolicy.animation, value: item.transform.scale)
                }
                .frame(width: containerDimension, height: containerDimension)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(tooltipText)
            .pointingHandCursor()
            .contextMenu {
                switch item.kind {
                case .application(let bundleIdentifier, let appURL):
                    Button {
                        NSWorkspace.shared.openApplication(
                            at: appURL,
                            configuration: NSWorkspace.OpenConfiguration()
                        )
                    } label: {
                        Label(item.isRunning ? "Show" : "Open", systemImage: "arrow.up.forward.app")
                    }

                    Button {
                        onShowWindows()
                    } label: {
                        Label("Show Windows", systemImage: "macwindow.on.rectangle")
                    }

                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([appURL])
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    if item.isRunning {
                        Divider()

                        Button {
                            runningInstances(bundleIdentifier: bundleIdentifier).forEach { $0.hide() }
                        } label: {
                            Label("Hide", systemImage: "eye.slash")
                        }

                        // Uygulama kaydedilmemiş belge için onay isteyebilir; bu durumda terminate() false döner
                        Button {
                            runningInstances(bundleIdentifier: bundleIdentifier).forEach { $0.terminate() }
                        } label: {
                            Label("Quit", systemImage: "xmark.circle")
                        }

                        Button(role: .destructive) {
                            runningInstances(bundleIdentifier: bundleIdentifier).forEach { $0.forceTerminate() }
                        } label: {
                            Label("Force Quit", systemImage: "exclamationmark.octagon")
                        }
                    }

                case .link(let url):
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("Open Link", systemImage: "safari")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url.absoluteString, forType: .string)
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }

                case .widget:
                    Button {
                        onActivate()
                    } label: {
                        Label("Open Widget", systemImage: "rectangle.portrait.badge.plus")
                    }
                }

                Divider()

                Menu("Dock Edge") {
                    Button("Left") { onChangeEdge(.left) }
                    Button("Right") { onChangeEdge(.right) }
                    Button("Top") { onChangeEdge(.top) }
                }

                Divider()

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from Dock", systemImage: "trash")
                }
            }
        }
    }
}
