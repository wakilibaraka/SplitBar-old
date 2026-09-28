import SwiftUI

public struct QuickNotesFlyoutView: View {
    public let initialText: String
    public let onSave: (String) -> Void
    public let onCopyAll: (String) -> Void

    @State private var noteText: String
    @State private var showCopiedAlert: Bool = false
    @State private var isConfirmingClear: Bool = false

    public init(
        initialText: String,
        onSave: @escaping (String) -> Void,
        onCopyAll: @escaping (String) -> Void
    ) {
        self.initialText = initialText
        self.onSave = onSave
        self.onCopyAll = onCopyAll
        self._noteText = State(initialValue: initialText)
    }

    private var wordCount: Int {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    public var body: some View {
        VStack(spacing: 10.0) {
            // Header Bar
            HStack {
                Label("Scratchpad", systemImage: "note.text")
                    .font(.system(size: 13.0, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    onCopyAll(noteText)
                    showCopiedAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showCopiedAlert = false
                    }
                }) {
                    HStack(spacing: 4.0) {
                        Image(systemName: showCopiedAlert ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11.0))
                        Text(showCopiedAlert ? "Copied!" : "Copy")
                            .font(.system(size: 11.0, weight: .medium))
                    }
                    .foregroundColor(showCopiedAlert ? .green : .secondary)
                    .padding(.horizontal, 8.0)
                    .padding(.vertical, 3.5)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(6.0)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()

                Button(action: {
                    isConfirmingClear = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11.0))
                        .foregroundColor(.secondary)
                        .padding(5.0)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .disabled(noteText.isEmpty)
                .help("Clear Scratchpad")
                .accessibilityLabel("Clear Scratchpad")
                .confirmationDialog(
                    "Clear the entire scratchpad?",
                    isPresented: $isConfirmingClear
                ) {
                    Button("Clear", role: .destructive) {
                        noteText = ""
                        onSave("")
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This cannot be undone.")
                }
            }

            // Editor
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text("Type quick thoughts, code snippets, or draft notes here...\nAutosaves instantly.")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 6.0)
                        .padding(.vertical, 8.0)
                }

                TextEditor(text: $noteText)
                    .font(.system(size: 12.5, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: noteText) { _, newValue in
                        onSave(newValue)
                    }
            }
            .padding(8.0)
            .liquidGlassCard(cornerRadius: 12.0, isHovered: false)

            // Footer
            HStack {
                Text("\(wordCount) words · \(noteText.count) characters")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4.0) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6.0, height: 6.0)
                    Text("Saved locally")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minHeight: 280.0)
    }
}
