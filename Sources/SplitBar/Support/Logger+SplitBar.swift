import Foundation
import OSLog

public extension Logger {
    private static let subsystem: String = "com.baraka.splitbar"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let dock = Logger(subsystem: subsystem, category: "dock")
    static let shortcuts = Logger(subsystem: subsystem, category: "shortcuts")
    static let clipboard = Logger(subsystem: subsystem, category: "clipboard")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let panels = Logger(subsystem: subsystem, category: "panels")
    static let general = Logger(subsystem: subsystem, category: "general")
}
