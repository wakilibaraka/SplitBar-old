import SwiftUI

public struct ThemeButtonStyle: ButtonStyle {
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    
    var isPrimary: Bool
    var cornerRadius: CGFloat
    var isIcon: Bool
    
    public init(isPrimary: Bool = false, cornerRadius: CGFloat = 8, isIcon: Bool = false) {
        self.isPrimary = isPrimary
        self.cornerRadius = cornerRadius
        self.isIcon = isIcon
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let isDarkMode = colorScheme == .dark
        let isPressed = configuration.isPressed
        
        Group {
            if surfaceStyle == .neumorphism {
                neumorphicBody(configuration: configuration, isDarkMode: isDarkMode, isPressed: isPressed)
            } else {
                standardBody(configuration: configuration, isDarkMode: isDarkMode, isPressed: isPressed)
            }
        }
        .font(surfaceStyle == .neumorphism ? .system(size: 13, weight: .medium, design: .rounded) : .system(size: 13))
    }
    
    // MARK: - Neumorphism Implementation
    private func neumorphicBody(configuration: Configuration, isDarkMode: Bool, isPressed: Bool) -> some View {
        let surfaceColor = ThemeTokens.resolve(style: .neumorphism, darkMode: isDarkMode).card
        let lightShadow = isDarkMode ? Color(white: 0.25) : Color.white
        let darkShadow = isDarkMode ? Color.black.opacity(0.8) : Color.black.opacity(0.2)
        
        return configuration.label
            .padding(.horizontal, isIcon ? 0 : 14)
            .padding(.vertical, isIcon ? 0 : 8)
            .background {
                if isPressed {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(surfaceColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(surfaceColor, lineWidth: 2)
                        }
                        .overlay {
                            // Inner shadows for pressed state
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color.clear, lineWidth: 4)
                                .shadow(color: darkShadow, radius: 3, x: 2, y: 2)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color.clear, lineWidth: 4)
                                .shadow(color: lightShadow.opacity(0.7), radius: 3, x: -2, y: -2)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(surfaceColor)
                        .shadow(color: darkShadow, radius: 5, x: 4, y: 4)
                        .shadow(color: lightShadow, radius: 5, x: -3, y: -3)
                }
            }
            .foregroundStyle(isPrimary ? (isDarkMode ? Color.white : Color.black) : Color.secondary)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }
    
    // MARK: - Standard Implementation (Fallback for other themes temporarily)
    private func standardBody(configuration: Configuration, isDarkMode: Bool, isPressed: Bool) -> some View {
        let tokens = ThemeTokens.resolve(style: surfaceStyle, darkMode: isDarkMode)
        return configuration.label
            .padding(.horizontal, isIcon ? 0 : 14)
            .padding(.vertical, isIcon ? 0 : 8)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isPrimary ? tokens.accent : (isPressed ? tokens.card.opacity(0.8) : tokens.card))
            }
            .overlay {
                if surfaceStyle == .classic98 || surfaceStyle == .cyberdeck || surfaceStyle == .neobrutalism {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(isDarkMode ? .white.opacity(0.4) : .black.opacity(0.3), lineWidth: 1)
                }
            }
            .foregroundStyle(isPrimary ? Color.white : Color.primary)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}
