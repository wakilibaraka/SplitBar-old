import SwiftUI

public struct ThemeToggleStyle: ToggleStyle {
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    
    public func makeBody(configuration: Configuration) -> some View {
        let isDarkMode = colorScheme == .dark
        let isOn = configuration.isOn
        
        HStack {
            configuration.label
                .font(surfaceStyle == .neumorphism ? .system(size: 13, weight: .medium, design: .rounded) : .system(size: 13))
            
            Spacer()
            
            if surfaceStyle == .neumorphism {
                neumorphicToggle(isOn: isOn, isDarkMode: isDarkMode)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            configuration.isOn.toggle()
                        }
                    }
            } else {
                standardToggle(isOn: isOn, isDarkMode: isDarkMode)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            configuration.isOn.toggle()
                        }
                    }
            }
        }
    }
    
    // MARK: - Neumorphism Implementation
    private func neumorphicToggle(isOn: Bool, isDarkMode: Bool) -> some View {
        let surfaceColor = ThemeTokens.resolve(style: .neumorphism, darkMode: isDarkMode).surface
        let lightShadow = isDarkMode ? Color(white: 0.25) : Color.white
        let darkShadow = isDarkMode ? Color.black.opacity(0.8) : Color.black.opacity(0.2)
        let activeTint = Color(red: 0.35, green: 0.55, blue: 0.95)
        
        return ZStack(alignment: isOn ? .trailing : .leading) {
            // Track (Inset groove)
            Capsule()
                .fill(surfaceColor)
                .frame(width: 44, height: 24)
                .overlay {
                    Capsule()
                        .stroke(Color.clear, lineWidth: 4)
                        .shadow(color: darkShadow, radius: 2, x: 2, y: 2)
                        .clipShape(Capsule())
                }
                .overlay {
                    Capsule()
                        .stroke(Color.clear, lineWidth: 4)
                        .shadow(color: lightShadow, radius: 2, x: -2, y: -2)
                        .clipShape(Capsule())
                }
            
            // Active background color fill
            Capsule()
                .fill(activeTint.opacity(isOn ? 1 : 0))
                .frame(width: 44, height: 24)
                .blendMode(isDarkMode ? .colorDodge : .multiply)
                .opacity(0.4)
            
            // Thumb (Extruded button)
            Circle()
                .fill(surfaceColor)
                .frame(width: 20, height: 20)
                .padding(2)
                .shadow(color: darkShadow.opacity(0.5), radius: 2, x: 2, y: 2)
                .shadow(color: lightShadow.opacity(0.5), radius: 2, x: -1, y: -1)
        }
    }
    
    // MARK: - Standard Implementation
    private func standardToggle(isOn: Bool, isDarkMode: Bool) -> some View {
        let tokens = ThemeTokens.resolve(style: surfaceStyle, darkMode: isDarkMode)
        return ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? tokens.accent : tokens.card.opacity(0.5))
                .frame(width: 40, height: 22)
                .overlay {
                    if surfaceStyle == .classic98 || surfaceStyle == .neobrutalism {
                        Capsule().strokeBorder(isDarkMode ? .white : .black, lineWidth: surfaceStyle == .neobrutalism ? 2 : 1)
                    }
                }
            
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .padding(2)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}
