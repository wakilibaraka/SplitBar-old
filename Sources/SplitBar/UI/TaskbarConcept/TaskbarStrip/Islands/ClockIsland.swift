import SwiftUI

// MARK: - ClockIsland
//
// Time/date button opening the calendar flyout, plus the optional trash
// placement rules that surround it (beforeClock / farRight). The display
// views moved here with it in the Phase-1 island split (HYBRID_PLAN A1).
//
// `tiles` is optional: the island renders standalone (e.g. the docked bar's
// trailing tray supplies its own placement) or with the clock-adjacent trash
// cluster the split layouts use.

struct ClockIsland: View {
    @ObservedObject var model: TaskbarConceptState
    var tiles: TaskbarTiles? = nil

    var body: some View {
        if let tiles {
            HStack(spacing: 4) {
                if model.trashPlacement(for: model.taskbarMode) == .beforeClock {
                    tiles.trashCluster
                }
                clockSection
                if model.trashPlacement(for: model.taskbarMode) == .farRight {
                    tiles.trashCluster
                }
            }
        } else {
            clockSection
        }
    }

    private var clockSection: some View {
        clockSchedule { date in
            Button {
                model.openPanel = model.openPanel == .calendar ? nil : .calendar
            } label: {
                TaskbarClockDisplay(
                    date: date,
                    style: model.clockDisplayStyle,
                    dateStyle: model.dateStyle,
                    uses24HourTime: model.uses24HourTime,
                    showsSeconds: model.showsSeconds,
                    tint: model.resolvedClockTint,
                    height: model.taskbarHeight,
                    tintGradient: model.clockTintGradient
                )
                .frame(minWidth: 88, minHeight: model.taskbarHeight - 8, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open calendar")
        }
    }

    private func clockSchedule<Content: View>(@ViewBuilder content: @escaping (Date) -> Content) -> some View {
        if model.showsSeconds {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(context.date)
            }
        } else {
            TimelineView(.periodic(from: .now.nextMinuteBoundary, by: 60)) { context in
                content(context.date)
            }
        }
    }
}


struct TaskbarClockDisplay: View {
    let date: Date
    let style: ClockDisplayStyle
    let dateStyle: ClockDateStyle
    let uses24HourTime: Bool
    let showsSeconds: Bool
    let tint: Color
    let height: CGFloat
    var tintGradient: LinearGradient? = nil

    private var time: String {
        clockTime(date, uses24HourTime: uses24HourTime, showsSeconds: showsSeconds)
    }

    private var textStyle: AnyShapeStyle {
        if let tintGradient {
            return AnyShapeStyle(tintGradient)
        }
        return AnyShapeStyle(tint)
    }

    var body: some View {
        Group {
            switch style {
            case .stacked:
                VStack(alignment: .trailing, spacing: 2) {
                    timeLabel
                    dateLabel
                }
            case .inline:
                HStack(spacing: 6) {
                    timeLabel
                    Text(dateStyle.string(from: date))
                        .font(.system(size: height * 0.19, weight: .medium))
                        .foregroundStyle(textStyle)
                        .lineLimit(1)
                }
            case .digital:
                timeLabel
            case .analog:
                HStack(spacing: 6) {
                    AnalogClockFace(date: date, tint: tint, size: min(height - 12, 24))
                    VStack(alignment: .trailing, spacing: 2) {
                        timeLabel
                        dateLabel
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var timeLabel: some View {
        Text(time)
            .font(.system(size: height * (style == .digital ? 0.32 : 0.27), weight: .semibold, design: .rounded))
            .foregroundStyle(textStyle)
            .lineLimit(1)
    }

    private var dateLabel: some View {
        Text(dateStyle.string(from: date))
            .font(.system(size: height * 0.20, weight: .medium))
            .foregroundStyle(textStyle)
            .lineLimit(1)
    }
}


struct AnalogClockFace: View {
    let date: Date
    let tint: Color
    let size: CGFloat

    private var hourAngle: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((components.hour ?? 0) % 12) * 30 + Double(components.minute ?? 0) / 2
    }

    private var minuteAngle: Double {
        Double(Calendar.current.component(.minute, from: date)) * 6
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(tint.opacity(0.7), lineWidth: 1.2)
            Capsule()
                .fill(tint)
                .frame(width: 2, height: size * 0.24)
                .offset(y: -size * 0.12)
                .rotationEffect(.degrees(hourAngle))
            Capsule()
                .fill(tint)
                .frame(width: 1.3, height: size * 0.34)
                .offset(y: -size * 0.17)
                .rotationEffect(.degrees(minuteAngle))
            Circle()
                .fill(tint)
                .frame(width: 3, height: 3)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(date.formatted(date: .omitted, time: .shortened))
    }
}
