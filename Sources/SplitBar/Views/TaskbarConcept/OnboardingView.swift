import AppKit
import SwiftUI

/// First-launch onboarding: six pages covering welcome, style, mode,
/// permissions, widgets, and completion.
struct OnboardingView: View {
    @ObservedObject var model: TaskbarConceptState
    let accent: Color
    let isDarkMode: Bool
    let onDone: () -> Void
    @State private var page = 0

    private var pageCount: Int { 6 }

    @ViewBuilder
    private var currentPage: some View {
        switch page {
        case 1: stylePage
        case 2: modePage
        case 3: permissionsPage
        case 4: widgetsPage
        case 5: readyPage
        default: welcomePage
        }
    }

    /// Explicit, predictable surface and text tokens. `.secondary`/`.primary`
/// resolve to a mid-grey that is nearly the same luminance as the translucent
/// card, so they only looked right by accident on some wallpapers.
    private var cardSurface: Color { Color(red: 0.02, green: 0.03, blue: 0.05).opacity(0.88) }
    private var secondaryOnCard: Color { Color.white.opacity(0.78) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                currentPage
                    .frame(height: 430)
                footerBar
            }
            .padding(28)
            .frame(width: 560)
            .background(cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerBar: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == page ? accent : Color.white.opacity(0.2))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            if page > 0 {
                Button("Back") { withAnimation(.spring(response: 0.42)) { page -= 1 } }
                    .buttonStyle(.plain)
                    .foregroundStyle(secondaryOnCard)
            }
            Button(page == pageCount - 1 ? "Let's go" : "Continue") {
                if page == pageCount - 1 {
                    onDone()
                } else {
                    withAnimation(.spring(response: 0.42)) { page += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    private func pageTransition() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var welcomePage: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(model.surfaceStyle.taskbarFill(darkMode: isDarkMode))
                    .frame(width: 120, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent.opacity(0.8))
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .padding(.top, 8)
            Text("Welcome to SplitBar")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("A Windows-inspired taskbar, thoughtfully reimagined for macOS. This tour takes under a minute.")
                .font(.system(size: 13))
                .foregroundStyle(secondaryOnCard)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .transition(pageTransition())
    }

    private var stylePage: some View {
        VStack(spacing: 12) {
            Text("Choose your style")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Fourteen themes. Switch anytime in Personalisation.")
                .font(.system(size: 12))
                .foregroundStyle(secondaryOnCard)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(SurfaceStyle.allCases.prefix(8)) { style in
                    styleSwatchButton(style)
                }
            }
            .padding(.horizontal, 20)
        }
        .transition(pageTransition())
    }

    private func styleSwatchButton(_ style: SurfaceStyle) -> some View {
        let isSelected = model.surfaceStyle == style
        return Button { model.surfaceStyle = style } label: {
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(style.taskbarFill(darkMode: isDarkMode))
                    .frame(height: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isSelected ? accent : Color.white.opacity(0.18), lineWidth: isSelected ? 2 : 1)
                    }
                Text(style.title)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private var modePage: some View {
        VStack(spacing: 12) {
            Text("Pick a layout")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("One bar or floating islands — your call.")
                .font(.system(size: 12))
                .foregroundStyle(secondaryOnCard)
            VStack(spacing: 8) {
                ForEach(TaskbarMode.allCases) { mode in
                    Button { model.taskbarMode = mode } label: {
                        HStack {
                            Text(mode.title)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text(mode.detail)
                                .font(.system(size: 10))
                                .foregroundStyle(secondaryOnCard)
                                .lineLimit(1)
                            Image(systemName: model.taskbarMode == mode ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(model.taskbarMode == mode ? accent : secondaryOnCard)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            model.taskbarMode == mode ? accent.opacity(0.10) : Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .transition(pageTransition())
    }

    private var permissionsPage: some View {
        VStack(spacing: 12) {
            Text("Grant superpowers")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Everything is optional — SplitBar works without these, with graceful fallbacks.")
                .font(.system(size: 12))
                .foregroundStyle(secondaryOnCard)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            VStack(spacing: 8) {
                permissionRow(
                    symbol: "accessibility",
                    title: "Accessibility",
                    detail: "Minimize windows from the taskbar",
                    pane: "com.apple.preference.security?Privacy_Accessibility"
                )
                permissionRow(
                    symbol: "record.circle",
                    title: "Screen Recording",
                    detail: "Live window thumbnails on hover",
                    pane: "com.apple.preference.security?Privacy_ScreenCapture"
                )
                permissionRow(
                    symbol: "location.fill",
                    title: "Location",
                    detail: "Wi-Fi network name in Quick Settings",
                    pane: "com.apple.preference.security?Privacy_LocationServices"
                )
            }
            .padding(.horizontal, 20)
        }
        .transition(pageTransition())
    }

    private func permissionRow(symbol: String, title: String, detail: String, pane: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(secondaryOnCard)
            }
            Spacer()
            Button("Grant") {
                if let url = URL(string: "x-apple.systempreferences:\(pane)") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var widgetsPage: some View {
        VStack(spacing: 12) {
            Text("Widgets at a glance")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Weather, calendar, Now Playing, and system rings live one click away.")
                .font(.system(size: 12))
                .foregroundStyle(secondaryOnCard)
            HStack(spacing: 10) {
                ForEach(["Weather", "Calendar", "Music", "System"], id: \.self) { name in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent.opacity(0.14))
                            .frame(width: 100, height: 76)
                            .overlay {
                                Image(systemName: widgetSymbol(for: name))
                                    .font(.system(size: 22))
                                    .foregroundStyle(accent)
                            }
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            }
        }
        .transition(pageTransition())
    }

    private func widgetSymbol(for name: String) -> String {
        switch name {
        case "Weather": "cloud.sun.fill"
        case "Calendar": "calendar"
        case "Music": "music.note"
        default: "cpu"
        }
    }

    private var readyPage: some View {
        VStack(spacing: 14) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 44))
                .foregroundStyle(accent)
            Text("You're all set")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("Right-click any taskbar icon for options. Open Personalisation anytime from the taskbar menu.")
                .font(.system(size: 13))
                .foregroundStyle(secondaryOnCard)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .transition(pageTransition())
    }
}
