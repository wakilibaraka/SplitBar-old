import AppKit
import SwiftUI

public struct AddItemView: View {
    public let applications: [ApplicationDescriptor]
    public let state: AddItemState
    public let onAction: (AddItemAction) -> Void
    public let onAddApplication: (ApplicationDescriptor) -> Void
    public let onAddLink: (String) -> Void
    public let onAddWidget: (String, String) -> Void
    public let onClose: () -> Void

    @State private var linkInputText: String = ""
    @State private var linkTitleText: String = ""
    @State private var linkError: String? = nil
    @FocusState private var isSearchFocused: Bool
    /// Arka plan ikon yüklemesi bitince satırların önbellekten yeniden okunması için artırılır.
    @State private var iconsLoadedGeneration: Int = 0
    @FocusState private var isLinkURLFocused: Bool

    public init(
        applications: [ApplicationDescriptor],
        state: AddItemState,
        onAction: @escaping (AddItemAction) -> Void,
        onAddApplication: @escaping (ApplicationDescriptor) -> Void,
        onAddLink: @escaping (String) -> Void,
        onAddWidget: @escaping (String, String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.applications = applications
        self.state = state
        self.onAction = onAction
        self.onAddApplication = onAddApplication
        self.onAddLink = onAddLink
        self.onAddWidget = onAddWidget
        self.onClose = onClose
    }

    private var filteredApps: [ApplicationDescriptor] {
        filterApplications(applications: applications, query: state.searchQuery)
    }

    @Environment(\.dockMaterialStyle) private var dockMaterialStyle

    /// Koyu dock temalarında panel temanın yüzeyini kullanır; metinler beyaz olduğundan açık temalarda noir zemin korunur.
    @ViewBuilder
    private var panelBackground: some View {
        if dockMaterialStyle.prefersDarkContent {
            ThemedGlassBackground(style: dockMaterialStyle, cornerRadius: 24.0)
        } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24.0, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 24.0, style: .continuous)
                        .fill(Color(white: 0.05).opacity(0.92))

                    RoundedRectangle(cornerRadius: 24.0, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.0),
                                    .init(color: Color.white.opacity(0.18), location: 0.35),
                                    .init(color: Color.white.opacity(0.05), location: 0.70),
                                    .init(color: Color.white.opacity(0.30), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                }
        }
    }

    public var body: some View {
        VStack(spacing: 16.0) {
            // Header with Luxury Segmented Pill Switcher & Dismiss
            HStack(spacing: 12.0) {
                categorySegmentedBar

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11.0, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .frame(width: 28.0, height: 28.0)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8))
                        )
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            // Tab Content
            Group {
                if state.category == .apps {
                    appsView
                } else if state.category == .links {
                    linksView
                } else {
                    widgetsView
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(20.0)
        .frame(width: 440.0, height: 500.0)
        .background(panelBackground)
        .shadow(color: Color.black.opacity(0.60), radius: 30.0, x: 0.0, y: 12.0)
        // Arka plan her zaman koyu olduğundan sistem kontrolleri de koyu şemada çizilmeli
        .environment(\.colorScheme, .dark)
        .task(id: state.category) {
            // Yeni kategorinin alanı hiyerarşiye eklendikten sonra odaklanır; kategori yeniden
            // değişirse bu görev iptal edilir ve eski kategoriye odak verilmez
            do {
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                return
            }
            if state.category == .apps {
                isSearchFocused = true
            } else if state.category == .links {
                isLinkURLFocused = true
            }
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .onKeyPress(.return) {
            if state.category == .apps {
                let apps = filteredApps
                if let index = state.selectedIndex, index >= 0 && index < apps.count {
                    onAddApplication(apps[index])
                }
            } else if state.category == .links {
                submitLink()
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if state.category == .apps {
                onAction(.selectNext(resultCount: filteredApps.count))
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if state.category == .apps {
                onAction(.selectPrevious(resultCount: filteredApps.count))
            }
            return .handled
        }
    }

    // MARK: - Luxury Segmented Control

    private var categorySegmentedBar: some View {
        HStack(spacing: 4.0) {
            categoryButton(title: "Apps", category: .apps, icon: "square.stack.3d.up.fill")
            categoryButton(title: "Links", category: .links, icon: "link")
            categoryButton(title: "Widgets", category: .widgets, icon: "square.grid.2x2.fill")
        }
        .padding(3.5)
        .background(
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
                )
        )
    }

    private func categoryButton(title: String, category: AddItemCategory, icon: String) -> some View {
        let isSelected = state.category == category
        return Button(action: {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                onAction(.setCategory(category))
            }
        }) {
            HStack(spacing: 5.5) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: isSelected ? .bold : .regular))
                Text(title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))
            .padding(.horizontal, 14.0)
            .padding(.vertical, 6.5)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 9.0, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9.0, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 4.0, x: 0.0, y: 1.5)
                    } else {
                        Color.white.opacity(0.001)
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 9.0, style: .continuous))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    // MARK: - Apps View

    private var appsView: some View {
        VStack(spacing: 12.0) {
            // Search Bar
            HStack(spacing: 9.0) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13.0, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))

                TextField(
                    "Search installed applications...",
                    text: Binding(
                        get: { state.searchQuery },
                        set: { onAction(.setSearchQuery($0, resultCount: filteredApps.count)) }
                    )
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13.0, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .focused($isSearchFocused)

                if !state.searchQuery.isEmpty {
                    Button(action: {
                        onAction(.setSearchQuery("", resultCount: filteredApps.count))
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12.0))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 9.0)
            .background(
                RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                            .strokeBorder(Color.white.opacity(isSearchFocused ? 0.35 : 0.12), lineWidth: 0.8)
                    )
            )

            // App List
            let apps = filteredApps
            if apps.isEmpty {
                VStack(spacing: 8.0) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28.0))
                        .foregroundColor(Color.white.opacity(0.25))
                    Text("No applications found")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.50))
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6.0) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            appRow(app: app, index: index)
                        }
                    }
                    .padding(.vertical, 2.0)
                }
                // Tüm ikonlar panel açılır açılmaz arka planda yüklenir; kaydırma önbellekten okur
                .task(id: applications.count) {
                    await IconCache.shared.loadApplicationIcons(applications.map { (key: $0.bundleIdentifier, path: $0.applicationURL.path) })
                    iconsLoadedGeneration += 1
                }
            }
        }
    }

    private func appRow(app: ApplicationDescriptor, index: Int) -> some View {
        let isSelected = state.selectedIndex == index
        return HStack(spacing: 12.0) {
            // İkon henüz yüklenmediyse hafif yer tutucu gösterilir; senkron disk okuması kaydırmayı dondurur
            Group {
                if let icon = IconCache.shared.cachedImage(key: app.bundleIdentifier) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
            }
            .frame(width: 32.0, height: 32.0)
            .id(iconsLoadedGeneration)

            VStack(alignment: .leading, spacing: 2.0) {
                Text(app.displayName)
                    .font(.system(size: 13.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(app.bundleIdentifier)
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                onAddApplication(app)
            }) {
                HStack(spacing: 4.0) {
                    Image(systemName: "plus")
                        .font(.system(size: 10.0, weight: .bold))
                    Text("Add")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 11.0)
                .padding(.vertical, 5.5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8))
                )
                .contentShape(Capsule())
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12.0)
        .padding(.vertical, 7.5)
        .background(
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                        .strokeBorder(Color.white.opacity(isSelected ? 0.30 : 0.06), lineWidth: 0.8)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
        .pointingHandCursor()
        .onTapGesture {
            onAddApplication(app)
        }
    }

    // MARK: - Links View (Interactive & Luxury)

    private var linksView: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            // URL Input Field
            VStack(alignment: .leading, spacing: 6.0) {
                Text("Web Link URL")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.70))

                HStack(spacing: 9.0) {
                    Image(systemName: "globe")
                        .font(.system(size: 13.0))
                        .foregroundColor(Color.white.opacity(0.50))

                    TextField("https://example.com", text: $linkInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13.0, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .focused($isLinkURLFocused)

                    if !linkInputText.isEmpty {
                        Button(action: { linkInputText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12.0))
                                .foregroundColor(Color.white.opacity(0.50))
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                    }
                }
                .padding(.horizontal, 12.0)
                .padding(.vertical, 10.0)
                .background(
                    RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                                .strokeBorder(Color.white.opacity(isLinkURLFocused ? 0.40 : 0.12), lineWidth: 0.8)
                        )
                )
            }

            // Quick Popular Shortcuts Grid
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Quick Add Popular Sites")
                    .font(.system(size: 11.0, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))

                HStack(spacing: 8.0) {
                    quickLinkChip(title: "GitHub", url: "https://github.com", icon: "terminal.fill")
                    quickLinkChip(title: "YouTube", url: "https://youtube.com", icon: "play.rectangle.fill")
                    quickLinkChip(title: "ChatGPT", url: "https://chatgpt.com", icon: "sparkles")
                    quickLinkChip(title: "X", url: "https://x.com", icon: "bubble.left.and.bubble.right.fill")
                }

                HStack(spacing: 8.0) {
                    quickLinkChip(title: "Notion", url: "https://notion.so", icon: "doc.text.fill")
                    quickLinkChip(title: "Figma", url: "https://figma.com", icon: "square.on.square.dashed")
                    quickLinkChip(title: "Reddit", url: "https://reddit.com", icon: "antenna.radiowaves.left.and.right")
                    quickLinkChip(title: "Google", url: "https://google.com", icon: "magnifyingglass")
                }
            }
            .padding(.vertical, 2.0)

            if let error = linkError {
                HStack(spacing: 6.0) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11.0))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    Text(error)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                }
                .transition(.opacity)
            }

            Spacer()

            // Submit Button
            Button(action: submitLink) {
                HStack(spacing: 7.0) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13.0, weight: .semibold))
                    Text("Add Link to Dock")
                        .font(.system(size: 13.0, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11.0)
                .background(
                    RoundedRectangle(cornerRadius: 11.0, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.white.opacity(0.25), radius: 8.0, x: 0.0, y: 2.0)
                )
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.top, 4.0)
    }

    private func quickLinkChip(title: String, url: String, icon: String) -> some View {
        Button(action: {
            linkInputText = url
            submitLink()
        }) {
            HStack(spacing: 5.0) {
                Image(systemName: icon)
                    .font(.system(size: 10.5))
                Text(title)
                    .font(.system(size: 11.0, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color.white.opacity(0.85))
            .padding(.horizontal, 9.0)
            .padding(.vertical, 5.5)
            .background(
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.75)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func submitLink() {
        switch normalizedLink(raw: linkInputText) {
        case .success(let url):
            linkError = nil
            onAddLink(url.absoluteString)
            linkInputText = ""
        case .failure(let err):
            switch err {
            case .empty:
                linkError = "Please enter a valid link URL."
            case .invalidURL:
                linkError = "The provided URL is invalid."
            case .unsupportedScheme(let scheme):
                linkError = "Unsupported scheme '\(scheme)'. Only HTTP/HTTPS are supported."
            }
        }
    }

    // MARK: - Widgets View

    private var widgetsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8.0) {
                widgetLuxuryRow(
                    id: "clipboard",
                    title: "Clipboard History",
                    description: "Instant searchable clipboard stack & snippets"
                )
                widgetLuxuryRow(
                    id: "system_monitor",
                    title: "System Monitor",
                    description: "Real-time CPU, RAM, Disk & Network speeds"
                )
                widgetLuxuryRow(
                    id: "now_playing",
                    title: "Now Playing",
                    description: "Apple Music & Spotify real-time track controls"
                )
                widgetLuxuryRow(
                    id: "weather",
                    title: "Weather Forecast",
                    description: "Live conditions & hourly telemetry"
                )
                widgetLuxuryRow(
                    id: "bluetooth",
                    title: "Bluetooth Devices",
                    description: "Connected peripherals & battery levels"
                )
                widgetLuxuryRow(
                    id: "ai_usage",
                    title: "AI Activity & Agents",
                    description: "Claude, OpenAI, Codex & Ollama orchestration"
                )
                widgetLuxuryRow(
                    id: "quick_notes",
                    title: "Quick Scratchpad",
                    description: "Instant markdown note taking & drafts"
                )
            }
            .padding(.vertical, 2.0)
        }
    }

    private func widgetLuxuryRow(
        id: String,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 12.0) {
            WidgetIconView(identifier: id, size: 38.0)

            VStack(alignment: .leading, spacing: 2.0) {
                Text(title)
                    .font(.system(size: 13.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11.0, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.50))
            }

            Spacer()

            Button(action: {
                onAddWidget(id, title)
            }) {
                HStack(spacing: 4.0) {
                    Image(systemName: "plus")
                        .font(.system(size: 10.0, weight: .bold))
                    Text("Add")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 12.0)
                .padding(.vertical, 6.0)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8))
                )
                .contentShape(Capsule())
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.horizontal, 12.0)
        .padding(.vertical, 8.0)
        .background(
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
        .pointingHandCursor()
        .onTapGesture {
            onAddWidget(id, title)
        }
    }
}
