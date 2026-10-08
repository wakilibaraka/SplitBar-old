import AppKit
import Combine
import SwiftUI

final class AppIconStore: ObservableObject {
    static let shared = AppIconStore()

    @Published private(set) var icons: [String: NSImage] = [:]

    private let queue = DispatchQueue(label: "com.baraka.splitbar.appicon", qos: .userInitiated)
    private var resolved = Set<String>()

    private init() {}

    func icon(for bundleIdentifier: String) -> NSImage? {
        if let cached = icons[bundleIdentifier] {
            return cached
        }
        resolve(bundleIdentifier)
        return nil
    }

    private func resolve(_ bundleIdentifier: String) {
        guard resolved.insert(bundleIdentifier).inserted else { return }
        queue.async { [weak self] in
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
            let image = NSWorkspace.shared.icon(forFile: appURL.path)
            DispatchQueue.main.async {
                self?.icons[bundleIdentifier] = image
            }
        }
    }
}


final class TrashStore: ObservableObject {
    static let shared = TrashStore()

    @Published private(set) var isEmpty = true

    private let queue = DispatchQueue(label: "com.baraka.splitbar.trash", qos: .utility)
    private let metadataQuery = NSMetadataQuery()

    private var trashURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash", isDirectory: true)
    }

    private init() {
        metadataQuery.searchScopes = [trashURL]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryUpdated),
            name: .NSMetadataQueryDidFinishGathering,
            object: metadataQuery
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryUpdated),
            name: .NSMetadataQueryDidUpdate,
            object: metadataQuery
        )
        refresh()
        metadataQuery.start()
    }

    @objc private func queryUpdated() {
        refresh()
    }

    func refresh() {
        let url = trashURL
        queue.async { [weak self] in
            let names = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
            let hasVisibleItems = names.contains { !$0.hasPrefix(".") }
            DispatchQueue.main.async {
                self?.isEmpty = !hasVisibleItems
            }
        }
    }

    func openTrash() {
        NSWorkspace.shared.open(trashURL)
        refresh()
    }

    func emptyTrash() {
        queue.async { [weak self] in
            guard let script = NSAppleScript(source: "tell application \"Finder\" to empty trash") else { return }
            var errorDict: NSDictionary?
            script.executeAndReturnError(&errorDict)
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
    }
}
