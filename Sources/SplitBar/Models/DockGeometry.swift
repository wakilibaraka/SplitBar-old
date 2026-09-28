import CoreGraphics
import Foundation

public struct DockMagnificationConfiguration: Equatable, Sendable {
    public let maxScale: CGFloat
    public let influenceRadius: CGFloat
    public let maxLift: CGFloat

    public init(
        maxScale: CGFloat,
        influenceRadius: CGFloat,
        maxLift: CGFloat
    ) {
        self.maxScale = maxScale
        self.influenceRadius = influenceRadius
        self.maxLift = maxLift
    }
}

public struct DockItemGeometry: Equatable, Sendable {
    public let id: UUID
    public let logicalFrame: CGRect

    public init(
        id: UUID,
        logicalFrame: CGRect
    ) {
        self.id = id
        self.logicalFrame = logicalFrame
    }
}

public struct DockItemVisualTransform: Equatable, Sendable {
    public let scale: CGFloat
    public let translationY: CGFloat
    public let logicalFrame: CGRect

    public init(
        scale: CGFloat,
        translationY: CGFloat,
        logicalFrame: CGRect
    ) {
        self.scale = scale
        self.translationY = translationY
        self.logicalFrame = logicalFrame
    }
}

public enum DockAnimationPolicy: Equatable, Sendable {
    case spring(response: Double, dampingFraction: Double)
    case reducedMotion(duration: Double)
}
