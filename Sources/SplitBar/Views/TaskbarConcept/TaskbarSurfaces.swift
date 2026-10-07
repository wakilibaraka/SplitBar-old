import AppKit
import SwiftUI

struct TaskbarFlyoutContentView: View {
    let panel: OpenPanel
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        flyoutContent
            .environment(\.surfaceStyle, model.surfaceStyle)
            .environment(\.surfaceTransparency, model.interfaceTransparency)
            .environment(\.widgetOutline, model.widgetOutline)
            .environment(\.iconBackground, model.iconBackground)
    }

    @ViewBuilder
    private var flyoutContent: some View {
        switch panel {
        case .widgets:
            WidgetsPanel(onClose: onClose, accent: model.clockTint, model: model)
        case .calendar:
            ClockFlyout(
                displayedMonth: $model.displayedMonth,
                selectedDate: $model.selectedDate,
                showsClockSettings: $model.showsClockSettings,
                uses24HourTime: $model.uses24HourTime,
                showsSeconds: $model.showsSeconds,
                dateStyle: $model.dateStyle,
                clockDisplayStyle: $model.clockDisplayStyle,
                clockTint: $model.clockTint,
                clockColorPreset: $model.clockColorPreset,
                clockGradientEnabled: $model.clockGradientEnabled,
                clockGradientStart: $model.clockGradientStart,
                clockGradientEnd: $model.clockGradientEnd,
                accent: model.clockTint,
                cornerRadius: model.shellRadius(for: .flyouts)
            )
        case .controls:
            ControlsFlyout(accent: model.clockTint, model: model)
        case .start:
            StartFlyout(
                onClose: onClose,
                accent: model.clockTint,
                model: model,
                onLaunchApplication: onLaunchApplication
            )
        case .settings:
            SettingsFlyout(
                surfaceStyle: $model.surfaceStyle,
                taskbarMode: $model.taskbarMode,
                islandGap: $model.islandGap,
                userDividers: $model.userDividers,
                trashAnchors: $model.trashAnchors,
                clusterOrder: $model.clusterOrder,
                centeredBarWidth: $model.centeredBarWidth,
                pinnedAppBundleIDs: model.pinnedAppBundleIDs,
                isDarkMode: $model.isDarkMode,
                wallpaperPreset: $model.wallpaperPreset,
                pastelTint: $model.pastelTint,
                gradientEndTint: $model.gradientEndTint,
                gradientAngle: $model.gradientAngle,
                interfaceTransparency: $model.interfaceTransparency,
                usesTaskbarGradient: $model.usesTaskbarGradient,
                taskbarGradientStart: $model.taskbarGradientStart,
                taskbarGradientEnd: $model.taskbarGradientEnd,
                taskbarHeight: $model.taskbarHeight,
                showsTaskbarPanel: $model.showsTaskbarPanel,
                hideMacDock: $model.hideMacDock,
                showWindowPreviews: $model.showWindowPreviews,
                runningIndicatorStyle: $model.runningIndicatorStyle,
                runningIndicatorSize: $model.runningIndicatorSize,
                runningIndicatorColor: $model.runningIndicatorColor,
                indicatorColorPreset: $model.indicatorColorPreset,
                indicatorGradientStart: $model.indicatorGradientStart,
                indicatorGradientEnd: $model.indicatorGradientEnd,
                minimizeMode: $model.minimizeMode,
                contextMenuStyle: $model.contextMenuStyle,
                showWifiName: $model.showWifiName,
                showBluetoothDevices: $model.showBluetoothDevices,
                ddcBrightnessEnabled: $model.ddcBrightnessEnabled,
                cornerStyle: $model.cornerStyle,
                cornerScope: $model.cornerScope,
                cornerTaskbar: $model.cornerTaskbar,
                cornerWidgets: $model.cornerWidgets,
                cornerFlyouts: $model.cornerFlyouts,
                taskbarIconSize: $model.taskbarIconSize,
                statusIconPreset: $model.statusIconPreset,
                statusIconCustomSymbol: $model.statusIconCustomSymbol,
                widgetOutlineBorder: $model.widgetOutlineBorder,
                widgetOutlineWidth: $model.widgetOutlineWidth,
                iconBackgroundVisible: $model.iconBackgroundVisible,
                iconBackgroundShape: $model.iconBackgroundShape,
                flyoutAnimation: $model.flyoutAnimation,
                flyoutHeightPreset: $model.flyoutHeightPreset,
                trashPlacement: $model.trashPlacement,
                shortcutBindings: $model.shortcutBindings,
                clipboardHistoryEnabled: $model.clipboardHistoryEnabled,
                ipGeolocationEnabled: $model.ipGeolocationEnabled,
                faviconServiceEnabled: $model.faviconServiceEnabled,
                aiAccountSwitchingEnabled: $model.aiAccountSwitchingEnabled,
                clipboardRetention: $model.clipboardRetention,
                panelWidths: $model.panelWidths,
                accent: model.clockTint,
                onClose: onClose,
                onResetPersonalisation: { model.resetPersonalisation() },
                cornerRadius: model.shellRadius(for: .flyouts)
            )
        }
    }
}


struct WindowPreviewContent: View {
    let bundleID: String
    let appTitle: String
    let windows: [AppWindowInfo]
    let surfaceStyle: SurfaceStyle
    let onSelectWindow: (AppWindowInfo) -> Void
    let onClose: () -> Void
    let cornerRadius: CGFloat
    @State private var thumbnails: [CGWindowID: NSImage] = [:]
    @State private var didAttemptCapture = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appTitle)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(windows.count) \(windows.count == 1 ? "window" : "windows")")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            ForEach(windows.prefix(6)) { window in
                previewRow(window)
            }
            if didAttemptCapture, thumbnails.isEmpty {
                Text("Grant Screen Recording for live thumbnails.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
        .task {
            await captureThumbnails()
        }
    }

    private func previewRow(_ window: AppWindowInfo) -> some View {
        Button {
            onSelectWindow(window)
        } label: {
            HStack(spacing: 10) {
                if let image = thumbnails[window.id] {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    MacOSAppIcon(
                        bundleIdentifier: bundleID,
                        fallbackSymbol: "app.fill",
                        fallbackColor: .secondary,
                        size: 34
                    )
                    .frame(width: 120, height: 72)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                Text(window.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func captureThumbnails() async {
        let service = AppWindowPreviewService()
        for window in windows.prefix(6) {
            if let image = await service.captureThumbnail(forWindowID: window.id) {
                thumbnails[window.id] = image
            }
        }
        didAttemptCapture = true
    }
}


struct TaskbarPanelContentView: View {
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void

    var body: some View {
        Taskbar(
            model: model,
            height: $model.taskbarHeight,
            onLaunchApplication: onLaunchApplication,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            rendersSplitRow: false
        )
        .environment(\.surfaceTransparency, model.interfaceTransparency)
        .environment(\.widgetOutline, model.widgetOutline)
        .environment(\.iconBackground, model.iconBackground)
        .preferredColorScheme(model.isDarkMode ? .dark : .light)
    }
}


public struct TaskbarConceptView: View {
    @ObservedObject private var model: TaskbarConceptState
    private let onLaunchApplication: (String) -> Void
    private let onTaskbarIconClick: (String) -> Void
    private let onTaskbarTileAction: (TaskbarTileAction) -> Void

    init(model: TaskbarConceptState, onLaunchApplication: @escaping (String) -> Void, onTaskbarIconClick: @escaping (String) -> Void, onTaskbarTileAction: @escaping (TaskbarTileAction) -> Void) {
        self._model = ObservedObject(wrappedValue: model)
        self.onLaunchApplication = onLaunchApplication
        self.onTaskbarIconClick = onTaskbarIconClick
        self.onTaskbarTileAction = onTaskbarTileAction
    }

    private var openPanel: OpenPanel? {
        get { model.openPanel }
        nonmutating set { model.openPanel = newValue }
    }
    private var surfaceStyle: SurfaceStyle { model.surfaceStyle }
    private var showsTaskbarPanel: Bool { model.showsTaskbarPanel }
    private var isDarkMode: Bool { model.isDarkMode }
    private var wallpaperPreset: WallpaperPreset { model.wallpaperPreset }
    private var pastelTint: Color { model.pastelTint }
    private var gradientEndTint: Color { model.gradientEndTint }
    private var gradientAngle: Double { model.gradientAngle }
    private var interfaceTransparency: Double { model.interfaceTransparency }
    private var usesTaskbarGradient: Bool { model.usesTaskbarGradient }
    private var taskbarGradientStart: Color { model.taskbarGradientStart }
    private var taskbarGradientEnd: Color { model.taskbarGradientEnd }
    private var taskbarHeight: CGFloat { model.taskbarHeight }
    private var showsClockSettings: Bool { model.showsClockSettings }
    private var uses24HourTime: Bool { model.uses24HourTime }
    private var showsSeconds: Bool { model.showsSeconds }
    private var dateStyle: ClockDateStyle { model.dateStyle }
    private var clockTint: Color { model.clockTint }
    private var displayedMonth: Date { model.displayedMonth }
    private var selectedDate: Date { model.selectedDate }

    private func panelFrameWidth(_ kind: PanelKind, available: CGFloat) -> CGFloat {
        min(model.panelWidth(for: kind), available)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                DesktopBackdrop(
                    isDarkMode: isDarkMode,
                    preset: wallpaperPreset,
                    pastelTint: pastelTint,
                    gradientEndTint: gradientEndTint,
                    gradientAngle: gradientAngle,
                    surfaceStyle: surfaceStyle,
                    weather: model.weather
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.roseAccent)
                        Text("TASKBAR CONCEPT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(.top, 30)
                    .padding(.leading, 34)

                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("A calmer kind of desktop.")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .tracking(-1.8)
                        Text("A Windows-inspired taskbar, thoughtfully reimagined for macOS.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 72)
                    .padding(.bottom, 180)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if openPanel == .widgets, !showsTaskbarPanel {
                    WidgetsPanel(onClose: { openPanel = nil }, accent: clockTint, model: model)
                        .frame(
                            width: panelFrameWidth(.widgets, available: geometry.size.width - 36),
                            height: model.flyoutHeight(available: geometry.size.height - taskbarHeight - 28)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 14)
                        .padding(.top, 14)
                        .transition(MotionTokens.flyoutTransition(model.flyoutAnimation, reduceMotion: model.reduceMotion))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .calendar, !showsTaskbarPanel {
                    ClockFlyout(
                        displayedMonth: $model.displayedMonth,
                        selectedDate: $model.selectedDate,
                        showsClockSettings: $model.showsClockSettings,
                        uses24HourTime: $model.uses24HourTime,
                        showsSeconds: $model.showsSeconds,
                        dateStyle: $model.dateStyle,
                        clockDisplayStyle: $model.clockDisplayStyle,
                        clockTint: $model.clockTint,
                        clockColorPreset: $model.clockColorPreset,
                        clockGradientEnabled: $model.clockGradientEnabled,
                        clockGradientStart: $model.clockGradientStart,
                        clockGradientEnd: $model.clockGradientEnd,
                        accent: clockTint,
                        cornerRadius: model.shellRadius(for: .flyouts)
                    )
                    .frame(width: min(520, geometry.size.width - 36), height: model.flyoutHeight(available: geometry.size.height - taskbarHeight - 28))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 14)
                    .padding(.top, 14)
                    .transition(MotionTokens.flyoutTransition(model.flyoutAnimation, reduceMotion: model.reduceMotion))
                    .environment(\.surfaceStyle, surfaceStyle)
                    .zIndex(2)
                }

                if openPanel == .controls, !showsTaskbarPanel {
                    ControlsFlyout(accent: clockTint, model: model)
                        .frame(width: panelFrameWidth(.controls, available: geometry.size.width - 36), height: model.flyoutHeight(available: geometry.size.height - taskbarHeight - 28))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 14)
                        .padding(.top, 14)
                        .transition(MotionTokens.flyoutTransition(model.flyoutAnimation, reduceMotion: model.reduceMotion))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .start, !showsTaskbarPanel {
                    StartFlyout(
                        onClose: { openPanel = nil },
                        accent: clockTint,
                        model: model,
                        onLaunchApplication: onLaunchApplication
                    )
                        .frame(width: panelFrameWidth(.start, available: geometry.size.width - 48), height: model.flyoutHeight(available: geometry.size.height - taskbarHeight - 36))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, taskbarHeight + 12)
                        .transition(MotionTokens.flyoutTransition(model.flyoutAnimation, reduceMotion: model.reduceMotion))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .settings, !showsTaskbarPanel {
                    SettingsFlyout(
                        surfaceStyle: $model.surfaceStyle,
                        taskbarMode: $model.taskbarMode,
                        islandGap: $model.islandGap,
                        userDividers: $model.userDividers,
                        trashAnchors: $model.trashAnchors,
                        clusterOrder: $model.clusterOrder,
                        centeredBarWidth: $model.centeredBarWidth,
                        pinnedAppBundleIDs: model.pinnedAppBundleIDs,
                        isDarkMode: $model.isDarkMode,
                        wallpaperPreset: $model.wallpaperPreset,
                        pastelTint: $model.pastelTint,
                        gradientEndTint: $model.gradientEndTint,
                        gradientAngle: $model.gradientAngle,
                        interfaceTransparency: $model.interfaceTransparency,
                        usesTaskbarGradient: $model.usesTaskbarGradient,
                        taskbarGradientStart: $model.taskbarGradientStart,
                        taskbarGradientEnd: $model.taskbarGradientEnd,
                        taskbarHeight: $model.taskbarHeight,
                        showsTaskbarPanel: $model.showsTaskbarPanel,
                        hideMacDock: $model.hideMacDock,
                        showWindowPreviews: $model.showWindowPreviews,
                        runningIndicatorStyle: $model.runningIndicatorStyle,
                        runningIndicatorSize: $model.runningIndicatorSize,
                        runningIndicatorColor: $model.runningIndicatorColor,
                        indicatorColorPreset: $model.indicatorColorPreset,
                        indicatorGradientStart: $model.indicatorGradientStart,
                        indicatorGradientEnd: $model.indicatorGradientEnd,
                        minimizeMode: $model.minimizeMode,
                        contextMenuStyle: $model.contextMenuStyle,
                        showWifiName: $model.showWifiName,
                        showBluetoothDevices: $model.showBluetoothDevices,
                        ddcBrightnessEnabled: $model.ddcBrightnessEnabled,
                        cornerStyle: $model.cornerStyle,
                        cornerScope: $model.cornerScope,
                        cornerTaskbar: $model.cornerTaskbar,
                        cornerWidgets: $model.cornerWidgets,
                        cornerFlyouts: $model.cornerFlyouts,
                        taskbarIconSize: $model.taskbarIconSize,
                        statusIconPreset: $model.statusIconPreset,
                        statusIconCustomSymbol: $model.statusIconCustomSymbol,
                        widgetOutlineBorder: $model.widgetOutlineBorder,
                        widgetOutlineWidth: $model.widgetOutlineWidth,
                        iconBackgroundVisible: $model.iconBackgroundVisible,
                        iconBackgroundShape: $model.iconBackgroundShape,
                        flyoutAnimation: $model.flyoutAnimation,
                        flyoutHeightPreset: $model.flyoutHeightPreset,
                        trashPlacement: $model.trashPlacement,
                        shortcutBindings: $model.shortcutBindings,
                        clipboardHistoryEnabled: $model.clipboardHistoryEnabled,
                        ipGeolocationEnabled: $model.ipGeolocationEnabled,
                        faviconServiceEnabled: $model.faviconServiceEnabled,
                        aiAccountSwitchingEnabled: $model.aiAccountSwitchingEnabled,
                        clipboardRetention: $model.clipboardRetention,
                        panelWidths: $model.panelWidths,
                        accent: clockTint,
                        onClose: { openPanel = nil },
                        onResetPersonalisation: { model.resetPersonalisation() },
                        cornerRadius: model.shellRadius(for: .flyouts)
                    )
                    .frame(width: panelFrameWidth(.settings, available: geometry.size.width - 40), height: max(560, model.flyoutHeight(available: geometry.size.height - taskbarHeight - 40)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, taskbarHeight)
                    .transition(MotionTokens.flyoutTransition(model.flyoutAnimation, reduceMotion: model.reduceMotion))
                    .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if showsTaskbarPanel {
                    Text("The live bar is running on your screen")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 18)
                        .zIndex(3)
                } else {
                    Taskbar(
                        model: model,
                        height: $model.taskbarHeight,
                        onLaunchApplication: onLaunchApplication,
                        onTaskbarIconClick: onTaskbarIconClick,
                        onTaskbarTileAction: onTaskbarTileAction
                    )
                    .zIndex(3)
                }

                if model.showsOnboarding {
                    OnboardingView(model: model, accent: model.clockTint, isDarkMode: model.isDarkMode) {
                        model.completeOnboarding()
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(MotionTokens.spring(response: 0.38, dampingFraction: 0.86, reduceMotion: model.reduceMotion), value: openPanel)
            .animation(MotionTokens.spring(response: 0.35, reduceMotion: model.reduceMotion), value: model.flyoutHeightPreset)
            .environment(\.surfaceTransparency, interfaceTransparency)
            .environment(\.widgetOutline, model.widgetOutline)
            .environment(\.iconBackground, model.iconBackground)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}


struct DesktopBackdrop: View {
    let isDarkMode: Bool
    let preset: WallpaperPreset
    let pastelTint: Color
    let gradientEndTint: Color
    let gradientAngle: Double
    let surfaceStyle: SurfaceStyle
    let weather: WeatherState

    private var weatherKind: WeatherBackdropKind {
        weatherBackdropKind(for: weather)
    }

    private var gradientStart: UnitPoint {
        UnitPoint(x: 0.5 - cos(gradientAngle * .pi / 180) / 2, y: 0.5 - sin(gradientAngle * .pi / 180) / 2)
    }

    private var gradientEnd: UnitPoint {
        UnitPoint(x: 0.5 + cos(gradientAngle * .pi / 180) / 2, y: 0.5 + sin(gradientAngle * .pi / 180) / 2)
    }

    private var wallpaperColors: [Color] {
        if preset == .custom {
            return [pastelTint, gradientEndTint]
        }
        if preset == .weatherReactive {
            return weatherBackdropPalette(for: weatherKind)
        }
        if preset == .themeMatched {
            return surfaceStyle.accentGradient(darkMode: isDarkMode)
        }
        if isDarkMode && !preset.isDark {
            return [
                Color(red: 0.035, green: 0.055, blue: 0.10),
                Color(red: 0.10, green: 0.075, blue: 0.14),
                Color(red: 0.045, green: 0.10, blue: 0.16)
            ]
        }
        return preset.colors
    }

    private var particleIntensity: Double {
        switch weatherKind {
        case .storm, .rain, .snow: 1.0
        case .cloudy, .fog: 0.7
        case .clearNight, .clearDay: 0.6
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: wallpaperColors,
                startPoint: gradientStart,
                endPoint: gradientEnd
            )

            Circle()
                .fill((preset == .custom ? pastelTint : wallpaperColors.first ?? pastelTint).opacity(0.47))
                .frame(width: 520, height: 520)
                .blur(radius: 85)
                .offset(x: 380, y: -170)

            Circle()
                .fill((preset == .custom ? gradientEndTint : wallpaperColors.last ?? gradientEndTint).opacity(0.31))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .offset(x: -430, y: 140)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.13), Color.white.opacity(0.015)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 860, height: 410)
                .rotationEffect(.degrees(-26))
                .offset(x: 220, y: 130)

            Ellipse()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 960, height: 480)
                .rotationEffect(.degrees(-26))
                .offset(x: 210, y: 135)

            if preset == .weatherReactive {
                WeatherParticles(kind: weatherKind, intensity: particleIntensity)
            }
        }
        .ignoresSafeArea()
    }
}
