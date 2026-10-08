import CoreGraphics

// MARK: - LayoutTokens
//
// The bar's spacing vocabulary (HYBRID_PLAN A3). Every island and shell
// padding derives from here so floating/split/docked modes keep one visual
// rhythm instead of ad-hoc numbers scattered through the views. Prefer
// multiples of `grid` for anything new.

enum LayoutTokens {
    /// The rhythm grid. Paddings snap to 4pt half-beats with major beats
    /// every 8pt.
    static let grid: CGFloat = 8

    /// Content inset inside a single island shell (split mode panels too).
    static let islandInnerPadding: CGFloat = 8

    /// Horizontal inset of the unified shell (floating mode).
    static let barOuterPadding: CGFloat = 16

    /// Horizontal inset of the edge-to-edge docked shell.
    static let dockedBarPadding: CGFloat = 8

    /// Trailing inset before the bar's right edge (docked tray cluster).
    static let trailingTrayPadding: CGFloat = 12

    /// Gutter between the weather island and the first divider.
    static let dividerGutter: CGFloat = 8
}
