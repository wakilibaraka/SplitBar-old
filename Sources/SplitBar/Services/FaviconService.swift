import AppKit
import Foundation

@MainActor
public final class FaviconService {
    public static let shared = FaviconService()
    public static let didUpdateNotification = Notification.Name("SplitBarFaviconDidUpdateNotification")

    private var memoryCache: [String: NSImage] = [:]
    private var inFlight: Set<String> = []
    private let cacheDirectory: URL

    /// Off by default. When enabled, DuckDuckGo and Google learn every host the
    /// user has pinned.
    public static var usesThirdPartyService = false

    private init() {
        let fileManager = FileManager.default
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = caches.appendingPathComponent("com.baraka.splitbar/Favicons", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        self.cacheDirectory = dir
    }

    public func cachedFavicon(for host: String) -> NSImage? {
        let cleanHost = host.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let memory = memoryCache[cleanHost] {
            return memory
        }

        let fileURL = cacheDirectory.appendingPathComponent("\(cleanHost).png")
        if let diskImage = NSImage(contentsOf: fileURL) {
            memoryCache[cleanHost] = diskImage
            return diskImage
        }

        return nil
    }

    public func requestFavicon(for url: URL) {
        guard let rawHost = url.host?.lowercased(), !rawHost.isEmpty else { return }
        let cleanHost = rawHost.trimmingCharacters(in: .whitespacesAndNewlines)

        if memoryCache[cleanHost] != nil || inFlight.contains(cleanHost) {
            return
        }

        if let diskImage = cachedFavicon(for: cleanHost) {
            memoryCache[cleanHost] = diskImage
            return
        }

        inFlight.insert(cleanHost)

        // The site's own icon is fetched first so a pinned host is not revealed
        // to a third party. The fallback services are used only when the user
        // opts in, because each request tells that service which sites you keep.
        let useFallbackServices = FaviconService.usesThirdPartyService

        Task.detached(priority: .background) { [cleanHost, cacheDirectory] in
            var candidates: [URL?] = [URL(string: "https://\(cleanHost)/favicon.ico")]
            if useFallbackServices {
                candidates.append(contentsOf: [
                    URL(string: "https://icons.duckduckgo.com/ip3/\(cleanHost).ico"),
                    URL(string: "https://www.google.com/s2/favicons?domain=\(cleanHost)&sz=128"),
                ])
            }

            var downloadedImage: NSImage? = nil

            for candidate in candidates {
                guard let candidateURL = candidate else { continue }
                var request = URLRequest(url: candidateURL)
                request.timeoutInterval = 4.0
                request.cachePolicy = .returnCacheDataElseLoad

                if let (data, response) = try? await URLSession.shared.data(for: request),
                   let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let image = NSImage(data: data),
                   image.isValid,
                   image.size.width > 0 && image.size.height > 0 {
                    downloadedImage = image
                    let fileURL = cacheDirectory.appendingPathComponent("\(cleanHost).png")
                    if let tiff = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        try? pngData.write(to: fileURL)
                    }
                    break
                }
            }

            let resultImage = downloadedImage
            await MainActor.run {
                FaviconService.shared.inFlight.remove(cleanHost)
                if let validImage = resultImage {
                    FaviconService.shared.memoryCache[cleanHost] = validImage
                    NotificationCenter.default.post(
                        name: FaviconService.didUpdateNotification,
                        object: nil,
                        userInfo: ["host": cleanHost]
                    )
                }
            }
        }
    }
}
