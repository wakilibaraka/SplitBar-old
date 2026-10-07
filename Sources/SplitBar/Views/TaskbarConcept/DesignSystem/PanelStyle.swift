import SwiftUI

enum CornerStyle: String, CaseIterable, Identifiable {
    case pill
    case roundedRect
    case sharp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pill: "Pill"
        case .roundedRect: "Rounded"
        case .sharp: "Sharp"
        }
    }

    func shellRadius(surfaceStyle: SurfaceStyle) -> CGFloat {
        switch self {
        case .pill: 26
        case .roundedRect: surfaceStyle.cornerRadius
        case .sharp: 2
        }
    }
}


enum CornerScope: String, CaseIterable, Identifiable {
    case universal
    case perSurface

    var id: String { rawValue }

    var title: String {
        switch self {
        case .universal: "Universal"
        case .perSurface: "Per surface"
        }
    }
}


enum CornerSurface {
    case taskbar
    case widgets
    case flyouts
}


enum PanelKind: String, CaseIterable, Identifiable {
    case start
    case widgets
    case calendar
    case controls
    case settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .start: "Start"
        case .widgets: "Widgets"
        case .calendar: "Calendar"
        case .controls: "Quick Settings"
        case .settings: "Personalisation"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .start: 640
        case .widgets: 480
        case .calendar: 380
        case .controls: 360
        case .settings: 560
        }
    }

    var minimumWidth: CGFloat {
        switch self {
        case .start: 560
        case .widgets: 400
        case .calendar: 340
        case .controls: 320
        case .settings: 480
        }
    }

    var maximumWidth: CGFloat {
        switch self {
        case .start: 860
        case .widgets: 640
        case .calendar: 520
        case .controls: 520
        case .settings: 680
        }
    }
}
