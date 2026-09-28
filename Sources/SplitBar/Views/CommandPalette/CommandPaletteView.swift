import AppKit
import Foundation
import SwiftUI

public enum CommandPaletteCategory: String, CaseIterable, Sendable {
    case quickActions = "Quick Actions"
    case windowManagement = "Window Management"
    case widgets = "SplitBar Widgets"
    case applications = "Applications"
    case ai = "Local AI (Ollama)"
}

public struct CommandPaletteItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconSystemName: String
    public let iconColor: Color
    public let category: CommandPaletteCategory
    public let action: @MainActor () -> Void

    public init(
        id: String,
        title: String,
        subtitle: String,
        iconSystemName: String,
        iconColor: Color,
        category: CommandPaletteCategory,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.category = category
        self.action = action
    }
}

public struct CommandPaletteView: View {
    public let items: [CommandPaletteItem]
    public let onExecuteAIQuery: (String) async -> String
    public let onClose: () -> Void

    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    @State private var aiResponse: String?
    @State private var isAILoading: Bool = false

    public init(
        items: [CommandPaletteItem],
        onExecuteAIQuery: @escaping (String) async -> String,
        onClose: @escaping () -> Void
    ) {
        self.items = items
        self.onExecuteAIQuery = onExecuteAIQuery
        self.onClose = onClose
    }

    private var filteredItems: [CommandPaletteItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return items
        }
        return items.filter { item in
            item.title.lowercased().contains(query) ||
            item.subtitle.lowercased().contains(query) ||
            item.category.rawValue.lowercased().contains(query)
        }
    }

    private var isAIMode: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("?") || trimmed.lowercased().hasPrefix("ai:")
    }

    public var body: some View {
        VStack(spacing: 0.0) {
            // Search Bar Header
            HStack(spacing: 12.0) {
                Image(systemName: isAIMode ? "sparkles" : "magnifyingglass")
                    .font(.system(size: 18.0, weight: .semibold))
                    .foregroundColor(isAIMode ? .purple : .secondary)

                TextField(
                    isAIMode ? "Ask Ollama AI anything..." : "Search commands, apps, widgets, or window tiling (? for AI)...",
                    text: $searchText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 15.0, weight: .regular))
                .onSubmit {
                    handleReturnKey()
                }
                .onChange(of: searchText) { _, _ in
                    // Filtre değişince seçim görünür ilk sonuca döner; aksi halde Enter görünmeyen bir öğeyi çalıştırabilir
                    selectedIndex = 0
                }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        aiResponse = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }

                Button(action: onClose) {
                    Text("esc")
                        .font(.system(size: 11.0, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 2.0)
                        .background(
                            RoundedRectangle(cornerRadius: 4.0)
                                .fill(Color.primary.opacity(0.08))
                        )
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 14.0)
            .background(Color.primary.opacity(0.03))

            Divider()
                .opacity(0.4)

            // Content Area: AI Mode or Command List
            if isAIMode {
                aiSectionView
            } else {
                commandsListView
            }

            Divider()
                .opacity(0.4)

            // Footer
            HStack(spacing: 16.0) {
                HStack(spacing: 4.0) {
                    Text("↑↓")
                        .font(.system(size: 11.0, weight: .semibold, design: .monospaced))
                    Text("Navigate")
                        .font(.caption2)
                }
                HStack(spacing: 4.0) {
                    Text("↵")
                        .font(.system(size: 11.0, weight: .semibold, design: .monospaced))
                    Text(isAIMode ? "Ask AI" : "Run")
                        .font(.caption2)
                }
                HStack(spacing: 4.0) {
                    Text("? <query>")
                        .font(.system(size: 11.0, weight: .semibold, design: .monospaced))
                    Text("Local AI")
                        .font(.caption2)
                }
                Spacer()
                Text("SplitBar Command Center")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 580.0, height: 420.0)
        .liquidGlassSurface(cornerRadius: 22.0, tintColor: nil, isHovered: false)
        .clipShape(RoundedRectangle(cornerRadius: 22.0, style: .continuous))
        .onKeyPress(.downArrow) {
            let count = filteredItems.count
            if count > 0 {
                selectedIndex = (selectedIndex + 1) % count
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            let count = filteredItems.count
            if count > 0 {
                selectedIndex = (selectedIndex - 1 + count) % count
            }
            return .handled
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }

    private var aiSectionView: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: 8.0) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Local AI Prompt (Ollama)")
                    .font(.system(size: 13.0, weight: .semibold))
                Spacer()
                if isAILoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let response = aiResponse {
                ScrollView {
                    Text(response)
                        .font(.system(size: 13.0))
                        .lineSpacing(4.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12.0)
                        .background(
                            RoundedRectangle(cornerRadius: 10.0)
                                .fill(Color.primary.opacity(0.04))
                        )
                }
            } else if isAILoading {
                VStack(spacing: 8.0) {
                    ProgressView()
                    Text("Generating on Apple Silicon neural engines...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 6.0) {
                    Text("Press Enter (↵) to query your active local Ollama model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("SplitBar connects directly to http://127.0.0.1:11434 with zero cloud transmission.")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16.0)
        .frame(maxHeight: .infinity)
    }

    private var commandsListView: some View {
        let results = filteredItems
        return Group {
            if results.isEmpty {
                VStack(spacing: 8.0) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28.0))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No matching commands found")
                        .font(.system(size: 14.0, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2.0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                                commandRow(item: item, isSelected: selectedIndex == index)
                                    .id(item.id)
                                    .onTapGesture {
                                        item.action()
                                        onClose()
                                    }
                            }
                        }
                        .padding(.vertical, 6.0)
                        .padding(.horizontal, 8.0)
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if newIndex >= 0 && newIndex < results.count {
                            proxy.scrollTo(results[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func commandRow(item: CommandPaletteItem, isSelected: Bool) -> some View {
        HStack(spacing: 12.0) {
            Image(systemName: item.iconSystemName)
                .font(.system(size: 16.0))
                .foregroundColor(item.iconColor)
                .frame(width: 28.0, height: 28.0)
                .background(
                    RoundedRectangle(cornerRadius: 6.0)
                        .fill(item.iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2.0) {
                Text(item.title)
                    .font(.system(size: 13.0, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(item.subtitle)
                    .font(.system(size: 11.0))
                    .foregroundColor(isSelected ? Color.white.opacity(0.7) : .secondary)
            }

            Spacer()

            Text(item.category.rawValue)
                .font(.system(size: 10.0, weight: .semibold))
                .padding(.horizontal, 6.0)
                .padding(.vertical, 2.0)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.06))
                )
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .padding(.horizontal, 10.0)
        .padding(.vertical, 6.0)
        .background(
            RoundedRectangle(cornerRadius: 8.0)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .pointingHandCursor()
    }

    private func handleReturnKey() {
        if isAIMode {
            let prompt = searchText.hasPrefix("?")
                ? String(searchText.dropFirst()).trimmingCharacters(in: .whitespaces)
                : String(searchText.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            guard !prompt.isEmpty else { return }
            isAILoading = true
            aiResponse = nil
            Task {
                let response = await onExecuteAIQuery(prompt)
                await MainActor.run {
                    self.aiResponse = response
                    self.isAILoading = false
                }
            }
        } else {
            let results = filteredItems
            if selectedIndex >= 0 && selectedIndex < results.count {
                results[selectedIndex].action()
                onClose()
            }
        }
    }
}
