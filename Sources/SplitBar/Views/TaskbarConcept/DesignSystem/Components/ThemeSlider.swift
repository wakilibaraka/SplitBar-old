import SwiftUI

public struct ThemeSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isDragging = false
    
    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil) {
        self._value = value
        self.range = range
    }
    
    public init(value: Binding<CGFloat>, in range: ClosedRange<CGFloat> = 0...1, step: CGFloat? = nil) {
        self._value = Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = CGFloat($0) })
        self.range = Double(range.lowerBound)...Double(range.upperBound)
    }
    
    public var body: some View {
        let isDarkMode = colorScheme == .dark
        
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbWidth: CGFloat = surfaceStyle == .neumorphism ? 24 : 16
            let fillWidth = max(0, min(width, width * normalizedValue))
            
            Group {
                if surfaceStyle == .neumorphism {
                    neumorphicSlider(
                        width: width,
                        height: height,
                        fillWidth: fillWidth,
                        thumbWidth: thumbWidth,
                        isDarkMode: isDarkMode
                    )
                } else {
                    standardSlider(
                        width: width,
                        height: height,
                        fillWidth: fillWidth,
                        thumbWidth: thumbWidth,
                        isDarkMode: isDarkMode
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let rawValue = gesture.location.x / width
                        let clamped = max(0, min(1, rawValue))
                        value = range.lowerBound + (clamped * (range.upperBound - range.lowerBound))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: surfaceStyle == .neumorphism ? 24 : 16)
    }
    
    private func neumorphicSlider(width: CGFloat, height: CGFloat, fillWidth: CGFloat, thumbWidth: CGFloat, isDarkMode: Bool) -> some View {
        let surfaceColor = ThemeTokens.resolve(style: .neumorphism, darkMode: isDarkMode).surface
        let lightShadow = isDarkMode ? Color(white: 0.25) : Color.white
        let darkShadow = isDarkMode ? Color.black.opacity(0.8) : Color.black.opacity(0.2)
        let activeTint = Color(red: 0.35, green: 0.55, blue: 0.95)
        
        return ZStack(alignment: .leading) {
            // Track (Inset groove)
            Capsule()
                .fill(surfaceColor)
                .frame(height: 12)
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
                .frame(maxHeight: .infinity)
            
            // Fill
            Capsule()
                .fill(activeTint)
                .frame(width: fillWidth, height: 12)
                .opacity(0.7)
            
            // Thumb
            Circle()
                .fill(surfaceColor)
                .frame(width: thumbWidth, height: thumbWidth)
                .shadow(color: darkShadow.opacity(0.5), radius: 3, x: 2, y: 2)
                .shadow(color: lightShadow.opacity(0.5), radius: 3, x: -1, y: -1)
                .offset(x: max(0, min(width - thumbWidth, fillWidth - (thumbWidth / 2))))
        }
    }
    
    private func standardSlider(width: CGFloat, height: CGFloat, fillWidth: CGFloat, thumbWidth: CGFloat, isDarkMode: Bool) -> some View {
        let tokens = ThemeTokens.resolve(style: surfaceStyle, darkMode: isDarkMode)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(tokens.card.opacity(0.5))
                .frame(height: 6)
                .overlay {
                    if surfaceStyle == .classic98 || surfaceStyle == .neobrutalism {
                        Capsule().strokeBorder(isDarkMode ? .white : .black, lineWidth: 1)
                    }
                }
                .frame(maxHeight: .infinity)
            
            Capsule()
                .fill(tokens.accent)
                .frame(width: fillWidth, height: 6)
            
            Circle()
                .fill(Color.white)
                .frame(width: thumbWidth, height: thumbWidth)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .overlay {
                    if surfaceStyle == .classic98 || surfaceStyle == .neobrutalism {
                        Circle().strokeBorder(isDarkMode ? .white : .black, lineWidth: 1)
                    }
                }
                .offset(x: max(0, min(width - thumbWidth, fillWidth - (thumbWidth / 2))))
        }
    }
}
