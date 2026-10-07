import SwiftUI

enum ClockDisplayStyle: String, CaseIterable, Identifiable {
    case stacked
    case inline
    case digital
    case analog

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stacked: "Stacked"
        case .inline: "Inline"
        case .digital: "Digital"
        case .analog: "Analog"
        }
    }
}


extension Date {
    var nextMinuteBoundary: Date {
        let calendar = Calendar.current
        let startOfMinute = calendar.dateInterval(of: .minute, for: self)?.start ?? self
        return calendar.date(byAdding: .minute, value: 1, to: startOfMinute) ?? self.addingTimeInterval(60)
    }
}


enum ClockDateStyle: String, CaseIterable, Identifiable {
    case compact
    case weekday
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Short"
        case .weekday: "Weekday"
        case .full: "Long"
        }
    }

    func string(from date: Date) -> String {
        switch self {
        case .compact:
            date.formatted(.dateTime.month(.twoDigits).day().year())
        case .weekday:
            date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .full:
            date.formatted(.dateTime.month(.wide).day().year())
        }
    }
}


func clockTime(_ date: Date, uses24HourTime: Bool, showsSeconds: Bool) -> String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.dateFormat = uses24HourTime
        ? (showsSeconds ? "HH:mm:ss" : "HH:mm")
        : (showsSeconds ? "h:mm:ss a" : "h:mm a")
    return formatter.string(from: date)
}


extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
