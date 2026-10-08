import SwiftUI

struct ClockStyleSettings: View {
    @Binding var uses24HourTime: Bool
    @Binding var showsSeconds: Bool
    @Binding var dateStyle: ClockDateStyle
    @Binding var clockDisplayStyle: ClockDisplayStyle
    @Binding var clockTint: Color
    @Binding var clockColorPreset: ClockColorPreset
    @Binding var clockGradientEnabled: Bool
    @Binding var clockGradientStart: Color
    @Binding var clockGradientEnd: Color
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Taskbar clock")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                ColorPicker("Text colour", selection: $clockTint, supportsOpacity: false)
                    .labelsHidden()
                    .help("Choose clock and date text colour")
            }

            HStack(spacing: 6) {
                ForEach(ClockColorPreset.allCases) { preset in
                    styleChip(preset.title, isSelected: clockColorPreset == preset) {
                        clockColorPreset = preset
                    }
                }
            }

            Toggle(isOn: $clockGradientEnabled) {
                Text("Gradient text")
                    .font(.system(size: 11, weight: .medium))
            }
            .toggleStyle(.switch)
            if clockGradientEnabled || clockColorPreset == .gradient {
                HStack(spacing: 16) {
                    ColorPicker("Start", selection: $clockGradientStart, supportsOpacity: false)
                    ColorPicker("End", selection: $clockGradientEnd, supportsOpacity: false)
                }
                .font(.system(size: 11, weight: .medium))
            }

            HStack(spacing: 8) {
                styleChip("12-hour", isSelected: !uses24HourTime) { uses24HourTime = false }
                styleChip("24-hour", isSelected: uses24HourTime) { uses24HourTime = true }
                styleChip("Seconds", isSelected: showsSeconds) { showsSeconds.toggle() }
            }

            HStack(spacing: 6) {
                ForEach(ClockDisplayStyle.allCases) { style in
                    styleChip(style.title, isSelected: clockDisplayStyle == style) {
                        clockDisplayStyle = style
                    }
                }
            }

            HStack(spacing: 7) {
                ForEach(ClockDateStyle.allCases) { style in
                    styleChip(style.title, isSelected: dateStyle == style) {
                        dateStyle = style
                    }
                }
            }
        }
        .padding(12)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func styleChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.75))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(isSelected ? Color.roseAccent : Color.black.opacity(0.055), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
