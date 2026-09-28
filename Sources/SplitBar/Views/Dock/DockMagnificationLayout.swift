import CoreGraphics
import Foundation
import SwiftUI

public struct DockItemFramePreferenceData: Equatable, Sendable {
    public let id: UUID
    public let frame: CGRect

    public init(id: UUID, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

public struct DockItemFramesPreferenceKey: PreferenceKey {
    public static let defaultValue: [DockItemFramePreferenceData] = []

    public static func reduce(
        value: inout [DockItemFramePreferenceData],
        nextValue: () -> [DockItemFramePreferenceData]
    ) {
        value.append(contentsOf: nextValue())
    }
}

public extension DockAnimationPolicy {
    var animation: Animation {
        switch self {
        case .spring(let response, let dampingFraction):
            return .spring(response: response, dampingFraction: dampingFraction)
        case .reducedMotion(let duration):
            return .easeOut(duration: duration)
        }
    }
}
