import SwiftUI

// MARK: - StartIsland
//
// The Start button (Launchpad-style emblem opening the launcher). Extracted
// from TaskbarStripViews.swift in the Phase-1 island split (HYBRID_PLAN A1).

struct StartIsland: View {
    @ObservedObject var model: TaskbarConceptState

    private var glyphSize: CGFloat { model.taskbarHeight * model.taskbarIconSize.glyphFraction }
    private var tileSide: CGFloat { max(28, model.taskbarHeight - 4) }

    var body: some View {
        Button {
            model.openPanel = model.openPanel == .start ? nil : .start
        } label: {
            MacOSAppIcon(
                bundleIdentifier: "com.apple.launchpad",
                fallbackSymbol: "square.grid.3x3.fill",
                fallbackColor: model.isDarkMode ? Color(red: 0.54, green: 0.76, blue: 1) : .blue,
                size: glyphSize
            )
            .frame(width: tileSide, height: tileSide)
            .taskbarTile()
        }
        .buttonStyle(.plain)
        .help("Open Start")
    }
}
