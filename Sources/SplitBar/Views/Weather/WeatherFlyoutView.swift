import Foundation
import SwiftUI

public struct WeatherFlyoutView: View {
    public let state: WeatherState
    public let onRefresh: () -> Void

    public init(
        state: WeatherState,
        onRefresh: @escaping () -> Void
    ) {
        self.state = state
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(spacing: 16.0) {
            // Header
            HStack {
                HStack(spacing: 6.0) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11.0))
                        .foregroundColor(.accentColor)
                    Text(state.cityName)
                        .font(.system(size: 13.0, weight: .bold))
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh Weather")
                        .font(.system(size: 12.0))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            // Hero: büyük sıcaklık solda, durum ve simge sağda
            HStack(alignment: .center, spacing: 12.0) {
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("\(Int(round(state.temperatureCelsius)))°")
                        .font(.system(size: 64.0, weight: .thin, design: .rounded))
                        .foregroundColor(.primary)
                    Text(state.conditionText)
                        .font(.system(size: 14.0, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("H \(Int(round(state.highCelsius)))°  ·  L \(Int(round(state.lowCelsius)))°")
                        .font(.system(size: 12.0, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0.0)
                Image(systemName: state.symbolName)
                    .font(.system(size: 56.0))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: SplitBarPalette.amber.opacity(0.35), radius: 14.0)
            }
            .padding(14.0)
            .liquidGlassCard(cornerRadius: 16.0, isHovered: false)

            // Saatlik tahmin: kartlar tüm genişliğe eşit dağılır
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Next hours")
                    .font(.system(size: 11.0, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 2.0)

                HStack(spacing: 8.0) {
                    ForEach(state.hourly.prefix(5)) { forecast in
                        VStack(spacing: 8.0) {
                            Text(forecast.hour)
                                .font(.system(size: 11.0, weight: .medium))
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                            Image(systemName: forecast.symbolName)
                                .font(.system(size: 18.0))
                                .symbolRenderingMode(.multicolor)
                                .frame(height: 22.0)
                            Text("\(Int(round(forecast.temperatureCelsius)))°")
                                .font(.system(size: 13.0, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 10.0)
                        .frame(maxWidth: .infinity)
                        .liquidGlassCard(cornerRadius: 12.0, isHovered: false)
                    }
                }
            }

            Spacer()
        }
        .padding(16.0)
    }
}
