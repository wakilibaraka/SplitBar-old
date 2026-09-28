import SwiftUI

/// Kullanım oranına göre gösterge rengi: düşük yükte metrik kendi rengini korur, yüksek yükte uyarı rengine döner.
public func systemLoadTint(percent: Double, base: Color) -> Color {
    if percent >= 90.0 {
        return SplitBarPalette.coral
    }
    if percent >= 75.0 {
        return SplitBarPalette.amber
    }
    return base
}

public struct SystemMonitorFlyoutView: View {
    public let metrics: SystemMetrics
    public let onRefresh: () -> Void
    public let onOpenDetailedWindow: () -> Void

    public init(
        metrics: SystemMetrics,
        onRefresh: @escaping () -> Void,
        onOpenDetailedWindow: @escaping () -> Void
    ) {
        self.metrics = metrics
        self.onRefresh = onRefresh
        self.onOpenDetailedWindow = onOpenDetailedWindow
    }

    private func gigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / 1_073_741_824.0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: 0.0) {
                Spacer()
                ringColumn(
                    percent: metrics.cpu.usagePercent,
                    base: SplitBarPalette.cyan,
                    caption: "CPU",
                    detail: String(format: "User %.0f%% · Sys %.0f%%", metrics.cpu.userPercent, metrics.cpu.systemPercent)
                )
                Spacer()
                ringColumn(
                    percent: metrics.memory.usagePercent,
                    base: SplitBarPalette.violet,
                    caption: "Memory",
                    detail: String(format: "%.1f of %.0f GB", gigabytes(metrics.memory.usedBytes), gigabytes(metrics.memory.totalBytes))
                )
                Spacer()
            }
            .padding(.vertical, 12.0)
            .liquidGlassCard(cornerRadius: 14.0, isHovered: false)

            // Ağ
            HStack(spacing: 10.0) {
                metricIcon("network", tint: SplitBarPalette.mint)
                Text("Network")
                    .font(.system(size: 12.0, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Label(metrics.network.formattedUploadSpeed, systemImage: "arrow.up")
                    .font(.system(size: 11.0, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                Label(metrics.network.formattedDownloadSpeed, systemImage: "arrow.down")
                    .font(.system(size: 11.0, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(SplitBarPalette.mint)
            }
            .padding(10.0)
            .liquidGlassCard(cornerRadius: 12.0, isHovered: false)

            // Disk
            VStack(alignment: .leading, spacing: 7.0) {
                HStack(spacing: 10.0) {
                    metricIcon("internaldrive", tint: SplitBarPalette.amber)
                    Text("Storage")
                        .font(.system(size: 12.0, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.0f GB free", gigabytes(metrics.disk.freeBytes)))
                        .font(.system(size: 11.0, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                GlassProgressBar(
                    fraction: metrics.disk.usagePercent / 100.0,
                    tint: systemLoadTint(percent: metrics.disk.usagePercent, base: SplitBarPalette.amber),
                    height: 6.0
                )
            }
            .padding(10.0)
            .liquidGlassCard(cornerRadius: 12.0, isHovered: false)

            // Pil ve ısı
            HStack(spacing: 10.0) {
                if let battery = metrics.battery {
                    statusTile(
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.75",
                        tint: battery.levelPercent <= 20 ? SplitBarPalette.coral : SplitBarPalette.mint,
                        title: "\(battery.levelPercent)%",
                        subtitle: battery.isPluggedIn ? "Power connected" : "On battery"
                    )
                }
                statusTile(
                    icon: "thermometer.medium",
                    tint: metrics.thermal.isThrottling ? SplitBarPalette.coral : SplitBarPalette.mint,
                    title: metrics.thermal.stateName,
                    subtitle: metrics.thermal.isThrottling ? "Throttling" : "Normal pressure"
                )
            }

            HStack(spacing: 8.0) {
                Button(action: onOpenDetailedWindow) {
                    Label("Open Monitor", systemImage: "macwindow")
                        .font(.system(size: 11.0, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12.0)
                        .padding(.vertical, 6.0)
                        .liquidGlassPill(accentColor: SplitBarPalette.cyan)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()

                Spacer()

                Text("Live · 1s")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.secondary)

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11.0, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24.0, height: 24.0)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Refresh")
                .accessibilityLabel("Refresh System Metrics")
                .pointingHandCursor()
            }
        }
        .padding(.horizontal, 2.0)
    }

    private func ringColumn(percent: Double, base: Color, caption: String, detail: String) -> some View {
        VStack(spacing: 6.0) {
            GaugeRingView(
                fraction: percent / 100.0,
                tint: systemLoadTint(percent: percent, base: base),
                valueText: "\(Int(percent.rounded()))%",
                captionText: caption,
                diameter: 92.0
            )
            Text(detail)
                .font(.system(size: 10.0, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func metricIcon(_ systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12.0, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 24.0, height: 24.0)
            .background(RoundedRectangle(cornerRadius: 7.0, style: .continuous).fill(tint.opacity(0.14)))
    }

    private func statusTile(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 9.0) {
            metricIcon(icon, tint: tint)
            VStack(alignment: .leading, spacing: 1.0) {
                Text(title)
                    .font(.system(size: 12.0, weight: .bold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 10.0))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0.0)
        }
        .padding(10.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 12.0, isHovered: false)
    }
}
