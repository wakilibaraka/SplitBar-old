import CoreGraphics
import Foundation

public func animationPolicy(reduceMotion: Bool) -> DockAnimationPolicy {
    if reduceMotion {
        return .reducedMotion(duration: 0.12)
    } else {
        return .spring(response: 0.18, dampingFraction: 0.82)
    }
}

public func magnificationTransforms(
    items: [DockItemGeometry],
    pointer: CGPoint?,
    configuration: DockMagnificationConfiguration
) -> [UUID: DockItemVisualTransform] {
    guard let pointer = pointer else {
        var result: [UUID: DockItemVisualTransform] = [:]
        for item in items {
            result[item.id] = DockItemVisualTransform(
                scale: 1.0,
                translationY: 0.0,
                logicalFrame: item.logicalFrame
            )
        }
        return result
    }

    var result: [UUID: DockItemVisualTransform] = [:]
    for item in items {
        let center = CGPoint(
            x: item.logicalFrame.midX,
            y: item.logicalFrame.midY
        )
        let distance = hypot(pointer.x - center.x, pointer.y - center.y)

        if distance >= configuration.influenceRadius {
            result[item.id] = DockItemVisualTransform(
                scale: 1.0,
                translationY: 0.0,
                logicalFrame: item.logicalFrame
            )
        } else {
            let normalizedDistance = distance / configuration.influenceRadius
            let factor = 0.5 * (1.0 + cos(Double.pi * Double(normalizedDistance)))
            let scaleDelta = configuration.maxScale - 1.0
            let scale = 1.0 + CGFloat(factor) * scaleDelta
            let translationY = CGFloat(factor) * configuration.maxLift

            result[item.id] = DockItemVisualTransform(
                scale: scale,
                translationY: translationY,
                logicalFrame: item.logicalFrame
            )
        }
    }
    return result
}
