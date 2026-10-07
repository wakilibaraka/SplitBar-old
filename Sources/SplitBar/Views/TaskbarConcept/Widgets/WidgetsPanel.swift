import SwiftUI

struct WidgetsPanel: View {
    private var shellRadius: CGFloat { model.shellRadius(for: .widgets) }
    let onClose: () -> Void
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @State private var isEditingWidgets = false

    private var boardSections: [WidgetBoardSection] {
        var sections: [WidgetBoardSection] = []
        var leading: [DashboardWidget] = []
        var trailing: [DashboardWidget] = []
        var leadingHeight: CGFloat = 0
        var trailingHeight: CGFloat = 0
        var nextID = 0

        func flushColumns() {
            guard !leading.isEmpty || !trailing.isEmpty else { return }
            sections.append(.columns(id: nextID, leading: leading, trailing: trailing))
            nextID += 1
            leading = []
            trailing = []
            leadingHeight = 0
            trailingHeight = 0
        }

        for widget in model.widgetOrder {
            let size = model.widgetSize(for: widget)
            if size.spansBoard {
                flushColumns()
                sections.append(.fullWidth(id: nextID, widget: widget))
                nextID += 1
            } else if leadingHeight <= trailingHeight {
                leading.append(widget)
                leadingHeight += size.estimatedHeight
            } else {
                trailing.append(widget)
                trailingHeight += size.estimatedHeight
            }
        }
        flushColumns()
        return sections
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Widgets")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text(isEditingWidgets ? "Drag to rearrange · Choose a size on each card" : "A little overview of your day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isEditingWidgets.toggle()
                } label: {
                    Text(isEditingWidgets ? "Done" : "Edit")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.6), in: Capsule())
                .help("Rearrange and resize widgets")
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.6), in: Circle())
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(boardSections) { section in
                        switch section {
                        case let .columns(_, leading, trailing):
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 12) {
                                    ForEach(leading) { widget in
                                        widgetTile(widget)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                                VStack(spacing: 12) {
                                    ForEach(trailing) { widget in
                                        widgetTile(widget)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        case let .fullWidth(_, widget):
                            widgetTile(widget)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white.opacity(0.95) : Color.white.opacity(0.72), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(surfaceStyle == .classic98 ? 0.12 : 0.18), radius: surfaceStyle == .glassmorphism ? 22 : 14, x: 0, y: surfaceStyle == .classic98 ? 3 : 8)
        .aeroSheen(cornerRadius: shellRadius)
    }

    @ViewBuilder
    private func widgetTile(_ widget: DashboardWidget) -> some View {
        let size = model.widgetSize(for: widget)
        let tile = widgetContent(widget, size: size)
            .overlay(alignment: .topTrailing) {
                if isEditingWidgets {
                    Menu {
                        ForEach(WidgetSizePreset.allCases) { preset in
                            Button {
                                model.setWidgetSize(preset, for: widget)
                            } label: {
                                if preset == size {
                                    Label(preset.title, systemImage: "checkmark")
                                } else {
                                    Text(preset.title)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.75))
                            .frame(width: 25, height: 25)
                            .background(.regularMaterial, in: Circle())
                    }
                    .menuStyle(.borderlessButton)
                    .padding(9)
                    .help("Change widget size")
                }
            }
            .animation(.snappy(duration: 0.22), value: size)

        if isEditingWidgets {
            tile
                .draggable(widget.rawValue)
                .dropDestination(for: String.self) { droppedItems, _ in
                    guard let rawValue = droppedItems.first,
                          let draggedWidget = DashboardWidget(rawValue: rawValue)
                    else {
                        return false
                    }
                    model.moveWidget(draggedWidget, before: widget)
                    return true
                }
        } else {
            tile
        }
    }

    @ViewBuilder
    private func widgetContent(_ widget: DashboardWidget, size: WidgetSizePreset) -> some View {
        switch widget {
        case .weather:
            WeatherWidget(weather: model.weather, contentHeight: size.weatherContentHeight, state: model.widgetState(for: .weather))
        case .systemResources:
            SystemResourcesWidget(contentHeight: size.cardContentHeight)
        case .nowPlaying:
            MediaWidget(model: model, contentHeight: size.cardContentHeight)
        case .photos:
            PhotosWidget(contentHeight: size.cardContentHeight)
        case .stickyNotes:
            StickyNotesWidget(contentHeight: size.cardContentHeight)
        case .watchlist:
            WatchlistWidget(contentHeight: size.cardContentHeight)
        case .date:
            DateWidget(contentHeight: size.cardContentHeight)
        case .systemRings:
            SystemRingsWidget(
                cpuPercent: model.systemMetrics?.cpu.usagePercent ?? 0,
                memoryPercent: model.systemMetrics?.memory.usagePercent ?? 0,
                diskPercent: model.systemMetrics?.disk.usagePercent ?? 0,
                batteryLevel: model.systemStatus.batteryLevel,
                processCount: model.totalProcessCount,
                contentHeight: size.cardContentHeight,
                state: model.widgetState(for: .systemRings)
            )
        case .network:
            NetworkWidget(
                downBytesPerSecond: model.systemMetrics?.network.bytesInPerSecond ?? 0,
                upBytesPerSecond: model.systemMetrics?.network.bytesOutPerSecond ?? 0,
                peakDownBytesPerSecond: UInt64(model.networkPeakIn),
                peakUpBytesPerSecond: UInt64(model.networkPeakOut),
                contentHeight: size.cardContentHeight
            )
        }
    }
}


struct WidgetCard<Content: View>: View {
    let title: String
    let symbol: String
    let tint: Color
    let minContentHeight: CGFloat
    let content: Content
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @Environment(\.widgetOutline) private var widgetOutline

    init(
        title: String,
        symbol: String,
        tint: Color = .blue,
        minContentHeight: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.minContentHeight = minContentHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.primary.opacity(0.84))
                Spacer(minLength: 0)
            }

            content
                .frame(maxWidth: .infinity, minHeight: minContentHeight, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency),
            in: RoundedRectangle(cornerRadius: surfaceStyle == .windowsXP ? 9 : (surfaceStyle == .classic98 ? 2 : 15), style: .continuous)
        )
        .overlay {
            if widgetOutline.showsBorder {
                RoundedRectangle(cornerRadius: surfaceStyle == .windowsXP ? 9 : (surfaceStyle == .classic98 ? 2 : 15), style: .continuous)
                    .strokeBorder(
                        surfaceStyle == .classic98 ? Color.white : (surfaceStyle == .neumorphism ? Color.black.opacity(0.035) : Color.white.opacity(0.9)),
                        lineWidth: surfaceStyle == .classic98 ? 2 : widgetOutline.width
                    )
            }
        }
        .shadow(color: .black.opacity(surfaceStyle == .glassmorphism ? 0.035 : 0.09), radius: surfaceStyle == .claymorphism ? 12 : 8, x: 0, y: surfaceStyle == .neumorphism ? 2 : 4)
        .shadow(color: .white.opacity(surfaceStyle == .neumorphism ? 0.75 : 0), radius: 5, x: -3, y: -3)
        .aeroSheen()
    }
}
