import AppKit
import Combine
import SwiftUI

struct QuickSetting: Identifiable {
    let title: String
    let symbol: String

    var id: String { title }
}


struct ControlsFlyout: View {
    private var shellRadius: CGFloat { model.shellRadius(for: .flyouts) }
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @State private var isEditingQuickSettings = false

    private let quickSettings: [QuickSetting] = [
        QuickSetting(title: "Bluetooth", symbol: "bluetooth"),
        QuickSetting(title: "Dark Mode", symbol: "moon.fill"),
        QuickSetting(title: "Dock Autohide", symbol: "rectangle.bottomthird.inset.filled"),
        QuickSetting(title: "Dock Recents", symbol: "clock.fill"),
        QuickSetting(title: "Eject Discs", symbol: "eject.fill"),
        QuickSetting(title: "Empty Trash", symbol: "trash.fill"),
        QuickSetting(title: "Finder Path Bar", symbol: "sidebar.left"),
        QuickSetting(title: "Hidden Files", symbol: "eye.fill"),
        QuickSetting(title: "Hide Desktop", symbol: "rectangle.dashed"),
        QuickSetting(title: "Keep Awake", symbol: "cup.and.saucer.fill"),
        QuickSetting(title: "Keyboard Lock", symbol: "keyboard"),
        QuickSetting(title: "Menubar Hide", symbol: "rectangle.topthird.inset.filled"),
        QuickSetting(title: "Mute", symbol: "speaker.slash.fill"),
        QuickSetting(title: "Mute Mic", symbol: "mic.slash.fill"),
        QuickSetting(title: "Pomodoro", symbol: "timer"),
        QuickSetting(title: "Restart Finder", symbol: "rectangle.dashed"),
        QuickSetting(title: "Screen Saver", symbol: "display"),
        QuickSetting(title: "Show Extension", symbol: "doc.text"),
        QuickSetting(title: "Show Library", symbol: "books.vertical.fill"),
        QuickSetting(title: "Small Launchpad", symbol: "square.grid.3x3.fill"),
        QuickSetting(title: "Speed Test", symbol: "globe"),
        QuickSetting(title: "True Tone", symbol: "sun.max.fill"),
        QuickSetting(title: "VPN", symbol: "lock.shield.fill"),
        QuickSetting(title: "Xcode Cache", symbol: "hammer.fill")
    ]

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
    }

    private var visibleQuickSettings: Set<String> {
        Set(quickSettings.map(\.title)).subtracting(model.hiddenQuickSettingTitles)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quick Settings")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("Your devices and controls")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isEditingQuickSettings.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(accent)
                        .frame(width: 34, height: 34)
                        .background(accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Choose which quick settings are shown")
                .popover(isPresented: $isEditingQuickSettings, arrowEdge: .trailing) {
                    quickSettingsEditor
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        BatteryWidget(
                            level: model.systemStatus.batteryLevel,
                            isCharging: model.systemStatus.isCharging,
                            isPluggedIn: model.systemStatus.isPluggedIn
                        )
                        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .topLeading)
                        statusReadoutTile(
                            title: "Wi-Fi",
                            detail: wifiDetailText,
                            symbol: model.systemStatus.wifiOn ? "wifi" : "wifi.slash",
                            isOn: model.systemStatus.wifiOn
                        )
                        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112)
                    }

                    BluetoothWidget(
                        powerOn: model.systemStatus.bluetoothOn,
                        monitoringEnabled: model.showBluetoothDevices,
                        devices: model.systemStatus.bluetoothDevices,
                        onToggleDevice: { connected, address in
                            model.setBluetoothDeviceConnected(connected, address: address)
                        }
                    )

                    LazyVGrid(columns: gridColumns, spacing: 6) {
                        ForEach(quickSettings.filter { visibleQuickSettings.contains($0.title) }) { setting in
                            quickSettingTile(setting)
                        }
                    }
                    if quickSettings.filter({ visibleQuickSettings.contains($0.title) }).isEmpty {
                        Text("No quick settings selected")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            WidgetCard(title: "Volume mixer", symbol: "speaker.wave.2.fill", tint: .blue) {
                controlSlider(
                    "System",
                    symbol: "speaker.wave.2.fill",
                    value: Binding(
                        get: { model.systemStatus.volumeLevel },
                        set: { model.setOutputVolume($0) }
                    )
                )
                controlSlider("App audio", symbol: "waveform", value: $model.appVolume)
                if model.displayBrightnessUnavailable {
                    Text("No controllable display found.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    controlSlider(
                        "Brightness",
                        symbol: "sun.max.fill",
                        value: Binding(
                            get: { model.displayBrightness },
                            set: { model.setDisplayBrightness($0) }
                        )
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 14)
            .task {
                model.refreshDisplayBrightness()
            }
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }

    private var quickSettingsEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Show in Quick Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("All") {
                    model.hiddenQuickSettingTitles = []
                }
                .font(.system(size: 10, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }

            Text("Choose which tiles appear in the grid.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(quickSettings) { setting in
                        Toggle(setting.title, isOn: Binding(
                            get: { visibleQuickSettings.contains(setting.title) },
                            set: { isVisible in
                                setQuickSettingVisibility(setting.title, isVisible: isVisible)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11, weight: .medium))
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 330)
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .frame(width: 260)
    }

    private func setQuickSettingVisibility(_ title: String, isVisible: Bool) {
        var hiddenTitles = model.hiddenQuickSettingTitles
        if isVisible {
            hiddenTitles.remove(title)
        } else {
            hiddenTitles.insert(title)
        }
        model.hiddenQuickSettingTitles = hiddenTitles
    }

    private var wifiDetailText: String {
        guard model.systemStatus.wifiOn else { return "Off" }
        if model.showWifiName,
           let ssid = model.systemStatus.wifiSSID,
           !ssid.isEmpty {
            return ssid
        }
        return "On · \(model.systemStatus.wifiBars)/3 bars"
    }

    private func statusReadoutTile(
        title: String,
        detail: String,
        symbol: String,
        isOn: Bool
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isOn ? .white : accent)
                .frame(width: 31, height: 31)
                .background(isOn ? accent : accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Text(detail)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .leading)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 13))
    }

    private func quickSettingTile(_ setting: QuickSetting) -> some View {
        let isOn = quickSettingIsOn(setting.title)
        return Button {
            activateQuickSetting(setting.title)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: setting.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 17)
                Text(setting.title)
                    .font(.system(size: 9, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isOn ? Color.white : Color.primary.opacity(0.82))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .leading)
            .background(
                isOn
                    ? AnyShapeStyle(Color(red: 1, green: 0.27, blue: 0.02))
                    : cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency),
                in: RoundedRectangle(cornerRadius: surfaceStyle == .classic98 ? 3 : 11)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(setting.title)
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private func quickSettingIsOn(_ title: String) -> Bool {
        switch title {
        case "Bluetooth": model.bluetoothEnabled
        case "Dark Mode": model.isDarkMode
        case "VPN": model.vpnEnabled
        default: model.enabledQuickSettings.contains(title)
        }
    }

    private func activateQuickSetting(_ title: String) {
        switch title {
        case "Bluetooth":
            model.bluetoothEnabled.toggle()
        case "Dark Mode":
            model.isDarkMode.toggle()
        case "VPN":
            model.vpnEnabled.toggle()
        default:
            if model.enabledQuickSettings.contains(title) {
                model.enabledQuickSettings.remove(title)
            } else {
                model.enabledQuickSettings.insert(title)
            }
        }
    }

    private func controlSlider(_ title: String, symbol: String, value: Binding<Double>) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 66, alignment: .leading)
            Slider(value: value)
                .tint(accent)
                .controlSize(.small)
        }
    }
}
