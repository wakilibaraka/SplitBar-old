import AppKit
import SwiftUI

public struct WebFaviconView: View {
    public let url: URL
    public let size: CGFloat

    @State private var downloadedImage: NSImage?

    public init(url: URL, size: CGFloat) {
        self.url = url
        self.size = size
    }

    private var host: String {
        (url.host ?? "link").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var initialLetter: String {
        let clean = host.replacingOccurrences(of: "www.", with: "")
        return clean.prefix(1).uppercased()
    }

    public var body: some View {
        let cornerRadius = size * (9.5 / 42.0)

        ZStack {
            // Brand-specific vector icons (High-Res 1st Class Design)
            if host.contains("github.com") {
                githubIcon(cornerRadius: cornerRadius)
            } else if host.contains("youtube.com") || host.contains("youtu.be") {
                youtubeIcon(cornerRadius: cornerRadius)
            } else if host.contains("x.com") || host.contains("twitter.com") {
                xTwitterIcon(cornerRadius: cornerRadius)
            } else if host.contains("chatgpt.com") || host.contains("openai.com") {
                chatGPTIcon(cornerRadius: cornerRadius)
            } else if host.contains("figma.com") {
                figmaIcon(cornerRadius: cornerRadius)
            } else if host.contains("notion.so") {
                notionIcon(cornerRadius: cornerRadius)
            } else if host.contains("google.com") {
                googleIcon(cornerRadius: cornerRadius)
            } else if host.contains("reddit.com") {
                redditIcon(cornerRadius: cornerRadius)
            } else if host.contains("spotify.com") {
                spotifyIcon(cornerRadius: cornerRadius)
            } else if let img = downloadedImage ?? FaviconService.shared.cachedFavicon(for: host) {
                // Real Live Favicon / SVG
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(white: 0.12).opacity(0.90))

                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size * 0.62, height: size * 0.62)
                        .cornerRadius(cornerRadius * 0.5)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.0),
                                    .init(color: Color.clear, location: 0.50),
                                    .init(color: Color.white.opacity(0.20), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            } else {
                // Elegant Monogram Fallback while fetching
                genericDomainBadge(cornerRadius: cornerRadius)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.35), radius: 3.5, x: 0.0, y: 2.0)
        .onAppear {
            if downloadedImage == nil {
                downloadedImage = FaviconService.shared.cachedFavicon(for: host)
                FaviconService.shared.requestFavicon(for: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: FaviconService.didUpdateNotification)) { notification in
            if let updatedHost = notification.userInfo?["host"] as? String,
               (updatedHost == host || host.contains(updatedHost)) {
                downloadedImage = FaviconService.shared.cachedFavicon(for: host)
            }
        }
    }

    // MARK: - Generic Fallback Badge

    private func genericDomainBadge(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.16, green: 0.22, blue: 0.32), location: 0.0),
                            .init(color: Color(red: 0.08, green: 0.10, blue: 0.16), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initialLetter)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.90))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.40), location: 0.0),
                            .init(color: Color.clear, location: 0.50),
                            .init(color: Color.white.opacity(0.15), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }

    // MARK: - Stilize Yedek Marka Glifleri (favicon indirilemediğinde gösterilir)

    private func githubIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(white: 0.10))

            Image(systemName: "cat.fill")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
        }
    }

    private func youtubeIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 1.0, green: 0.0, blue: 0.0))

            Image(systemName: "play.rectangle.fill")
                .font(.system(size: size * 0.55))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
        }
    }

    private func xTwitterIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black)

            Text("𝕏")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
        }
    }

    private func chatGPTIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.06, green: 0.65, blue: 0.53))

            Image(systemName: "sparkles")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
        }
    }

    private func figmaIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(white: 0.12))

            Image(systemName: "square.on.square.dashed")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.25))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
        }
    }

    private func notionIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            Text("N")
                .font(.system(size: size * 0.52, weight: .heavy, design: .serif))
                .foregroundColor(.black)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.15), lineWidth: 0.8)
        }
    }

    private func googleIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            Text("G")
                .font(.system(size: size * 0.50, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.8)
        }
    }

    private func redditIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 1.0, green: 0.27, blue: 0.0))

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
        }
    }

    private func spotifyIcon(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.11, green: 0.84, blue: 0.38))

            Image(systemName: "wave.3.forward")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundColor(.black)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
        }
    }
}
