import AppKit
import SwiftUI

public struct ClipboardHistoryView: View {
    public let history: [ClipboardEntry]
    public let onCopy: (ClipboardEntry) -> Void
    public let onTogglePin: (UUID) -> Void
    public let onDelete: (UUID) -> Void
    public let onClearUnpinned: () -> Void
    public let onClearAll: () -> Void

    @State private var searchQuery: String = ""
    @State private var showingClearConfirmation: Bool = false

    public init(
        history: [ClipboardEntry],
        onCopy: @escaping (ClipboardEntry) -> Void,
        onTogglePin: @escaping (UUID) -> Void,
        onDelete: @escaping (UUID) -> Void,
        onClearUnpinned: @escaping () -> Void,
        onClearAll: @escaping () -> Void
    ) {
        self.history = history
        self.onCopy = onCopy
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
        self.onClearUnpinned = onClearUnpinned
        self.onClearAll = onClearAll
    }

    private var filteredHistory: [ClipboardEntry] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return history
        }
        return history.filter { $0.searchableText.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        VStack(spacing: 10.0) {
            TextField("Search clipboard...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)

            if filteredHistory.isEmpty {
                VStack(spacing: 8.0) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 28.0))
                        .foregroundColor(.secondary)
                    Text("No clipboard entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6.0) {
                        ForEach(filteredHistory) { entry in
                            entryRow(entry: entry)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button("Clear Unpinned") {
                    onClearUnpinned()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
                .pointingHandCursor()

                Spacer()

                Button("Clear All") {
                    showingClearConfirmation = true
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
                .pointingHandCursor()
                .confirmationDialog(
                    "Are you sure you want to clear all clipboard history including pinned items?",
                    isPresented: $showingClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All History", role: .destructive) {
                        onClearAll()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(12.0)
    }

    private func entryRow(entry: ClipboardEntry) -> some View {
        HStack(spacing: 10.0) {
            payloadIcon(for: entry.payload)
                .foregroundColor(.accentColor)
                .frame(width: 20.0)

            VStack(alignment: .leading, spacing: 2.0) {
                Text(entry.searchableText)
                    .font(.system(size: 12.0))
                    .lineLimit(2)

                Text(formattedTimestamp(entry.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                onTogglePin(entry.id)
            }) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .accessibilityLabel(entry.isPinned ? "Unpin Entry" : "Pin Entry")
                    .font(.system(size: 11.0))
                    .foregroundColor(entry.isPinned ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Button(action: {
                onCopy(entry)
            }) {
                Image(systemName: "doc.on.doc")
                    .accessibilityLabel("Copy Entry")
                    .font(.system(size: 11.0))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Button(action: {
                onDelete(entry.id)
            }) {
                Image(systemName: "trash")
                    .accessibilityLabel("Delete Entry")
                    .font(.system(size: 11.0))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.horizontal, 8.0)
        .padding(.vertical, 6.0)
        .liquidGlassCard(cornerRadius: 12.0, isHovered: false)
        .contentShape(Rectangle())
        .pointingHandCursor()
        .onTapGesture {
            onCopy(entry)
        }
    }

    private func payloadIcon(for payload: ClipboardPayloadDescriptor) -> Image {
        switch payload {
        case .text:
            return Image(systemName: "text.alignleft")
        case .url:
            return Image(systemName: "link")
        case .imageBlob:
            return Image(systemName: "photo")
        case .fileURLs:
            return Image(systemName: "folder")
        }
    }

    private static let relativeTimestampFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private func formattedTimestamp(_ date: Date) -> String {
        Self.relativeTimestampFormatter.localizedString(for: date, relativeTo: Date())
    }
}
