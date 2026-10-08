import SwiftUI

public struct ThemeTextFieldStyle: TextFieldStyle {
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        let isDarkMode = colorScheme == .dark
        
        Group {
            if surfaceStyle == .neumorphism {
                neumorphicBody(configuration: configuration, isDarkMode: isDarkMode)
            } else {
                standardBody(configuration: configuration, isDarkMode: isDarkMode)
            }
        }
        .font(surfaceStyle == .neumorphism ? .system(size: 13, weight: .medium, design: .rounded) : .system(size: 13))
    }
    
    private func neumorphicBody(configuration: TextField<Self._Label>, isDarkMode: Bool) -> some View {
        let surfaceColor = ThemeTokens.resolve(style: .neumorphism, darkMode: isDarkMode).card
        let lightShadow = isDarkMode ? Color(white: 0.25) : Color.white
        let darkShadow = isDarkMode ? Color.black.opacity(0.8) : Color.black.opacity(0.2)
        
        return configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(surfaceColor)
                    .overlay {
                        // Inner shadows (Inset)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.clear, lineWidth: 4)
                            .shadow(color: darkShadow, radius: 3, x: 2, y: 2)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.clear, lineWidth: 4)
                            .shadow(color: lightShadow.opacity(0.7), radius: 3, x: -2, y: -2)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
            }
    }
    
    private func standardBody(configuration: TextField<Self._Label>, isDarkMode: Bool) -> some View {
        let tokens = ThemeTokens.resolve(style: surfaceStyle, darkMode: isDarkMode)
        return configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tokens.card.opacity(0.5))
            }
            .overlay {
                if surfaceStyle == .classic98 || surfaceStyle == .neobrutalism {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isDarkMode ? .white : .black, lineWidth: 1)
                }
            }
    }
}
