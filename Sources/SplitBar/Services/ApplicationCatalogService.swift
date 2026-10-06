import Foundation

public final class ApplicationCatalogService: @unchecked Sendable {
    public init() {
    }

    public func scan(directories: [URL]) -> [ApplicationDescriptor] {
        var results: [ApplicationDescriptor] = []
        var seenBundleIDs = Set<String>()

        for dir in directories {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isApplicationKey],
                // .skipsHiddenFiles kullanılmaz: macOS, Cryptex'teki Safari'ye giden /Applications/Safari.app
                // bağlantısını "hidden" bayrağıyla işaretler ve Safari listeden düşer. Yalnızca nokta dosyaları elenir.
                options: []
            ) else {
                continue
            }

            for url in contents where url.pathExtension == "app" && !url.lastPathComponent.hasPrefix(".") {
                guard let bundle = Bundle(url: url) else { continue }
                let bundleID = bundle.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                if seenBundleIDs.contains(bundleID) {
                    continue
                }
                seenBundleIDs.insert(bundleID)

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                let categoryType = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String

                results.append(
                    ApplicationDescriptor(
                        bundleIdentifier: bundleID,
                        displayName: displayName,
                        applicationURL: url,
                        category: Self.friendlyCategoryName(for: categoryType)
                    )
                )
            }
        }

        return results.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }

    public static func catalogDirectories() -> [URL] {
        let fileManager = FileManager.default
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
    }

    private static func friendlyCategoryName(for rawType: String?) -> String {
        switch rawType {
        case "public.app-category.business": return "Business"
        case "public.app-category.developer-tools": return "Developer Tools"
        case "public.app-category.education": return "Education"
        case "public.app-category.entertainment": return "Entertainment"
        case "public.app-category.finance": return "Finance"
        case "public.app-category.games",
             "public.app-category.action-games",
             "public.app-category.adventure-games",
             "public.app-category.arcade-games",
             "public.app-category.board-games",
             "public.app-category.card-games",
             "public.app-category.casino-games",
             "public.app-category.dice-games",
             "public.app-category.educational-games",
             "public.app-category.family-games",
             "public.app-category.kids-games",
             "public.app-category.music-games",
             "public.app-category.puzzle-games",
             "public.app-category.racing-games",
             "public.app-category.role-playing-games",
             "public.app-category.simulation-games",
             "public.app-category.sports-games",
             "public.app-category.strategy-games",
             "public.app-category.trivia-games",
             "public.app-category.word-games": return "Games"
        case "public.app-category.graphics-design": return "Graphics & Design"
        case "public.app-category.healthcare-fitness": return "Health & Fitness"
        case "public.app-category.lifestyle": return "Lifestyle"
        case "public.app-category.medical": return "Medical"
        case "public.app-category.music": return "Music"
        case "public.app-category.news": return "News"
        case "public.app-category.photography": return "Photography"
        case "public.app-category.productivity": return "Productivity"
        case "public.app-category.reference": return "Reference"
        case "public.app-category.social-networking": return "Social Networking"
        case "public.app-category.sports": return "Sports"
        case "public.app-category.travel": return "Travel"
        case "public.app-category.utilities": return "Utilities"
        case "public.app-category.video": return "Video"
        case "public.app-category.weather": return "Weather"
        default: return "Other"
        }
    }
}
