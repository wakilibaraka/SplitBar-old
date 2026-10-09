import AppKit
import SwiftUI

extension SettingsFlyout {
    var state: TaskbarConceptState {
        fatalError("state must be provided by the owning view")
    }

    // MARK: - Tab 1: Taskbar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // MARK: - Tab 1: Taskbar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var taskbarTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                taskbarModeCard
                if taskbarMode == .centered || taskbarMode == .macOS {
                    barWidthCard
                }
                dividerCard
                clusterOrderCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var taskbarModeCard: some View {
        settingsSection("Taskbar mode") {
            HStack(spacing: 10) {
                ForEach(TaskbarMode.allCases) { mode in
                    Button { taskbarMode = mode } label: {
                        VStack(spacing: 6) {
                            TaskbarModeThumbnail(mode: mode, isSelected: taskbarMode == mode)
                            Text(mode.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(taskbarMode == mode ? accent : .primary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(mode.detail)
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(taskbarMode.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(taskbarMode.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 4)

            if taskbarMode.isSplit {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Island gap")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        sliderValueLabel("\(Int(islandGap)) pt")
                    }
                    ThemeSlider(value: $islandGap, in: 0...40, step: 1).tint(accent)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Taskbar height")
                    .font(.system(size: 13, weight: .medium))
                // Height presets: XS/S/M/L/XL
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    let presets: [(String, CGFloat)] = [("XS", 32), ("S", 38), ("M", 42), ("L", 46), ("XL", 52)]
                    ForEach(presets, id: \.0) { label, h in
                        Button {
                            withAnimation(.spring(response: 0.25)) { taskbarHeight = h }
                        } label: {
                            Text(label)
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    abs(taskbarHeight - h) < 1 ? accent.opacity(0.16) : Color.primary.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    ThemeSlider(value: $taskbarHeight, in: 32...56, step: 2).tint(accent)
                    sliderValueLabel("\(Int(taskbarHeight)) pt")
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $showsTaskbarPanel) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Screen-edge panel")
                            .font(.system(size: 13, weight: .medium))
                        Text("Show the taskbar in a bottom-edge panel.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(ThemeToggleStyle())
                Toggle(isOn: $hideMacDock) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Hide macOS Dock")
                            .font(.system(size: 13, weight: .medium))
                        Text("Experimental and fully reversible. Original Dock settings restore on quit.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(ThemeToggleStyle())
            }
        }
    }

    var barWidthCard: some View {
        settingsSection("Bar width") {
            HStack {
                Text("Centered width")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                sliderValueLabel("\(Int(centeredBarWidth)) pt")
            }
            ThemeSlider(value: $centeredBarWidth, in: 360...1600, step: 20).tint(accent)
            Text("Narrower bars leave more desktop visible.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    var dividerCard: some View {
        settingsSection("Dividers") {
            if userDividers.isEmpty {
                Text("No dividers yet. Right-click any taskbar icon and choose Divider to place one after it.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(userDividers.enumerated()), id: \.element.id) { index, divider in
                        HStack(spacing: 8) {
                            Text("Divider \(index + 1)")
                                .font(.system(size: 12, weight: .medium))
                            Text(divider.anchorBundleID.map(taskbarDisplayName(for:)) ?? "End of strip")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Menu("Move") {
                                ForEach(pinnedAppBundleIDs, id: \.self) { bundleID in
                                    Button(taskbarDisplayName(for: bundleID)) {
                                        moveDivider(divider.id, after: bundleID)
                                    }
                                }
                            }
                            .menuStyle(.borderlessButton)
                            .frame(maxWidth: 80)
                            Button(role: .destructive) {
                                removeDivider(divider.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                    }
                }
            }
            Menu {
                ForEach(pinnedAppBundleIDs, id: \.self) { bundleID in
                    Button(taskbarDisplayName(for: bundleID)) { addDivider(after: bundleID) }
                }
            } label: {
                Label("Add divider after an app", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .disabled(pinnedAppBundleIDs.isEmpty || taskbarMode == .macOS)
        }
    }

    var clusterOrderCard: some View {
        settingsSection("Cluster order") {
            Text("Downloads, Trash, and system status travel as one cluster.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                ForEach(Array(clusterOrder.enumerated()), id: \.element) { index, key in
                    HStack(spacing: 8) {
                        Text(clusterItemTitle(key))
                            .font(.system(size: 12, weight: .medium))
                        Spacer(minLength: 0)
                        Button { moveClusterItem(key, offset: -1) } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .disabled(index == 0)
                        Button { moveClusterItem(key, offset: 1) } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .disabled(index == clusterOrder.count - 1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tab 2: Themes
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var themesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                themeSwatchCard
                appearanceCard
                iconSizeCard
                transparencyCard
                cornersCard
                taskbarGradientCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var themeSwatchCard: some View {
        settingsSection("Surface theme") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(SurfaceStyle.allCases) { style in
                    themeSwatchButton(style)
                }
            }
            HStack {
                Text(surfaceStyle.title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(surfaceStyle.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
            Text("Theme applies across the taskbar, all flyouts, and widget cards.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            glassMaterialSelector
        }
    }

    var glassMaterialSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Glass material")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Picker("", selection: state.glassMaterialBinding()) {
                    ForEach(GlassMaterial.allCases) { material in
                        Text(material.title).tag(material)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            if state.glassMaterialForSettings == .clear {
                Text(GlassMaterial.clear.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Text(GlassMaterial.frosted.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    func themeSwatchButton(_ style: SurfaceStyle) -> some View {
        Button { surfaceStyle = style } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: max(4, style.cornerRadius * 0.45), style: .continuous)
                        .fill(state.glassMaterial.background(style: style, darkMode: isDarkMode))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(state.glassMaterial.taskbar(style: style, darkMode: isDarkMode))
                        .frame(height: 10)
                        .padding(.horizontal, 2)
                        .padding(.bottom, 2)
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(style.accent(darkMode: isDarkMode).opacity(0.8))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.bottom, 14)
                    if surfaceStyle == style {
                        RoundedRectangle(cornerRadius: max(4, style.cornerRadius * 0.45), style: .continuous)
                            .strokeBorder(accent, lineWidth: 2.5)
                    }
                    if style == .neobrutalism {
                        Rectangle()
                            .strokeBorder(Color.black, lineWidth: 2)
                    }
                }
                .frame(height: 62)
                Text(style.title)
                    .font(.system(size: 9, weight: surfaceStyle == style ? .semibold : .medium))
                    .foregroundStyle(surfaceStyle == style ? accent : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .buttonStyle(.plain)
    }

    var appearanceCard: some View {
        settingsSection("Appearance") {
            Toggle(isOn: $isDarkMode) {
                Label(
                    isDarkMode ? "Dark appearance" : "Light appearance",
                    systemImage: isDarkMode ? "moon.stars.fill" : "sun.max.fill"
                )
                .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(ThemeToggleStyle())
        }
    }

    var transparencyCard: some View {
        settingsSection("Transparency") {
            Toggle(isOn: Binding(
                get: { interfaceTransparency > 0 },
                set: { interfaceTransparency = $0 ? 0.40 : 0 }
            )) {
                Text("Enable transparency")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(ThemeToggleStyle())
            ThemeSlider(value: $interfaceTransparency, in: 0...0.9, step: 0.01)
                .tint(accent)
                .disabled(interfaceTransparency == 0)
            HStack {
                Text("\(Int(interfaceTransparency * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Applies to panels and taskbar")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    var cornersCard: some View {
        settingsSection("Corners") {
            HStack(spacing: 8) {
                ForEach(CornerStyle.allCases) { style in
                    Button { cornerStyle = style } label: {
                        Text(style.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                cornerStyle == style ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Text("Apply corners to")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $cornerScope) {
                    ForEach(CornerScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            if cornerScope == .perSurface {
                cornerSurfaceRow("Taskbar", selection: $cornerTaskbar)
                cornerSurfaceRow("Widgets", selection: $cornerWidgets)
                cornerSurfaceRow("Flyouts", selection: $cornerFlyouts)
            }
            Text("Pill rounds shells fully. Sharp floors at 2 pt so beveled themes keep reading correctly.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    func cornerSurfaceRow(_ title: String, selection: Binding<CornerStyle>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Picker("", selection: selection) {
                ForEach(CornerStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }

    var taskbarGradientCard: some View {
        settingsSection("Taskbar gradient") {
            Toggle("Use custom gradient", isOn: $usesTaskbarGradient)
                .toggleStyle(ThemeToggleStyle())
                .font(.system(size: 13, weight: .medium))
            if usesTaskbarGradient {
                HStack(spacing: 16) {
                    ColorPicker("Start", selection: $taskbarGradientStart, supportsOpacity: false)
                    ColorPicker("End", selection: $taskbarGradientEnd, supportsOpacity: false)
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tab 3: Widgets & Wallpaper
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var widgetsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                widgetAppearanceCard
                wallpaperPresetsCard
                wallpaperGradientCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var widgetAppearanceCard: some View {
        settingsSection("Widget cards") {
            Toggle(isOn: $widgetOutlineBorder) {
                Text("Card outline")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(ThemeToggleStyle())
            HStack {
                Text("Outline width")
                    .font(.system(size: 12, weight: .medium))
                ThemeSlider(value: $widgetOutlineWidth, in: 0.5...3, step: 0.5).tint(accent)
                sliderValueLabel("\(String(format: "%.1f", widgetOutlineWidth)) pt")
            }
            .disabled(!widgetOutlineBorder)
            Toggle(isOn: $iconBackgroundVisible) {
                Text("Icon tile background")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(ThemeToggleStyle())
            HStack(spacing: 8) {
                ForEach(IconShape.allCases) { shape in
                    Button { iconBackgroundShape = shape } label: {
                        Text(shape.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                iconBackgroundShape == shape ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .disabled(!iconBackgroundVisible)
            HStack {
                Text("Weather card corners")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $cornerWidgets) {
                    ForEach(CornerStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            Text("Weather follows the Widgets corner style; pick it here without leaving this tab.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    var wallpaperPresetsCard: some View {
        settingsSection("Desktop wallpaper") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(WallpaperPreset.allCases) { preset in
                    wallpaperPresetButton(preset)
                }
            }
            Text("Choose a preset, or Custom to pick your own gradient colours.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            if wallpaperPreset == .custom {
                HStack(spacing: 16) {
                    ColorPicker("Start colour", selection: $pastelTint, supportsOpacity: false)
                    ColorPicker("End colour", selection: $gradientEndTint, supportsOpacity: false)
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }

    func wallpaperPresetButton(_ preset: WallpaperPreset) -> some View {
        Button {
            wallpaperPreset = preset
            isDarkMode = preset.isDark
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: preset == .custom ? [pastelTint, gradientEndTint] : preset.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 44)
                Text(preset.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                wallpaperPreset == preset ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 11)
            )
        }
        .buttonStyle(.plain)
    }

    var wallpaperGradientCard: some View {
        settingsSection("Wallpaper gradient") {
            HStack {
                Text("Angle")
                    .font(.system(size: 13, weight: .medium))
                ThemeSlider(value: $gradientAngle, in: 0...360, step: 1).tint(accent)
                sliderValueLabel("\(Int(gradientAngle))°")
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tab 4: Flyouts
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var flyoutsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                flyoutMotionCard
                panelWidthsCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var flyoutMotionCard: some View {
        settingsSection("Animation & height") {
            Text("Open animation")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(FlyoutAnimation.allCases) { animation in
                    Button { flyoutAnimation = animation } label: {
                        Text(animation.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                flyoutAnimation == animation ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Height")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(FlyoutHeightPreset.allCases) { preset in
                    Button { flyoutHeightPreset = preset } label: {
                        Text(preset.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                flyoutHeightPreset == preset ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var panelWidthsCard: some View {
        settingsSection("Panel widths") {
            ForEach(PanelKind.allCases) { kind in
                panelWidthRow(kind)
            }
            Text("Widen any panel up to its maximum width.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    func panelWidthRow(_ kind: PanelKind) -> some View {
        HStack {
            Text(kind.title)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 100, alignment: .leading)
            Slider(
                value: panelWidthBinding(for: kind),
                in: Double(kind.minimumWidth)...Double(kind.maximumWidth),
                step: 10
            )
            .tint(accent)
            sliderValueLabel("\(Int(panelWidths[kind] ?? kind.defaultWidth)) pt")
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tab 5: Advanced
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tab 6: Privacy
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var privacyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                capabilitiesCard
                dataGatesCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var capabilities: [PrivacyCapability] {
        [
            PrivacyCapability(
                id: "clipboard",
                title: "Clipboard history",
                purpose: "Records what you copy so you can paste it again.",
                leavesTheMac: "Nothing leaves the Mac. Entries are written to your home folder, readable only by you.",
                settingsPane: nil,
                status: clipboardHistoryEnabled ? .granted : .notRequested
            ),
            PrivacyCapability(
                id: "previews",
                title: "Window previews",
                purpose: "Shows live thumbnails when you hover a taskbar icon.",
                leavesTheMac: "Nothing leaves the Mac. Icons are used instead if you decline.",
                settingsPane: PrivacyStatusReader.panes.screenRecording,
                status: PrivacyStatusReader.screenRecording
            ),
            PrivacyCapability(
                id: "accessibility",
                title: "Minimize windows",
                purpose: "Lets a taskbar click send the frontmost window to the Dock.",
                leavesTheMac: "Nothing leaves the Mac.",
                settingsPane: PrivacyStatusReader.panes.accessibility,
                status: PrivacyStatusReader.accessibility
            ),
            PrivacyCapability(
                id: "wifi",
                title: "Wi-Fi network name",
                purpose: "Shows which network you are on in Quick Settings.",
                leavesTheMac: "Nothing leaves the Mac, but macOS requires Location before it will show the name.",
                settingsPane: PrivacyStatusReader.panes.location,
                status: PrivacyStatusReader.location
            ),
            PrivacyCapability(
                id: "bluetooth",
                title: "Bluetooth devices",
                purpose: "Lists paired devices so you can reconnect them.",
                leavesTheMac: "Nothing leaves the Mac.",
                settingsPane: PrivacyStatusReader.panes.bluetooth,
                status: PrivacyStatusReader.bluetooth
            ),
            PrivacyCapability(
                id: "automation",
                title: "Control other apps",
                purpose: "Reveals files in Finder, closes windows, reads now-playing status.",
                leavesTheMac: "Nothing leaves the Mac. macOS asks the first time you use one of these.",
                settingsPane: PrivacyStatusReader.panes.automation,
                status: .notRequested
            ),
        ]
    }

    var capabilitiesCard: some View {
        settingsSection("What this app can access") {
            VStack(spacing: 8) {
                ForEach(capabilities) { capability in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: capability.status.symbolName)
                                .foregroundStyle(capability.status == .granted ? accent : .secondary)
                            Text(capability.title)
                                .font(.system(size: 12, weight: .semibold))
                            Spacer(minLength: 6)
                            // Never colour alone: text plus a distinct symbol.
                            Text(capability.status.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Text(capability.purpose)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(capability.leavesTheMac)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            HStack(spacing: 14) {
                Button("Open System Settings") {
                    PrivacyStatusReader.openPane(PrivacyStatusReader.panes.accessibility)
                }
                Button("Login Items") {
                    PrivacyStatusReader.openPane(PrivacyStatusReader.panes.loginItems)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(accent)
        }
    }

    var dataGatesCard: some View {
        settingsSection("Optional data access") {
            Toggle(isOn: $clipboardHistoryEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Record clipboard history")
                        .font(.system(size: 13, weight: .medium))
                    Text("Off by default. Pasteboards an app marks as private are never recorded.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(ThemeToggleStyle())

            Toggle(isOn: $ipGeolocationEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Weather location from IP address")
                        .font(.system(size: 13, weight: .medium))
                    Text("Your IP address is sent to ipwho.is. Off by default.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(ThemeToggleStyle())

            Toggle(isOn: $faviconServiceEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Third-party favicon fallback")
                        .font(.system(size: 13, weight: .medium))
                    Text("Tells DuckDuckGo and Google which sites you pinned. Off by default.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(ThemeToggleStyle())

            Toggle(isOn: $aiAccountSwitchingEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Read Claude Code and Codex credentials")
                        .font(.system(size: 13, weight: .medium))
                    Text("Reads the \"Claude Code-credentials\" Keychain item and ~/.codex/auth.json, and contacts provider OAuth endpoints. Off by default; Claude usage still comes from the Claude Code status line.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(ThemeToggleStyle())

            Text("Clipboard retention")
                .font(.system(size: 12, weight: .medium))
            HStack(spacing: 8) {
                ForEach(ClipboardRetentionWindow.allCases) { window in
                    Button {
                        clipboardRetention = ClipboardRetentionPolicy(
                            maxEntries: clipboardRetention.maxEntries,
                            maxBlobBytes: clipboardRetention.maxBlobBytes,
                            window: window
                        )
                    } label: {
                        Text(window.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                clipboardRetention.window == window ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Hosts contacted with these defaults: api.open-meteo.com for weather, plus the sites you pinned for their own icon. See NETWORK.md.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var advancedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                runningIndicatorCard
                clickBehaviorCard
                contextMenuCard
                statusIconCard
                hotkeysCard
                privacyCard
                trashPlacementCard
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    var runningIndicatorCard: some View {
        settingsSection("Running indicator") {
            Text("Style")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(RunningIndicatorStyle.allCases) { style in
                    Button { runningIndicatorStyle = style } label: {
                        Text(style.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                runningIndicatorStyle == style ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Size")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(RunningIndicatorSize.allCases) { size in
                    Button { runningIndicatorSize = size } label: {
                        Text(size.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background(
                                runningIndicatorSize == size ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 8)
            }
            Text("Colour")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(IndicatorColorPreset.allCases) { preset in
                    Button { indicatorColorPreset = preset } label: {
                        Text(preset.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                indicatorColorPreset == preset ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            if indicatorColorPreset == .gradient {
                HStack(spacing: 16) {
                    ColorPicker("Start", selection: $indicatorGradientStart, supportsOpacity: false)
                    ColorPicker("End", selection: $indicatorGradientEnd, supportsOpacity: false)
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }

    var clickBehaviorCard: some View {
        settingsSection("Click focused app") {
            HStack(spacing: 8) {
                ForEach(AppMinimizeMode.allCases) { mode in
                    Button { minimizeMode = mode } label: {
                        Text(mode.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                minimizeMode == mode ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Minimize needs Accessibility (prompted on first use). Hide needs nothing.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    var contextMenuCard: some View {
        settingsSection("Right-click menu") {
            HStack(spacing: 8) {
                ForEach(ContextMenuStyle.allCases) { style in
                    Button { contextMenuStyle = style } label: {
                        Text(style.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                contextMenuStyle == style ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var privacyCard: some View {
        settingsSection("Features & Privacy") {
            Toggle(isOn: $showWindowPreviews) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Window previews")
                        .font(.system(size: 13, weight: .medium))
                    Text("Live thumbnails on icon hover. Needs Screen Recording; falls back to icon otherwise.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(ThemeToggleStyle())
            Toggle(isOn: $showWifiName) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Show Wi-Fi network name")
                        .font(.system(size: 13, weight: .medium))
                    Text("Needs Location — macOS prompts once on first read.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(ThemeToggleStyle())
            Toggle(isOn: $showBluetoothDevices) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bluetooth devices")
                        .font(.system(size: 13, weight: .medium))
                    Text("Lists paired devices with tap-to-connect.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(ThemeToggleStyle())
            Toggle(isOn: $ddcBrightnessEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("External display brightness (DDC)")
                        .font(.system(size: 13, weight: .medium))
                    Text("Uses a private display API, isolated and probed at runtime.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(ThemeToggleStyle())
        }
    }

    var iconSizeCard: some View {
        settingsSection("Taskbar icons") {
            HStack(spacing: 8) {
                ForEach(TaskbarIconSize.allCases) { size in
                    Button { taskbarIconSize = size } label: {
                        VStack(spacing: 7) {
                            Image(systemName: "app.fill")
                                .font(.system(size: max(13, size.glyphFraction * 42), weight: .medium))
                                .foregroundStyle(accent)
                                .frame(height: 30)
                            Text(size.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            taskbarIconSize == size ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Glyph scales with taskbar height; XS is compact, XL is touch-sized.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    var statusIconCard: some View {
        settingsSection("Status icon") {
            Text("One primary glyph per tile. Volume and network layer inside the battery ring — never side by side.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                ForEach(StatusIconPreset.allCases) { preset in
                    Button { statusIconPreset = preset } label: {
                        HStack {
                            Text(preset.title)
                                .font(.system(size: 12, weight: .medium))
                            Spacer(minLength: 0)
                            Image(systemName: statusIconPreset == preset ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(statusIconPreset == preset ? accent : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            statusIconPreset == preset ? accent.opacity(0.10) : Color.primary.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            if statusIconPreset == .customSFSymbol {
                TextField("SF Symbol name", text: $statusIconCustomSymbol)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }
        }
    }

    var hotkeysCard: some View {
        settingsSection("Keyboard shortcuts") {
            Text("Global shortcuts. Click Record, then press a key combination. Escape cancels.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                ForEach(shortcutBindings.filter(\.action.isRebindable)) { binding in
                    HStack(spacing: 8) {
                        Text(binding.action.title)
                            .font(.system(size: 12, weight: .medium))
                        Spacer(minLength: 0)
                        Text(shortcutChordLabel(binding.chord))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                        Button(recordingBindingID == binding.id ? "Press keys…" : "Record") {
                            startRecording(binding.id)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                        .disabled(recordingBindingID != nil && recordingBindingID != binding.id)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            if let conflictMessage {
                Text(conflictMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
            }
            Button {
                shortcutBindings = TaskbarConceptState.defaultShortcutBindings
                conflictMessage = nil
            } label: {
                Label("Reset defaults", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)
        }
    }

    func startRecording(_ id: UUID) {
        recordingMonitor.map(NSEvent.removeMonitor)
        recordingMonitor = nil
        recordingBindingID = id
        conflictMessage = nil
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            if event.keyCode == 0x35 {
                stopRecording()
                return event
            }
            let modifiers = carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else { return event }
            let chord = ShortcutChord(carbonKeyCode: UInt32(event.keyCode), carbonModifiers: modifiers)
            var updated = shortcutBindings
            updated.removeAll { $0.id == id }
            let candidate = ShortcutBinding(id: id, chord: chord, action: shortcutBindings.first(where: { $0.id == id })?.action ?? .toggleDock)
            let conflicts = shortcutConflicts(bindings: updated + [candidate]).filter { $0.bindingIDs.contains(id) }
            if conflicts.isEmpty {
                updated.append(candidate)
                shortcutBindings = updated
            } else {
                conflictMessage = "\(shortcutChordLabel(chord)) is already taken."
            }
            stopRecording()
            return nil
        }
    }

    func stopRecording() {
        recordingMonitor.map(NSEvent.removeMonitor)
        recordingMonitor = nil
        recordingBindingID = nil
    }

    var trashPlacementCard: some View {
        settingsSection("Trash placement — \(taskbarMode.title)") {
            HStack(spacing: 8) {
                ForEach(TrashPlacement.allCases) { placement in
                    Button {
                        trashAnchors[taskbarMode.rawValue] = placement.rawValue
                    } label: {
                        Text(placement.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                effectiveTrashPlacement == placement ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 12) {
                Button {
                    trashPlacement = effectiveTrashPlacement
                    for mode in TaskbarMode.allCases {
                        trashAnchors[mode.rawValue] = effectiveTrashPlacement.rawValue
                    }
                } label: {
                    Label("Use in every mode", systemImage: "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
                if trashAnchors[taskbarMode.rawValue] != nil {
                    Button {
                        trashAnchors[taskbarMode.rawValue] = nil
                    } label: {
                        Label("Reset \(taskbarMode.title)", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(accent)
                }
            }
        }
    }

    // MARK: - Tab: System
    var systemTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                settingsSection("Startup") {
                    Toggle("Launch SplitBar automatically at login", isOn: $isLaunchAtLoginEnabled)
                        .toggleStyle(ThemeToggleStyle())
                        .font(.system(size: 13, weight: .medium))
                }
                
                settingsSection("Legacy Edge Dock") {
                    Text("The classic edge-dock behavior. If enabled, SplitBar will also render a dock on the specified screen edge.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Toggle("Enable Edge Dock", isOn: $isLegacyEdgeDockEnabled)
                        .toggleStyle(ThemeToggleStyle())
                        .font(.system(size: 13, weight: .medium))
                        .padding(.bottom, 4)
                        
                    if isLegacyEdgeDockEnabled {
                        Picker("Edge Placement", selection: Binding(
                            get: { preferences.placement.edge },
                            set: { newEdge in
                                var updated = preferences
                                updated.placement.edge = newEdge
                                preferences = updated
                            }
                        )) {
                            Text("Left").tag(DockEdge.left)
                            Text("Bottom").tag(DockEdge.bottom)
                            Text("Right").tag(DockEdge.right)
                            Text("Top").tag(DockEdge.top)
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            Text("Icon Size")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Slider(value: Binding(
                                get: { preferences.dockIconSize },
                                set: { preferences.dockIconSize = $0 }
                            ), in: 32...80)
                            .frame(width: 140)
                        }
                        
                        Toggle("Auto-hide Dock", isOn: Binding(
                            get: { preferences.placement.autoHide },
                            set: { newAutoHide in
                                var updated = preferences
                                updated.placement.autoHide = newAutoHide
                                preferences = updated
                            }
                        ))
                        .toggleStyle(ThemeToggleStyle())
                        .font(.system(size: 12, weight: .medium))
                    }
                }
                
                settingsSection("Motion & Accessibility") {
                    Toggle("Reduce Motion (disables spring overshoot)", isOn: Binding(
                        get: { preferences.reduceMotion },
                        set: { preferences.reduceMotion = $0 }
                    ))
                    .toggleStyle(ThemeToggleStyle())
                    .font(.system(size: 13, weight: .medium))
                }
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Tab: Shortcuts
    var shortcutsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hotkeysCard
                
                settingsSection("Clipboard Exclusions") {
                    Text("Bundle identifiers excluded from clipboard history.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    if preferences.clipboardExcludedBundleIdentifiers.isEmpty {
                        Text("No excluded applications")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(preferences.clipboardExcludedBundleIdentifiers).sorted(), id: \.self) { bundleID in
                            HStack {
                                Text(bundleID)
                                    .font(.system(size: 12, design: .monospaced))
                                Spacer()
                                Button {
                                    var updated = preferences
                                    updated.clipboardExcludedBundleIdentifiers.remove(bundleID)
                                    preferences = updated
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }
}
