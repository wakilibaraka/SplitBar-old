import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct EdgeDockView: View {
    public let viewState: DockViewState
    public let materialStyle: DockMaterialStyle
    public let reduceMotion: Bool
    public let autoHide: Bool
    public let onAction: (AppAction) -> Void
    public let onOpenAddPanel: () -> Void
    public let onSelectTheme: (DockMaterialStyle) -> Void
    public let onToggleAutoHide: () -> Void
    public let onShowAppWindows: (String, String, URL?) -> Void
    public let iconBaseSize: CGFloat
    public let onUpdateIconSize: (Double) -> Void

    @State private var draggingItemID: UUID? = nil
    @State private var dragOffset: CGFloat = 0.0
    /// Sürükleme bırakıldığında düğmenin tıklama eylemi de tetiklenir; bu süre boyunca tıklama yok sayılır.
    @State private var suppressTapUntil: Date = .distantPast
    /// Sıralama değişince SwiftUI hareketi `onEnded` çağırmadan iptal edebilir; GestureState her durumda sıfırlanır.
    @GestureState private var isDragGestureActive: Bool = false

    public init(
        viewState: DockViewState,
        onAction: @escaping (AppAction) -> Void
    ) {
        self.viewState = viewState
        self.materialStyle = .system
        self.reduceMotion = false
        self.autoHide = false
        self.iconBaseSize = 46.0
        self.onAction = onAction
        self.onOpenAddPanel = {}
        self.onSelectTheme = { _ in }
        self.onToggleAutoHide = {}
        self.onShowAppWindows = { _, _, _ in }
        self.onUpdateIconSize = { _ in }
    }

    public init(
        viewState: DockViewState,
        materialStyle: DockMaterialStyle,
        reduceMotion: Bool,
        onAction: @escaping (AppAction) -> Void,
        onOpenAddPanel: @escaping () -> Void
    ) {
        self.viewState = viewState
        self.materialStyle = materialStyle
        self.reduceMotion = reduceMotion
        self.autoHide = false
        self.iconBaseSize = 46.0
        self.onAction = onAction
        self.onOpenAddPanel = onOpenAddPanel
        self.onSelectTheme = { _ in }
        self.onToggleAutoHide = {}
        self.onShowAppWindows = { _, _, _ in }
        self.onUpdateIconSize = { _ in }
    }

    public init(
        viewState: DockViewState,
        materialStyle: DockMaterialStyle,
        reduceMotion: Bool,
        autoHide: Bool,
        iconBaseSize: CGFloat,
        onAction: @escaping (AppAction) -> Void,
        onOpenAddPanel: @escaping () -> Void,
        onSelectTheme: @escaping (DockMaterialStyle) -> Void,
        onToggleAutoHide: @escaping () -> Void,
        onShowAppWindows: @escaping (String, String, URL?) -> Void,
        onUpdateIconSize: @escaping (Double) -> Void
    ) {
        self.viewState = viewState
        self.materialStyle = materialStyle
        self.reduceMotion = reduceMotion
        self.autoHide = autoHide
        self.iconBaseSize = iconBaseSize
        self.onAction = onAction
        self.onOpenAddPanel = onOpenAddPanel
        self.onSelectTheme = onSelectTheme
        self.onToggleAutoHide = onToggleAutoHide
        self.onShowAppWindows = onShowAppWindows
        self.onUpdateIconSize = onUpdateIconSize
    }

    @Environment(\.colorScheme) private var colorScheme

    private var dockBackground: some View {
        ThemedGlassBackground(style: materialStyle, cornerRadius: 22.0)
    }

    private func animationPolicy(reduceMotion: Bool) -> DockAnimationPolicy {
        if reduceMotion {
            return .reducedMotion(duration: 0.15)
        }
        return .spring(response: 0.18, dampingFraction: 0.76)
    }

    private func shouldInsertDivider(prev: DockItemViewState, curr: DockItemViewState) -> Bool {
        switch (prev.kind, curr.kind) {
        case (.application, .widget), (.application, .link):
            return true
        case (.link, .widget), (.widget, .application), (.link, .application):
            return true
        default:
            return false
        }
    }

    private func handleDroppedURL(url: URL) {
        if url.pathExtension.lowercased() == "app" {
            let bundleID = Bundle(url: url)?.bundleIdentifier ?? ("custom." + url.deletingPathExtension().lastPathComponent.lowercased())
            let appName = FileManager.default.displayName(atPath: url.path)
            let newItem = DockItem(
                id: UUID(),
                name: appName,
                kind: .application(bundleIdentifier: bundleID, applicationURL: url)
            )
            onAction(.addItem(newItem))
        } else if url.scheme == "http" || url.scheme == "https" {
            let name = url.host ?? "Web Link"
            let newItem = DockItem(
                id: UUID(),
                name: name,
                kind: .link(url: url)
            )
            onAction(.addItem(newItem))
        } else {
            let fileName = FileManager.default.displayName(atPath: url.path)
            let newItem = DockItem(
                id: UUID(),
                name: fileName,
                kind: .application(bundleIdentifier: "file." + url.lastPathComponent, applicationURL: url)
            )
            onAction(.addItem(newItem))
        }
    }

    private func handleDrop(providers: [NSItemProvider], destinationItemID: UUID?) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        self.handleDroppedURL(url: url)
                    }
                }
                return true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        self.handleDroppedURL(url: url)
                    }
                }
                return true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let string = string as? String,
                          let sourceID = UUID(uuidString: string),
                          let destID = destinationItemID else {
                        return
                    }
                    DispatchQueue.main.async {
                        onAction(.moveItem(sourceID: sourceID, destinationID: destID))
                    }
                }
                return true
            }
        }
        return false
    }

    private func itemRow(item: DockItemViewState) -> some View {
        let isBeingDragged = draggingItemID == item.id
        return DockItemView(
            item: item,
            edge: viewState.edge,
            animationPolicy: animationPolicy(reduceMotion: reduceMotion),
            iconBaseSize: iconBaseSize,
            isTapSuppressed: {
                // Her sürükleme hareketi engeli uzatır; hareket iptal edilse bile engel kısa sürede kendiliğinden kalkar
                Date() < suppressTapUntil
            },
            onSelect: {},
            onActivate: {
                onAction(.selectItem(id: item.id))
            },
            onRemove: {
                onAction(.removeItem(id: item.id))
            },
            onChangeEdge: { newEdge in
                onAction(.updatePlacement(DockPlacement(edge: newEdge, verticalOffsetFraction: 0.5, autoHide: autoHide)))
            },
            onShowWindows: {
                if case .application(let bundleID, let appURL) = item.kind {
                    onShowAppWindows(item.name, bundleID, appURL)
                }
            }
        )
        .offset(
            x: (viewState.edge == .top && isBeingDragged) ? dragOffset : 0.0,
            y: (viewState.edge != .top && isBeingDragged) ? dragOffset : 0.0
        )
        .scaleEffect(isBeingDragged ? 1.14 : 1.0)
        .zIndex(isBeingDragged ? 100.0 : 1.0)
        .shadow(
            color: Color.black.opacity(isBeingDragged ? 0.50 : 0.0),
            radius: 12.0,
            x: 0.0,
            y: 5.0
        )
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DockItemFramesPreferenceKey.self,
                    value: [
                        DockItemFramePreferenceData(
                            id: item.id,
                            frame: proxy.frame(in: .named("DockContainer"))
                        )
                    ]
                )
            }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 7.0, coordinateSpace: .local)
                .updating($isDragGestureActive) { _, isActive, _ in
                    isActive = true
                }
                .onChanged { gesture in
                    suppressTapUntil = Date().addingTimeInterval(0.35)
                    if draggingItemID == nil {
                        draggingItemID = item.id
                        dragOffset = 0.0
                    }
                    let translation = viewState.edge == .top ? gesture.translation.width : gesture.translation.height
                    dragOffset = translation

                    let threshold: CGFloat = 38.0
                    if translation > threshold {
                        if let currentIndex = viewState.items.firstIndex(where: { $0.id == item.id }),
                           currentIndex + 1 < viewState.items.count {
                            let nextItem = viewState.items[currentIndex + 1]
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                onAction(.moveItem(sourceID: item.id, destinationID: nextItem.id))
                            }
                            dragOffset -= threshold
                        }
                    } else if translation < -threshold {
                        if let currentIndex = viewState.items.firstIndex(where: { $0.id == item.id }),
                           currentIndex > 0 {
                            let prevItem = viewState.items[currentIndex - 1]
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                onAction(.moveItem(sourceID: item.id, destinationID: prevItem.id))
                            }
                            dragOffset += threshold
                        }
                    }
                }
                .onEnded { _ in
                    suppressTapUntil = Date().addingTimeInterval(0.35)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        draggingItemID = nil
                        dragOffset = 0.0
                    }
                }
        )
        .onDrop(of: [UTType.fileURL, UTType.url, UTType.text], isTargeted: nil) { providers in
            handleDrop(providers: providers, destinationItemID: item.id)
        }
        .onChange(of: isDragGestureActive) { _, isActive in
            // İptal edilen sürüklemede onEnded çağrılmaz; ikon büyütülmüş ve kaymış halde kalmasın
            guard !isActive, draggingItemID == item.id else { return }
            suppressTapUntil = Date().addingTimeInterval(0.35)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                draggingItemID = nil
                dragOffset = 0.0
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            onOpenAddPanel()
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.70), Color.white.opacity(0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
                Image(systemName: "plus")
                    .font(.system(size: 13.0, weight: .bold))
                    .foregroundColor(.primary.opacity(0.80))
            }
            .frame(width: max(26.0, iconBaseSize - 14.0), height: max(26.0, iconBaseSize - 14.0))
            .shadow(color: Color.black.opacity(0.15), radius: 4.0, x: 0.0, y: 2.0)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help("Add Items")
    }

    private var dockContextMenu: some View {
        Group {
            Button {
                onToggleAutoHide()
            } label: {
                HStack {
                    Text("Auto-Hide Dock")
                    if autoHide { Image(systemName: "checkmark") }
                }
            }

            Menu("Liquid Glass Theme") {
                ForEach(DockMaterialStyle.presets, id: \.self) { theme in
                    Button { onSelectTheme(theme) } label: {
                        HStack {
                            Text(theme.displayName)
                            if materialStyle == theme { Image(systemName: "checkmark") }
                        }
                    }
                }
            }

            Menu("Icon Size") {
                Button { onUpdateIconSize(38.0) } label: {
                    HStack {
                        Text("Small (38 pt)")
                        if iconBaseSize == 38.0 { Image(systemName: "checkmark") }
                    }
                }
                Button { onUpdateIconSize(46.0) } label: {
                    HStack {
                        Text("Medium (46 pt)")
                        if iconBaseSize == 46.0 { Image(systemName: "checkmark") }
                    }
                }
                Button { onUpdateIconSize(54.0) } label: {
                    HStack {
                        Text("Large (54 pt)")
                        if iconBaseSize == 54.0 { Image(systemName: "checkmark") }
                    }
                }
                Button { onUpdateIconSize(62.0) } label: {
                    HStack {
                        Text("Extra Large (62 pt)")
                        if iconBaseSize == 62.0 { Image(systemName: "checkmark") }
                    }
                }
            }

            Menu("Dock Position") {
                Button {
                    onAction(.updatePlacement(DockPlacement(edge: .left, verticalOffsetFraction: 0.5, autoHide: autoHide)))
                } label: {
                    HStack {
                        Text("Left Edge")
                        if viewState.edge == .left { Image(systemName: "checkmark") }
                    }
                }

                Button {
                    onAction(.updatePlacement(DockPlacement(edge: .right, verticalOffsetFraction: 0.5, autoHide: autoHide)))
                } label: {
                    HStack {
                        Text("Right Edge")
                        if viewState.edge == .right { Image(systemName: "checkmark") }
                    }
                }

                Button {
                    onAction(.updatePlacement(DockPlacement(edge: .top, verticalOffsetFraction: 0.5, autoHide: autoHide)))
                } label: {
                    HStack {
                        Text("Top Edge")
                        if viewState.edge == .top { Image(systemName: "checkmark") }
                    }
                }
            }

            Divider()

            Button {
                onOpenAddPanel()
            } label: {
                Label("Add Items / Widgets...", systemImage: "plus.circle")
            }
        }
    }

    private var horizontalContent: some View {
        HStack(spacing: 6.0) {
            ForEach(Array(viewState.items.enumerated()), id: \.element.id) { index, item in
                if index > 0 && shouldInsertDivider(prev: viewState.items[index - 1], curr: item) {
                    Divider()
                        .frame(height: 26.0)
                        .overlay(Color.white.opacity(0.30))
                        .padding(.horizontal, 1.0)
                }

                itemRow(item: item)
            }

            Divider()
                .frame(height: 28.0)
                .overlay(Color.white.opacity(0.35))
                .padding(.horizontal, 2.0)

            addButton
        }
        .padding(.horizontal, 12.0)
        .padding(.vertical, 10.0)
        .background(dockBackground)
    }

    private var verticalContent: some View {
        VStack(spacing: 6.0) {
            ForEach(Array(viewState.items.enumerated()), id: \.element.id) { index, item in
                if index > 0 && shouldInsertDivider(prev: viewState.items[index - 1], curr: item) {
                    Divider()
                        .frame(width: 26.0)
                        .overlay(Color.white.opacity(0.30))
                        .padding(.vertical, 1.0)
                }

                itemRow(item: item)
            }

            Divider()
                .frame(width: 28.0)
                .overlay(Color.white.opacity(0.35))
                .padding(.vertical, 2.0)

            addButton
        }
        .padding(.vertical, 12.0)
        .padding(.horizontal, 10.0)
        .background(dockBackground)
    }

    public var body: some View {
        Group {
            if viewState.edge == .top {
                horizontalContent
            } else {
                verticalContent
            }
        }
        .contextMenu {
            dockContextMenu
        }
        .onDrop(of: [UTType.fileURL, UTType.url], isTargeted: nil) { providers in
            handleDrop(providers: providers, destinationItemID: nil)
        }
    }
}
