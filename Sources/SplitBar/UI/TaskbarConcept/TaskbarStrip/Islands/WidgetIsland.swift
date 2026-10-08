import SwiftUI

// MARK: - WidgetIsland
//
// Weather badge for the taskbar. Opens the widgets panel. Extracted verbatim
// from TaskbarStripViews.swift in the Phase-1 island split (HYBRID_PLAN A1).

struct WidgetIsland: View {
    @ObservedObject var model: TaskbarConceptState

    private var glyphSize: CGFloat { model.taskbarHeight * model.taskbarIconSize.glyphFraction }

    var body: some View {
        Button {
            model.openPanel = model.openPanel == .widgets ? nil : .widgets
        } label: {
            HStack(spacing: 10) {
                Image(systemName: model.weather.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: glyphSize))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.weather.formattedTemperature)
                        .font(.system(size: 13, weight: .semibold))
                    Text(model.weather.conditionText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 170, height: model.taskbarHeight - 4, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open widgets")
    }
}
