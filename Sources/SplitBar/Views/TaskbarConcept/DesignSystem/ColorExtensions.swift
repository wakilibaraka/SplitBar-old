import AppKit
import SwiftUI

extension Color {
    static let roseAccent = Color(red: 0.82, green: 0.34, blue: 0.43)
    static let roseMist = Color(red: 0.98, green: 0.92, blue: 0.93)

    var storedRGBA: [Double] {
        guard let color = NSColor(self).usingColorSpace(.deviceRGB) else {
            return [0.91, 0.69, 0.87, 1]
        }
        return [
            Double(color.redComponent),
            Double(color.greenComponent),
            Double(color.blueComponent),
            Double(color.alphaComponent)
        ]
    }

    static func fromStoredRGBA(_ values: [Double]) -> Color? {
        guard values.count == 4,
              values.allSatisfy({ (0...1).contains($0) })
        else {
            return nil
        }
        return Color(
            .sRGB,
            red: values[0],
            green: values[1],
            blue: values[2],
            opacity: values[3]
        )
    }
}
