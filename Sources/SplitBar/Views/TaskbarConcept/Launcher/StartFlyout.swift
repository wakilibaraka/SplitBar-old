import AppKit
import SwiftUI

struct StartFlyout: View {
    private var shellRadius: CGFloat { model.shellRadius(for: .flyouts) }
    let onClose: () -> Void
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    @State private var isEditingPins = false
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private var apps: [LauncherApp] { LauncherDefaults.apps }

    private var folders: [LauncherFolder] { LauncherDefaults.folders }

    private var filteredCatalogApps: [ApplicationDescriptor] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return catalogApps }
        return catalogApps.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    private func loadCatalog() async {
        guard catalogApps.isEmpty else { return }
        let scanned = await Task.detached(priority: .userInitiated) {
            ApplicationCatalogService().scan(directories: ApplicationCatalogService.catalogDirectories())
        }.value
        catalogApps = scanned
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.system(size: 14, weight: .semibold))
            if !model.recentAppIDs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.recentAppIDs, id: \.self) { bundleID in
                            recentAppCell(bundleID)
                        }
                    }
                }
            }
            if !model.recentFolderTitles.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(model.recentFolderTitles.filter({ title in folders.contains(where: { $0.title == title }) }), id: \.self) { title in
                        if let folder = folders.first(where: { $0.title == title }) {
                            folderCell(folder)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func recentAppTitle(_ bundleID: String) -> String {
        if let known = apps.first(where: { $0.bundleIdentifier == bundleID }) {
            return known.title
        }
        if let scanned = catalogApps.first(where: { $0.bundleIdentifier == bundleID }) {
            return scanned.displayName
        }
        return bundleID
    }

    private func recentAppCell(_ bundleID: String) -> some View {
        Button {
            onLaunchApplication(bundleID)
        } label: {
            VStack(spacing: 6) {
                MacOSAppIcon(
                    bundleIdentifier: bundleID,
                    fallbackSymbol: "app.fill",
                    fallbackColor: .secondary,
                    size: 30
                )
                .frame(width: 46, height: 46)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 13))
                Text(recentAppTitle(bundleID))
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .help(recentAppTitle(bundleID))
    }

    private var allAppsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All apps")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(filteredCatalogApps.count) apps")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            if catalogApps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if filteredCatalogApps.isEmpty {
                Text("No apps match your search.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(filteredCatalogApps) { app in
                        catalogAppCell(app)
                    }
                }
            }
        }
        .padding(.top, 4)
        .task {
            await loadCatalog()
        }
    }

    private func pinnedCell(_ app: LauncherApp) -> some View {
        Button {
            if isEditingPins {
                model.setPinned(app.bundleIdentifier, isPinned: false)
            } else {
                onLaunchApplication(app.bundleIdentifier)
            }
        } label: {            VStack(spacing: 8) {
                MacOSAppIcon(
                    bundleIdentifier: app.bundleIdentifier,
                    fallbackSymbol: app.symbol,
                    fallbackColor: app.color,
                    size: 34
                )
                .frame(width: 54, height: 54)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 15))
                Text(app.title).font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if isEditingPins {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .draggable(app.bundleIdentifier)
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let draggedID = droppedItems.first else { return false }
            model.movePinned(draggedID, before: app.bundleIdentifier)
            return true
        }
    }

    private func pinEditCell(_ app: LauncherApp) -> some View {        let isPinned = model.pinnedAppBundleIDs.contains(app.bundleIdentifier)
        return Button {
            model.setPinned(app.bundleIdentifier, isPinned: !isPinned)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isPinned ? "pin.fill" : "plus")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isPinned ? accent : .secondary)
                Text(app.title)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!isPinned && model.pinnedAppBundleIDs.count >= 8)
        .opacity(!isPinned && model.pinnedAppBundleIDs.count >= 8 ? 0.45 : 1)
    }
    private func folderCell(_ folder: LauncherFolder) -> some View {
        Button {
            if let url = folder.url {
                NSWorkspace.shared.open(url)
                model.recordFolderOpen(folder.title)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: folder.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(folder.tint)
                    .frame(width: 26, height: 26)
                    .background(folder.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(folder.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 42)
            .background(
                Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.05),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

        private func catalogAppCell(_ app: ApplicationDescriptor) -> some View {
        Button {
            onLaunchApplication(app.bundleIdentifier)
        } label: {
            VStack(spacing: 8) {
                MacOSAppIcon(
                    bundleIdentifier: app.bundleIdentifier,
                    fallbackSymbol: "app.fill",
                    fallbackColor: .secondary,
                    size: 34
                )
                .frame(width: 54, height: 54)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 15))
                Text(app.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 26)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .help(app.displayName)
    }

    @State private var userIdentity = UserIdentityService.currentIdentity()
    @State private var userAvatar: NSImage?
    @State private var pendingPowerAction: SystemPowerAction?
    @State private var powerErrorMessage: String?
    @State private var searchQuery = ""
    @State private var catalogApps: [ApplicationDescriptor] = []

    private var launcherFooter: some View {
        HStack {
            HStack(spacing: 10) {
                if let userAvatar {
                    Image(nsImage: userAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Text(userIdentity.initials)
                                .font(.system(size: 11, weight: .semibold))
                        }
                }
                Text(userIdentity.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                model.openPanel = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .help("Open Personalisation")
            powerMenu
        }
        .onAppear {
            userAvatar = UserIdentityService.avatarImage(for: userIdentity)
        }
        .confirmationDialog(
            powerConfirmationTitle,
            isPresented: Binding(
                get: { pendingPowerAction != nil },
                set: { if !$0 { pendingPowerAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive) {
                if let action = pendingPowerAction {
                    pendingPowerAction = nil
                    runPowerAction(action)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPowerAction = nil
            }
        } message: {
            Text("This uses macOS Automation and may ask for permission first.")
        }
        .alert("Couldn't complete the action", isPresented: Binding(
            get: { powerErrorMessage != nil },
            set: { if !$0 { powerErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(powerErrorMessage ?? "")
        }
    }

    private var powerConfirmationTitle: String {
        switch pendingPowerAction {
        case .restart: "Restart this Mac now?"
        case .shutDown: "Shut down this Mac now?"
        case .logOut: "Log out now?"
        case .lock, .sleep, .none: "Continue?"
        }
    }

    private var powerMenu: some View {
        Menu {
            Button {
                runPowerAction(.lock)
            } label: {
                Label("Lock", systemImage: "lock.fill")
            }
            Button {
                runPowerAction(.sleep)
            } label: {
                Label("Sleep", systemImage: "moon.zzz.fill")
            }
            Divider()
            Button {
                pendingPowerAction = .restart
            } label: {
                Label("Restart…", systemImage: "arrow.clockwise")
            }
            Button {
                pendingPowerAction = .shutDown
            } label: {
                Label("Shut Down…", systemImage: "power")
            }
            Button {
                pendingPowerAction = .logOut
            } label: {
                Label("Log Out…", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "power")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 10))
        }
        .menuStyle(.borderlessButton)
        .help("Power options")
    }

    private func runPowerAction(_ action: SystemPowerAction) {
        performSystemPowerAction(action) { result in
            if case .failure(let error) = result {
                powerErrorMessage = error.description
            }
        }
    }

    private var pinnedApps: [LauncherApp] {
        model.pinnedAppBundleIDs.compactMap { bundleID in
            apps.first { $0.bundleIdentifier == bundleID }
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(accent)
                TextField("Search apps, settings and files", text: $searchQuery)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                if searchQuery.isEmpty {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), in: Capsule())

            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Pinned")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Button(isEditingPins ? "Done" : "Edit") {
                            isEditingPins.toggle()
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(accent)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 19) {
                        ForEach(Array(pinnedApps.prefix(4))) { app in
                            pinnedCell(app)
                        }
                    }

                    Toggle("Show only 4 pinned apps", isOn: $model.showOnlyFourPinned)
                        .toggleStyle(.switch)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.top, 2)

                    if !model.recentAppIDs.isEmpty || !model.recentFolderTitles.isEmpty {
                        recentSection
                    }

                    if !isEditingPins && !model.showOnlyFourPinned {
                        allAppsSection
                    }

                    if isEditingPins {
                        HStack {
                            Text("All apps")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("\(model.pinnedAppBundleIDs.count) of 8 pinned")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(apps) { app in
                                pinEditCell(app)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 13) {
                    LauncherBackgroundAppsCard()

                    HStack {
                        Text("Folders")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(folders) { folder in
                            folderCell(folder)
                        }
                    }

                    LauncherProcessesCard(processes: model.topProcesses)

                    Spacer(minLength: 0)
                }
                .frame(width: 250, alignment: .leading)
                }
            }
            .scrollIndicators(.hidden)

            launcherFooter
        }
        .padding(25)
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }
}
