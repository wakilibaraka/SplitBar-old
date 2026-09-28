import AppKit
import SwiftUI

public struct PointingHandCursorModifier: ViewModifier {
    @State private var isPushed: Bool = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .onHover { isHovered in
                if isHovered {
                    if !isPushed {
                        NSCursor.pointingHand.push()
                        isPushed = true
                    }
                } else {
                    if isPushed {
                        NSCursor.pop()
                        isPushed = false
                    }
                }
            }
            .onDisappear {
                if isPushed {
                    NSCursor.pop()
                    isPushed = false
                }
            }
    }
}

public extension View {
    func pointingHandCursor() -> some View {
        self.modifier(PointingHandCursorModifier())
    }
}
