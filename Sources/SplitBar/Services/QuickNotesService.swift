import Foundation
import OSLog

@MainActor
public final class QuickNotesService {
    private let fileURL: URL

    public init(baseURL: URL) {
        self.fileURL = baseURL.appendingPathComponent("quick_notes.txt")
    }

    public func loadNotes() -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ""
        }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            Logger.persistence.error("Failed to load quick notes: \(error.localizedDescription)")
            return ""
        }
    }

    public func saveNotes(_ text: String) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            Logger.persistence.error("Failed to save quick notes: \(error.localizedDescription)")
        }
    }
}
