import AppKit
import SwiftUI

struct ClockFlyout: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    @Binding var showsClockSettings: Bool
    @Binding var uses24HourTime: Bool
    @Binding var showsSeconds: Bool
    @Binding var dateStyle: ClockDateStyle
    @Binding var clockDisplayStyle: ClockDisplayStyle
    @Binding var clockTint: Color
    @Binding var clockColorPreset: ClockColorPreset
    @Binding var clockGradientEnabled: Bool
    @Binding var clockGradientStart: Color
    @Binding var clockGradientEnd: Color
    let accent: Color
    let cornerRadius: CGFloat
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("Calendar")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(18)

            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("Your calendar")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    monthButton("chevron.left", step: -1)
                    monthButton("chevron.right", step: 1)
                }

                MonthGrid(month: displayedMonth, selectedDate: $selectedDate)

                CalendarActivities(accent: accent)

                FocusWidget()

                HStack {
                    Label("30 min", systemImage: "timer")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showsClockSettings.toggle()
                    } label: {
                        Label("Clock style", systemImage: "paintpalette")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(clockTint)
                }
                .padding(.top, 2)

                if showsClockSettings {
                    ClockStyleSettings(
                        uses24HourTime: $uses24HourTime,
                        showsSeconds: $showsSeconds,
                        dateStyle: $dateStyle,
                        clockDisplayStyle: $clockDisplayStyle,
                        clockTint: $clockTint,
                        clockColorPreset: $clockColorPreset,
                        clockGradientEnabled: $clockGradientEnabled,
                        clockGradientStart: $clockGradientStart,
                        clockGradientEnd: $clockGradientEnd
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                }
                .padding(18)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.22), value: showsClockSettings)
    }

    private func monthButton(_ symbol: String, step: Int) -> some View {
        Button {
            if let nextMonth = Calendar.current.date(byAdding: .month, value: step, to: displayedMonth) {
                displayedMonth = nextMonth
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}


struct MonthGrid: View {
    let month: Date
    @Binding var selectedDate: Date

    private var days: [Date?] {
        let calendar = Calendar.current
        guard
            let range = calendar.range(of: .day, in: .month, for: month),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }

        let leadingDays = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
        return Array(repeating: nil, count: leadingDays) + dates.map(Optional.some)
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = max(0, calendar.firstWeekday - 1)
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
            }

            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    Button {
                        selectedDate = day
                    } label: {
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : .primary.opacity(0.78))
                            .frame(maxWidth: .infinity)
                            .frame(height: 31)
                            .background {
                                if isSelected {
                                    Circle().fill(Color.roseAccent)
                                } else if Calendar.current.isDateInToday(day) {
                                    Circle().stroke(Color.roseAccent.opacity(0.55), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 31)
                }
            }
        }
    }
}


struct CalendarActivities: View {
    let accent: Color
    @State private var completedTasks: Set<String> = []
    @State private var isAgendaExpanded = true
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private let events = [
        ("10:30", "Design check-in", "Studio"),
        ("14:00", "Project planning", "Online")
    ]
    private let tasks = ["Review design notes", "Send project update"]
    private let alarms = [("7:30 AM", "Weekdays"), ("9:00 AM", "Saturday")]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader("Events", symbol: "calendar.badge.clock", trailing: "New event")
            ForEach(events, id: \.1) { time, title, location in
                HStack(spacing: 9) {
                    Text(time)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accent)
                        .frame(width: 3, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 10, weight: .semibold))
                        Text(location).font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            sectionHeader("Tasks", symbol: "checklist", trailing: "Add task")
            ForEach(tasks, id: \.self) { task in
                Button {
                    if completedTasks.contains(task) {
                        completedTasks.remove(task)
                    } else {
                        completedTasks.insert(task)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: completedTasks.contains(task) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(completedTasks.contains(task) ? accent : Color.secondary)
                        Text(task)
                            .strikethrough(completedTasks.contains(task))
                        Spacer()
                        Image(systemName: "star")
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.82))
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            Button {
                isAgendaExpanded.toggle()
            } label: {
                HStack {
                    Label("Agenda", systemImage: "list.bullet.rectangle")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text(isAgendaExpanded ? "Today · 2 items" : "Show today")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: isAgendaExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isAgendaExpanded {
                Text("2 events and 2 tasks scheduled for today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            sectionHeader("Alarms", symbol: "alarm", trailing: "Add alarm")
            ForEach(alarms, id: \.0) { time, repeatDays in
                HStack {
                    Image(systemName: "alarm")
                        .foregroundStyle(accent)
                        .frame(width: 19)
                    Text(time)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(repeatDays)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "togglepower")
                        .foregroundStyle(accent)
                }
            }
        }
        .padding(14)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func sectionHeader(_ title: String, symbol: String, trailing: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
            Spacer()
            Button(trailing) {}
                .font(.system(size: 9, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(accent)
        }
    }
}
