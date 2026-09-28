import CoreGraphics
import Foundation

public enum WindowTilingAction: String, CaseIterable, Codable, Sendable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case maximize = "Maximize"
    case center = "Center"
    case almostMaximize = "Almost Maximize"
    case topLeftQuarter = "Top Left Quarter"
    case topRightQuarter = "Top Right Quarter"
    case bottomLeftQuarter = "Bottom Left Quarter"
    case bottomRightQuarter = "Bottom Right Quarter"
}

public struct WindowTilingConfiguration: Equatable, Sendable {
    public let gap: CGFloat
    public let edgeMargin: CGFloat

    public init(gap: CGFloat, edgeMargin: CGFloat) {
        self.gap = gap
        self.edgeMargin = edgeMargin
    }
}
