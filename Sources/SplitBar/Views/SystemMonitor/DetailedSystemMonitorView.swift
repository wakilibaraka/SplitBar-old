import AppKit
import Foundation
import SwiftUI

public struct DetailedSystemMonitorView: View {
    public let metrics: SystemMetrics
    public let runningApps: [NSRunningApplication]
    public let onRefresh: () -> Void

    @State private var selectedSection: SystemSection? = .overview

    public enum SystemSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case cpu = "CPU"
        case memory = "Memory"
        case network = "Network"
        case disk = "Storage"
        case processes = "Applications"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .overview: return "gauge.with.needle"
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .network: return "network"
            case .disk: return "internaldrive"
            case .processes: return "square.stack.3d.up"
            }
        }

        public var tint: Color {
            switch self {
            case .overview: return SplitBarPalette.silver
            case .cpu: return SplitBarPalette.cyan
            case .memory: return SplitBarPalette.violet
            case .network: return SplitBarPalette.mint
            case .disk: return SplitBarPalette.amber
            case .processes: return SplitBarPalette.terracotta
            }
        }
    }

    public init(
        metrics: SystemMetrics,
        runningApps: [NSRunningApplication],
        onRefresh: @escaping () -> Void
    ) {
        self.metrics = metrics
        self.runningApps = runningApps
        self.onRefresh = onRefresh
    }

    private func gigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / 1_073_741_824.0
    }

    public var body: some View {
        NavigationSplitView {
            List(SystemSection.allCases, selection: $selectedSection) { section in
                Label {
                    Text(section.rawValue)
                        .font(.system(size: 13.0, weight: .medium))
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundColor(section.tint)
                }
                .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180.0, ideal: 200.0, max: 240.0)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            let section = selectedSection ?? .overview
            ScrollView {
                VStack(alignment: .leading, spacing: 18.0) {
                    header(section)
                    switch section {
                    case .overview:
                        overview
                    case .cpu:
                        cpuDetail
                    case .memory:
                        memoryDetail
                    case .network:
                        networkDetail
                    case .disk:
                        diskDetail
                    case .processes:
                        processesDetail
                    }
                }
                .padding(24.0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(backdrop)
            .navigationTitle(section.rawValue)
        }
        .frame(minWidth: 760.0, minHeight: 520.0)
    }

    /// Noir cam temasına uygun, bölüm rengiyle hafifçe aydınlanan arka plan.
    private var backdrop: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            RadialGradient(
                colors: [(selectedSection ?? .overview).tint.opacity(0.14), Color.clear],
                center: .topTrailing,
                startRadius: 10.0,
                endRadius: 520.0
            )
            RadialGradient(
                colors: [SplitBarPalette.violet.opacity(0.06), Color.clear],
                center: .bottomLeading,
                startRadius: 10.0,
                endRadius: 480.0
            )
        }
        .ignoresSafeArea()
    }

    private func header(_ section: SystemSection) -> some View {
        HStack(alignment: .center, spacing: 10.0) {
            Image(systemName: section.icon)
                .font(.system(size: 15.0, weight: .semibold))
                .foregroundColor(section.tint)
                .frame(width: 34.0, height: 34.0)
                .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous).fill(section.tint.opacity(0.15)))
            Text(section.rawValue)
                .font(.system(size: 22.0, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            HStack(spacing: 5.0) {
                Circle()
                    .fill(SplitBarPalette.mint)
                    .frame(width: 6.0, height: 6.0)
                    .shadow(color: SplitBarPalette.mint.opacity(0.8), radius: 3.0)
                Text("Live")
                    .font(.system(size: 11.0, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10.0)
            .padding(.vertical, 5.0)
            .liquidGlassPill(accentColor: SplitBarPalette.mint)
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12.0, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28.0, height: 28.0)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Refresh System Metrics")
            .accessibilityLabel("Refresh System Metrics")
            .pointingHandCursor()
        }
    }

    // MARK: - Overview

    private var overview: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            HStack(spacing: 14.0) {
                overviewRing(
                    percent: metrics.cpu.usagePercent,
                    base: SplitBarPalette.cyan,
                    caption: "CPU",
                    detail: String(format: "User %.0f%% · Sys %.0f%%", metrics.cpu.userPercent, metrics.cpu.systemPercent)
                )
                overviewRing(
                    percent: metrics.memory.usagePercent,
                    base: SplitBarPalette.violet,
                    caption: "Memory",
                    detail: String(format: "%.1f of %.0f GB", gigabytes(metrics.memory.usedBytes), gigabytes(metrics.memory.totalBytes))
                )
                overviewRing(
                    percent: metrics.disk.usagePercent,
                    base: SplitBarPalette.amber,
                    caption: "Storage",
                    detail: String(format: "%.0f GB free", gigabytes(metrics.disk.freeBytes))
                )
            }

            HStack(spacing: 14.0) {
                statCard(
                    icon: "arrow.down.circle.fill",
                    tint: SplitBarPalette.mint,
                    title: "Download",
                    value: metrics.network.formattedDownloadSpeed
                )
                statCard(
                    icon: "arrow.up.circle.fill",
                    tint: SplitBarPalette.cyan,
                    title: "Upload",
                    value: metrics.network.formattedUploadSpeed
                )
            }

            HStack(spacing: 14.0) {
                if let battery = metrics.battery {
                    statCard(
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.75",
                        tint: battery.levelPercent <= 20 ? SplitBarPalette.coral : SplitBarPalette.mint,
                        title: battery.isPluggedIn ? "Power connected" : "On battery",
                        value: "\(battery.levelPercent)%"
                    )
                }
                statCard(
                    icon: "thermometer.medium",
                    tint: metrics.thermal.isThrottling ? SplitBarPalette.coral : SplitBarPalette.mint,
                    title: metrics.thermal.isThrottling ? "Throttling active" : "Thermal pressure",
                    value: metrics.thermal.stateName
                )
            }
        }
    }

    // MARK: - CPU

    private var cpuDetail: some View {
        let idle = max(0.0, 100.0 - metrics.cpu.usagePercent)
        return HStack(alignment: .top, spacing: 16.0) {
            GaugeRingView(
                fraction: metrics.cpu.usagePercent / 100.0,
                tint: systemLoadTint(percent: metrics.cpu.usagePercent, base: SplitBarPalette.cyan),
                valueText: "\(Int(metrics.cpu.usagePercent.rounded()))%",
                captionText: "Total load",
                diameter: 150.0
            )
            .padding(16.0)
            .liquidGlassCard(cornerRadius: 16.0, isHovered: false)

            VStack(alignment: .leading, spacing: 14.0) {
                barRow(title: "User", percent: metrics.cpu.userPercent, tint: SplitBarPalette.cyan)
                barRow(title: "System", percent: metrics.cpu.systemPercent, tint: SplitBarPalette.violet)
                barRow(title: "Idle", percent: idle, tint: SplitBarPalette.silver)
                Divider().opacity(0.4)
                HStack {
                    Label("Thermal state", systemImage: "thermometer.medium")
                        .font(.system(size: 12.0, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(metrics.thermal.stateName)
                        .font(.system(size: 12.0, weight: .semibold))
                        .foregroundColor(metrics.thermal.isThrottling ? SplitBarPalette.coral : SplitBarPalette.mint)
                }
            }
            .padding(16.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: 16.0, isHovered: false)
        }
    }

    // MARK: - Memory

    private var memoryDetail: some View {
        let usedGB = gigabytes(metrics.memory.usedBytes)
        let freeGB = gigabytes(metrics.memory.freeBytes)
        let totalGB = gigabytes(metrics.memory.totalBytes)
        return HStack(alignment: .top, spacing: 16.0) {
            GaugeRingView(
                fraction: metrics.memory.usagePercent / 100.0,
                tint: systemLoadTint(percent: metrics.memory.usagePercent, base: SplitBarPalette.violet),
                valueText: "\(Int(metrics.memory.usagePercent.rounded()))%",
                captionText: "In use",
                diameter: 150.0
            )
            .padding(16.0)
            .liquidGlassCard(cornerRadius: 16.0, isHovered: false)

            VStack(alignment: .leading, spacing: 14.0) {
                valueRow(title: "Used", value: String(format: "%.1f GB", usedGB), tint: SplitBarPalette.violet)
                valueRow(title: "Available", value: String(format: "%.1f GB", freeGB), tint: SplitBarPalette.mint)
                valueRow(title: "Installed", value: String(format: "%.0f GB", totalGB), tint: SplitBarPalette.silver)
                GlassProgressBar(
                    fraction: metrics.memory.usagePercent / 100.0,
                    tint: systemLoadTint(percent: metrics.memory.usagePercent, base: SplitBarPalette.violet),
                    height: 8.0
                )
            }
            .padding(16.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: 16.0, isHovered: false)
        }
    }

    // MARK: - Network

    private var networkDetail: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            HStack(spacing: 14.0) {
                statCard(icon: "arrow.down.circle.fill", tint: SplitBarPalette.mint, title: "Download", value: metrics.network.formattedDownloadSpeed)
                statCard(icon: "arrow.up.circle.fill", tint: SplitBarPalette.cyan, title: "Upload", value: metrics.network.formattedUploadSpeed)
            }
            Text("Aggregate throughput across all active network interfaces, sampled every second.")
                .font(.system(size: 11.0))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Storage

    private var diskDetail: some View {
        let usedGB = gigabytes(metrics.disk.usedBytes)
        let freeGB = gigabytes(metrics.disk.freeBytes)
        let totalGB = gigabytes(metrics.disk.totalBytes)
        return VStack(alignment: .leading, spacing: 14.0) {
            HStack {
                Label("Macintosh HD", systemImage: "internaldrive.fill")
                    .font(.system(size: 14.0, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "%.0f GB of %.0f GB used", usedGB, totalGB))
                    .font(.system(size: 12.0, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            GlassProgressBar(
                fraction: metrics.disk.usagePercent / 100.0,
                tint: systemLoadTint(percent: metrics.disk.usagePercent, base: SplitBarPalette.amber),
                height: 10.0
            )
            HStack {
                valueRow(title: "Used", value: String(format: "%.0f%%", metrics.disk.usagePercent), tint: SplitBarPalette.amber)
                Spacer(minLength: 24.0)
                valueRow(title: "Free", value: String(format: "%.0f GB", freeGB), tint: SplitBarPalette.mint)
            }
        }
        .padding(18.0)
        .liquidGlassCard(cornerRadius: 16.0, isHovered: false)
    }

    // MARK: - Applications

    private var processesDetail: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text("\(runningApps.count) running applications")
                .font(.system(size: 12.0, weight: .medium))
                .foregroundColor(.secondary)
            LazyVStack(spacing: 6.0) {
                ForEach(runningApps, id: \.processIdentifier) { app in
                    HStack(spacing: 12.0) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24.0, height: 24.0)
                        } else {
                            Image(systemName: "app")
                                .frame(width: 24.0, height: 24.0)
                        }
                        VStack(alignment: .leading, spacing: 1.0) {
                            Text(app.localizedName ?? "Unknown")
                                .font(.system(size: 13.0, weight: .medium))
                                .foregroundColor(.primary)
                            Text(app.bundleIdentifier ?? "—")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if app.isActive {
                            Text("Active")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(SplitBarPalette.mint)
                                .padding(.horizontal, 7.0)
                                .padding(.vertical, 2.0)
                                .liquidGlassPill(accentColor: SplitBarPalette.mint)
                        }
                        Text("PID \(String(app.processIdentifier))")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12.0)
                    .padding(.vertical, 8.0)
                    .liquidGlassCard(cornerRadius: 11.0, isHovered: false)
                }
            }
        }
    }

    // MARK: - Building blocks

    private func overviewRing(percent: Double, base: Color, caption: String, detail: String) -> some View {
        VStack(spacing: 10.0) {
            GaugeRingView(
                fraction: percent / 100.0,
                tint: systemLoadTint(percent: percent, base: base),
                valueText: "\(Int(percent.rounded()))%",
                captionText: caption,
                diameter: 112.0
            )
            Text(detail)
                .font(.system(size: 11.0, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 16.0)
        .frame(maxWidth: .infinity)
        .liquidGlassCard(cornerRadius: 16.0, isHovered: false)
    }

    private func statCard(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12.0) {
            Image(systemName: icon)
                .font(.system(size: 16.0, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 36.0, height: 36.0)
                .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous).fill(tint.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2.0) {
                Text(value)
                    .font(.system(size: 18.0, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                Text(title)
                    .font(.system(size: 11.0))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0.0)
        }
        .padding(14.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 14.0, isHovered: false)
    }

    private func barRow(title: String, percent: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6.0) {
            HStack {
                Text(title)
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", percent))
                    .font(.system(size: 12.0, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }
            GlassProgressBar(fraction: percent / 100.0, tint: tint, height: 6.0)
        }
    }

    private func valueRow(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 8.0) {
            Circle()
                .fill(tint)
                .frame(width: 7.0, height: 7.0)
            Text(title)
                .font(.system(size: 12.0, weight: .medium))
                .foregroundColor(.secondary)
            Spacer(minLength: 12.0)
            Text(value)
                .font(.system(size: 13.0, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }
}
