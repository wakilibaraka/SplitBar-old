import AppKit
import SwiftUI

struct SettingsFlyout: View {
    // MARK: - Bindings (all preserved)
    @Binding var surfaceStyle: SurfaceStyle
    @Binding var taskbarMode: TaskbarMode
    @Binding var islandGap: CGFloat
    @Binding var userDividers: [TaskbarDivider]
    @Binding var trashAnchors: [String: String]
    @Binding var clusterOrder: [String]
    @Binding var centeredBarWidth: CGFloat
    let pinnedAppBundleIDs: [String]
    @Binding var isDarkMode: Bool
    @Binding var wallpaperPreset: WallpaperPreset
    @Binding var pastelTint: Color
    @Binding var gradientEndTint: Color
    @Binding var gradientAngle: Double
    @Binding var interfaceTransparency: Double
    @Binding var usesTaskbarGradient: Bool
    @Binding var taskbarGradientStart: Color
    @Binding var taskbarGradientEnd: Color
    @Binding var taskbarHeight: CGFloat
    @Binding var showsTaskbarPanel: Bool
    @Binding var hideMacDock: Bool
    @Binding var showWindowPreviews: Bool
    @Binding var runningIndicatorStyle: RunningIndicatorStyle
    @Binding var runningIndicatorSize: RunningIndicatorSize
    @Binding var runningIndicatorColor: Color
    @Binding var indicatorColorPreset: IndicatorColorPreset
    @Binding var indicatorGradientStart: Color
    @Binding var indicatorGradientEnd: Color
    @Binding var minimizeMode: AppMinimizeMode
    @Binding var contextMenuStyle: ContextMenuStyle
    @Binding var showWifiName: Bool
    @Binding var showBluetoothDevices: Bool
    @Binding var ddcBrightnessEnabled: Bool
    @Binding var cornerStyle: CornerStyle
    @Binding var cornerScope: CornerScope
    @Binding var cornerTaskbar: CornerStyle
    @Binding var cornerWidgets: CornerStyle
    @Binding var cornerFlyouts: CornerStyle
    @Binding var taskbarIconSize: TaskbarIconSize
    @Binding var statusIconPreset: StatusIconPreset
    @Binding var statusIconCustomSymbol: String
    @Binding var widgetOutlineBorder: Bool
    @Binding var widgetOutlineWidth: CGFloat
    @Binding var iconBackgroundVisible: Bool
    @Binding var iconBackgroundShape: IconShape
    @Binding var flyoutAnimation: FlyoutAnimation
    @Binding var flyoutHeightPreset: FlyoutHeightPreset
    @Binding var trashPlacement: TrashPlacement
    @Binding var shortcutBindings: [ShortcutBinding]
    @Binding var clipboardHistoryEnabled: Bool
    @Binding var ipGeolocationEnabled: Bool
    @Binding var faviconServiceEnabled: Bool
    @Binding var aiAccountSwitchingEnabled: Bool
    @Binding var clipboardRetention: ClipboardRetentionPolicy
    @Binding var panelWidths: [PanelKind: CGFloat]
    @Binding var preferences: AppPreferences
    @Binding var isLaunchAtLoginEnabled: Bool
    @Binding var isLegacyEdgeDockEnabled: Bool
    let accent: Color
    let onClose: () -> Void
    let onResetPersonalisation: () -> Void
    let cornerRadius: CGFloat

    // MARK: - State
    @State var isConfirmingReset = false
    @State var selectedTab = SFTab.taskbar
    @State var recordingBindingID: UUID?
    @State var recordingMonitor: Any?
    @State var conflictMessage: String?

    // MARK: - Environment
    @Environment(\.surfaceStyle) private var currentStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    // MARK: - Tab definition
    enum SFTab: String, CaseIterable {
        case system   = "System"
        case taskbar  = "Taskbar"
        case themes   = "Themes"
        case widgets  = "Widgets"
        case flyouts  = "Flyouts"
        case shortcuts = "Shortcuts"
        case advanced = "Advanced"
        case privacy  = "Privacy"

        var icon: String {
            switch self {
            case .system:   "gearshape.fill"
            case .taskbar:  "square.3.layers.3d.bottom.filled"
            case .themes:   "paintbrush.fill"
            case .widgets:  "square.grid.2x2.fill"
            case .flyouts:  "sidebar.right"
            case .shortcuts: "command"
            case .advanced: "slider.horizontal.3"
            case .privacy:  "hand.raised.fill"
            }
        }
    }

    // MARK: - Helpers
    var sectionFill: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045)
    }

    func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            content()
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .widgetCard(style: currentStyle, darkMode: colorScheme == .dark, transparency: transparency, showsBorder: false)
    }

    func sliderValueLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(minWidth: 44, alignment: .trailing)
    }

    var effectiveTrashPlacement: TrashPlacement {
        trashAnchors[taskbarMode.rawValue].flatMap(TrashPlacement.init(rawValue:)) ?? trashPlacement
    }

    func panelWidthBinding(for kind: PanelKind) -> Binding<Double> {
        Binding(
            get: { Double(panelWidths[kind] ?? kind.defaultWidth) },
            set: { panelWidths[kind] = min(kind.maximumWidth, max(kind.minimumWidth, CGFloat($0))) }
        )
    }

    func clusterItemTitle(_ key: String) -> String {
        switch key {
        case "downloads": "Downloads"
        case "trash": "Trash"
        default: "System status"
        }
    }

    func moveClusterItem(_ key: String, offset: Int) {
        guard let index = clusterOrder.firstIndex(of: key) else { return }
        let target = index + offset
        guard clusterOrder.indices.contains(target) else { return }
        clusterOrder.swapAt(index, target)
    }

    func addDivider(after bundleID: String) {
        guard taskbarMode != .macOS, !hasDividerAfter(bundleID) else { return }
        userDividers.append(TaskbarDivider(anchorBundleID: bundleID))
    }

    func moveDivider(_ id: UUID, after bundleID: String) {
        guard taskbarMode != .macOS,
              let index = userDividers.firstIndex(where: { $0.id == id })
        else { return }
        userDividers[index].anchorBundleID = bundleID
    }

    func removeDivider(_ id: UUID) {
        userDividers.removeAll { $0.id == id }
    }

    func hasDividerAfter(_ bundleIdentifier: String) -> Bool {
        userDividers.contains { $0.anchorBundleID == bundleIdentifier }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            tabBar
            Divider().opacity(0.35)
            tabContent
        }
        .flyoutSurface(style: currentStyle, darkMode: colorScheme == .dark, transparency: transparency, cornerRadius: cornerRadius)
    }

    // MARK: - Header bar
    var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personalisation")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("Make this taskbar feel like yours")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isConfirmingReset = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(sectionFill, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Reset to defaults")
            .confirmationDialog(
                "Reset Personalisation?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) { onResetPersonalisation() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Widths, icons, trash position, wallpaper and taskbar appearance return to defaults. Pins and widgets are untouched.")
            }
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(sectionFill, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Tab bar
    var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(SFTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? accent : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        selectedTab == tab ? accent.opacity(0.10) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 9)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Tab content router
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .system:   systemTab
        case .taskbar:  taskbarTab
        case .themes:   themesTab
        case .widgets:  widgetsTab
        case .flyouts:  flyoutsTab
        case .shortcuts: shortcutsTab
        case .advanced: advancedTab
        case .privacy:  privacyTab
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
}
