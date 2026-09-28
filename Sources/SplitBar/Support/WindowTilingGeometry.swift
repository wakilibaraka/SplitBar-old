import CoreGraphics
import Foundation

public struct WindowTilingGeometry {
    public static func calculateCocoaTargetFrame(
        action: WindowTilingAction,
        screenVisibleFrame: CGRect,
        configuration: WindowTilingConfiguration
    ) -> CGRect {
        let gap = configuration.gap
        let margin = configuration.edgeMargin

        let workArea = CGRect(
            x: screenVisibleFrame.origin.x + margin,
            y: screenVisibleFrame.origin.y + margin,
            width: max(100.0, screenVisibleFrame.width - (margin * 2.0)),
            height: max(100.0, screenVisibleFrame.height - (margin * 2.0))
        )

        let halfWidth = (workArea.width - gap) / 2.0
        let halfHeight = (workArea.height - gap) / 2.0

        switch action {
        case .maximize:
            return workArea

        case .almostMaximize:
            let inset: CGFloat = 24.0
            return CGRect(
                x: workArea.origin.x + inset,
                y: workArea.origin.y + inset,
                width: max(100.0, workArea.width - (inset * 2.0)),
                height: max(100.0, workArea.height - (inset * 2.0))
            )

        case .leftHalf:
            return CGRect(
                x: workArea.origin.x,
                y: workArea.origin.y,
                width: halfWidth,
                height: workArea.height
            )

        case .rightHalf:
            return CGRect(
                x: workArea.origin.x + halfWidth + gap,
                y: workArea.origin.y,
                width: halfWidth,
                height: workArea.height
            )

        case .topHalf:
            return CGRect(
                x: workArea.origin.x,
                y: workArea.origin.y + halfHeight + gap,
                width: workArea.width,
                height: halfHeight
            )

        case .bottomHalf:
            return CGRect(
                x: workArea.origin.x,
                y: workArea.origin.y,
                width: workArea.width,
                height: halfHeight
            )

        case .topLeftQuarter:
            return CGRect(
                x: workArea.origin.x,
                y: workArea.origin.y + halfHeight + gap,
                width: halfWidth,
                height: halfHeight
            )

        case .topRightQuarter:
            return CGRect(
                x: workArea.origin.x + halfWidth + gap,
                y: workArea.origin.y + halfHeight + gap,
                width: halfWidth,
                height: halfHeight
            )

        case .bottomLeftQuarter:
            return CGRect(
                x: workArea.origin.x,
                y: workArea.origin.y,
                width: halfWidth,
                height: halfHeight
            )

        case .bottomRightQuarter:
            return CGRect(
                x: workArea.origin.x + halfWidth + gap,
                y: workArea.origin.y,
                width: halfWidth,
                height: halfHeight
            )

        case .center:
            let defaultSize = CGSize(
                width: min(workArea.width * 0.70, 1100.0),
                height: min(workArea.height * 0.75, 780.0)
            )
            let originX = workArea.origin.x + (workArea.width - defaultSize.width) / 2.0
            let originY = workArea.origin.y + (workArea.height - defaultSize.height) / 2.0
            return CGRect(x: originX, y: originY, width: defaultSize.width, height: defaultSize.height)
        }
    }

    public static func convertCocoaToAXFrame(
        cocoaRect: CGRect,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        let axX = cocoaRect.origin.x
        let axY = primaryScreenHeight - (cocoaRect.origin.y + cocoaRect.height)
        return CGRect(x: axX, y: axY, width: cocoaRect.width, height: cocoaRect.height)
    }
}
