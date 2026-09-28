import AppKit
import Foundation

/// Panodan yakalanan girdi; resim girdileri için diske yazılması gereken PNG verisini de taşır.
public struct ClipboardCapture: Sendable {
    public let entry: ClipboardEntry
    public let imageData: Data?

    public init(entry: ClipboardEntry, imageData: Data?) {
        self.entry = entry
        self.imageData = imageData
    }
}

public final class ClipboardMonitor: @unchecked Sendable {
    private var lastChangeCount: Int
    private var timer: Timer?
    private var onNewEntry: ((ClipboardCapture) -> Void)?
    private var excludedBundleIdentifiers: Set<String> = []

    public init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    deinit {
        stopMonitoring()
    }

    public func startMonitoring(
        interval: TimeInterval,
        excludedBundleIdentifiers: Set<String>,
        onNewEntry: @escaping (ClipboardCapture) -> Void
    ) {
        self.onNewEntry = onNewEntry
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.checkPasteboard(excludedBundleIdentifiers: self.excludedBundleIdentifiers)
        }
    }

    /// Ayarlarda değişen hariç tutma listesini yeniden başlatma gerektirmeden uygular.
    public func updateExcludedBundleIdentifiers(_ identifiers: Set<String>) {
        self.excludedBundleIdentifiers = identifiers
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        onNewEntry = nil
    }

    public func checkPasteboard(excludedBundleIdentifiers: Set<String>) {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else {
            return
        }
        lastChangeCount = currentCount

        let frontmostID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard shouldCaptureClipboard(
            frontmostBundleIdentifier: frontmostID,
            excludedBundleIdentifiers: excludedBundleIdentifiers
        ) else {
            return
        }

        guard let capture = captureCandidate(pasteboard: pasteboard, sourceBundleID: frontmostID) else {
            return
        }

        onNewEntry?(capture)
    }

    private func captureCandidate(pasteboard: NSPasteboard, sourceBundleID: String?) -> ClipboardCapture? {
        // 1. File URLs
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true
        ]) as? [URL], !fileURLs.isEmpty {
            let names = fileURLs.map(\.lastPathComponent).joined(separator: ", ")
            return textCapture(ClipboardEntry(
                id: UUID(),
                timestamp: Date(),
                sourceBundleIdentifier: sourceBundleID,
                isPinned: false,
                searchableText: names,
                payload: .fileURLs(fileURLs)
            ))
        }

        // 2. Web URL
        if let urlString = pasteboard.string(forType: .URL),
           let url = URL(string: urlString),
           url.scheme == "http" || url.scheme == "https" {
            return textCapture(ClipboardEntry(
                id: UUID(),
                timestamp: Date(),
                sourceBundleIdentifier: sourceBundleID,
                isPinned: false,
                searchableText: urlString,
                payload: .url(url)
            ))
        }

        // 3. Image
        if let pngData = pngImageData(pasteboard: pasteboard), !pngData.isEmpty {
            let entryID = UUID()
            let byteCount = pngData.count
            let entry = ClipboardEntry(
                id: entryID,
                timestamp: Date(),
                sourceBundleIdentifier: sourceBundleID,
                isPinned: false,
                searchableText: "Image (\(ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)))",
                payload: .imageBlob(relativePath: "image_\(entryID.uuidString).png", byteCount: byteCount)
            )
            return ClipboardCapture(entry: entry, imageData: pngData)
        }

        // 4. Plain Text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return textCapture(ClipboardEntry(
                id: UUID(),
                timestamp: Date(),
                sourceBundleIdentifier: sourceBundleID,
                isPinned: false,
                searchableText: text,
                payload: .text(text)
            ))
        }

        return nil
    }

    private func textCapture(_ entry: ClipboardEntry) -> ClipboardCapture {
        ClipboardCapture(entry: entry, imageData: nil)
    }

    /// Panodaki resmi PNG olarak döndürür; yalnızca TIFF varsa PNG'ye dönüştürür.
    private func pngImageData(pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) {
            return png
        }
        guard let tiff = pasteboard.data(forType: .tiff) else {
            return nil
        }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }
}
