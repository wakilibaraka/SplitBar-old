import ApplicationServices
import SwiftUI

public struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .general
    @State private var newExcludedBundleID: String = ""
    public let preferences: AppPreferences
    public let isLaunchAtLoginEnabled: Bool
    public let onUpdatePreferences: (AppPreferences) -> Void
    public let onToggleLaunchAtLogin: (Bool) -> Void

    public init(
        preferences: AppPreferences,
        isLaunchAtLoginEnabled: Bool,
        onUpdatePreferences: @escaping (AppPreferences) -> Void,
        onToggleLaunchAtLogin: @escaping (Bool) -> Void
    ) {
        self.preferences = preferences
        self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
        self.onUpdatePreferences = onUpdatePreferences
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
    }

    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case dock = "Dock"
        case appearance = "Appearance"
        case shortcuts = "Shortcuts"
        case clipboard = "Clipboard"
        case widgets = "Widgets"
        case privacy = "Privacy"
        case importExport = "Backup"
        case diagnostics = "Diagnostics"

        public var id: String { rawValue }

        public var systemImage: String {
            switch self {
            case .general: return "gear"
            case .dock: return "dock.rectangle"
            case .appearance: return "paintbrush"
            case .shortcuts: return "command"
            case .clipboard: return "doc.on.clipboard"
            case .widgets: return "square.grid.2x2"
            case .privacy: return "hand.raised"
            case .importExport: return "arrow.triangle.2.circlepath"
            case .diagnostics: return "wrench.and.screwdriver"
            }
        }
    }

    public var body: some View {
        // 9 bölüm TabView araç çubuğuna sığmadığı için macOS Sistem Ayarları gibi kenar çubuklu düzen kullanılır
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 190.0, ideal: 200.0, max: 240.0)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            tabContent(selectedTab ?? .general)
                .formStyle(.grouped)
                .navigationTitle((selectedTab ?? .general).rawValue)
        }
        .frame(width: 780.0, height: 520.0)
    }

    @ViewBuilder
    private func tabContent(_ tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            generalTab
        case .dock:
            dockTab
        case .appearance:
            appearanceTab
        case .shortcuts:
            shortcutsTab
        case .clipboard:
            clipboardTab
        case .widgets:
            widgetsTab
        case .privacy:
            privacyTab
        case .importExport:
            importExportTab
        case .diagnostics:
            diagnosticsTab
        }
    }

    private var generalTab: some View {
        Form {
            Section("System & Startup") {
                Toggle(
                    "Launch SplitBar automatically at login",
                    isOn: Binding(
                        get: { isLaunchAtLoginEnabled },
                        set: { onToggleLaunchAtLogin($0) }
                    )
                )
            }

            Section("Language / Dil") {
                Picker(
                    "Language",
                    selection: Binding(
                        get: { preferences.language },
                        set: { newLanguage in
                            var updated = preferences
                            updated.language = newLanguage
                            onUpdatePreferences(updated)
                        }
                    )
                ) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Motion & Accessibility") {
                Toggle(
                    "Reduce Motion (disables spring overshoot)",
                    isOn: Binding(
                        get: { preferences.reduceMotion },
                        set: { newValue in
                            var updated = preferences
                            updated.reduceMotion = newValue
                            onUpdatePreferences(updated)
                        }
                    )
                )
            }
        }
    }

    private var dockTab: some View {
        Form {
            Section("Placement & Edge") {
                Picker(
                    "Edge",
                    selection: Binding(
                        get: { preferences.placement.edge },
                        set: { newEdge in
                            let updatedPlacement = DockPlacement(
                                edge: newEdge,
                                verticalOffsetFraction: preferences.placement.verticalOffsetFraction,
                                autoHide: preferences.placement.autoHide
                            )
                            var updated = preferences
                            updated.placement = updatedPlacement
                            onUpdatePreferences(updated)
                        }
                    )
                ) {
                    Text("Right Edge").tag(DockEdge.right)
                    Text("Left Edge").tag(DockEdge.left)
                    Text("Top Edge").tag(DockEdge.top)
                    Text("Bottom Edge").tag(DockEdge.bottom)
                }
            }

            Section("Icon Size / İkon Boyutu") {
                Picker(
                    "Dock Icon Size",
                    selection: Binding(
                        get: { preferences.dockIconSize },
                        set: { newSize in
                            var updated = preferences
                            updated.dockIconSize = newSize
                            onUpdatePreferences(updated)
                        }
                    )
                ) {
                    Text("Small (38 pt)").tag(38.0)
                    Text("Medium (46 pt)").tag(46.0)
                    Text("Large (54 pt)").tag(54.0)
                    Text("Extra Large (62 pt)").tag(62.0)
                }
                .pickerStyle(.segmented)
            }

            Section("Dock Visibility") {
                Toggle(
                    "Auto-hide Dock",
                    isOn: Binding(
                        get: { preferences.placement.autoHide },
                        set: { newAutoHide in
                            let updatedPlacement = DockPlacement(
                                edge: preferences.placement.edge,
                                verticalOffsetFraction: preferences.placement.verticalOffsetFraction,
                                autoHide: newAutoHide
                            )
                            var updated = preferences
                            updated.placement = updatedPlacement
                            onUpdatePreferences(updated)
                        }
                    )
                )
            }
        }
    }

    private var appearanceTab: some View {
        Form {
            Section("2026/2027 Liquid Glass Themes") {
                Picker(
                    "Theme",
                    selection: Binding(
                        get: { preferences.materialStyle },
                        set: { newStyle in
                            var updated = preferences
                            updated.materialStyle = newStyle
                            onUpdatePreferences(updated)
                        }
                    )
                ) {
                    ForEach(DockMaterialStyle.presets, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                    if case .customRGBA = preferences.materialStyle {
                        Text("Custom Tint").tag(preferences.materialStyle)
                    }
                }
            }
        }
    }

    private var shortcutsTab: some View {
        Form {
            Section("Global Navigation & Launcher") {
                HStack {
                    Text("Toggle Dock")
                    Spacer()
                    Text("⌥ D")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
                HStack {
                    Text("Command Palette & AI")
                    Spacer()
                    Text("⌥ Space")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
                HStack {
                    Text("Clipboard History")
                    Spacer()
                    Text("⌥ V")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
            }
            Section("Window Snapping & Tiling") {
                HStack {
                    Text("Snap Window Left")
                    Spacer()
                    Text("⌃⌥ ←")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
                HStack {
                    Text("Snap Window Right")
                    Spacer()
                    Text("⌃⌥ →")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
                HStack {
                    Text("Maximize Window")
                    Spacer()
                    Text("⌃⌥ ↑")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
                HStack {
                    Text("Center Window")
                    Spacer()
                    Text("⌃⌥ ↓")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(Color.secondary.opacity(0.15)))
                }
            }
        }
    }

    private var clipboardTab: some View {
        Form {
            Section("History Limits") {
                Text("Max Entries: \(preferences.clipboardRetention.maxEntries)")
                Text("Max Payload: \(preferences.clipboardRetention.maxBlobBytes / (1024 * 1024)) MB")
            }
            Section("Excluded Applications") {
                if preferences.clipboardExcludedBundleIdentifiers.isEmpty {
                    Text("No excluded applications")
                        .foregroundColor(.secondary)
                }
                ForEach(preferences.clipboardExcludedBundleIdentifiers.sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(role: .destructive) {
                            var updated = preferences
                            updated.clipboardExcludedBundleIdentifiers.remove(bundleID)
                            onUpdatePreferences(updated)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .accessibilityLabel("Remove \(bundleID)")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    TextField("Bundle identifier (e.g. com.apple.Passwords)", text: $newExcludedBundleID)
                        .onSubmit(addExcludedBundleID)
                    Button("Add", action: addExcludedBundleID)
                        .disabled(trimmedNewExcludedBundleID.isEmpty)
                }
            }
        }
    }

    private var trimmedNewExcludedBundleID: String {
        newExcludedBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addExcludedBundleID() {
        let bundleID = trimmedNewExcludedBundleID
        guard !bundleID.isEmpty else { return }
        var updated = preferences
        updated.clipboardExcludedBundleIdentifiers.insert(bundleID)
        onUpdatePreferences(updated)
        newExcludedBundleID = ""
    }

    private var widgetsTab: some View {
        Form {
            Section("Installed Widgets") {
                HStack {
                    Label("Clipboard History", systemImage: "doc.on.clipboard")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("System Monitor", systemImage: "cpu")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("Now Playing", systemImage: "music.note")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("Weather Forecast", systemImage: "sun.max.fill")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("Bluetooth Devices", systemImage: "dot.radiowaves.left.and.right")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("Local AI (Ollama)", systemImage: "sparkles")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
                HStack {
                    Label("Quick Scratchpad", systemImage: "note.text")
                    Spacer()
                    Text("Built-in").foregroundColor(.secondary)
                }
            }
        }
    }

    private var privacyTab: some View {
        Form {
            Section("Diagnostics & Permissions") {
                HStack {
                    Text("Accessibility Permission")
                    Spacer()
                    if AXIsProcessTrusted() {
                        Text("Granted")
                            .foregroundColor(.green)
                    } else {
                        Text("Not Granted (Required for Window Tiling)")
                            .foregroundColor(.orange)
                    }
                }
                HStack {
                    Text("Screen Recording Permission")
                    Spacer()
                    Text("Not Required")
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Local-First Storage")
                    Spacer()
                    Text("100% On-Device")
                        .foregroundColor(.green)
                }
            }
        }
    }

    private var importExportTab: some View {
        Form {
            Section("Configuration Backup") {
                Text("Settings and items are saved automatically to Application Support.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var diagnosticsTab: some View {
        Form {
            Section("System Diagnostics") {
                Text("Application: SplitBar (macOS 15.0+)")
                Text("Architecture: Apple Silicon Native (ARM64)")
                Text("Storage: JSON Atomic Persistence")
            }
        }
    }
}
