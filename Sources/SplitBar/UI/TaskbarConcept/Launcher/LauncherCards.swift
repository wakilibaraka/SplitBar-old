import AppKit
import SwiftUI

struct LauncherProcessesCard: View {
    let processes: [TopProcess]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Processes")
                    .font(.system(size: 11, weight: .semibold))
                Spacer(minLength: 4)
                Text("LIVE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
            }
            HStack {
                Text("PROCESS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CORE")
                    .frame(width: 44, alignment: .trailing)
                Text("MEM")
                    .frame(width: 52, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.secondary)
            if processes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 7) {
                    ForEach(0..<processes.count, id: \.self) { index in
                        processRow(processes[index])
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
    }

    private func processRow(_ process: TopProcess) -> some View {
        HStack {
            Text(process.name)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.1f%%", process.cpuPercent))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.green)
                .frame(width: 44, alignment: .trailing)
            Text(memoryText(process.memoryMB))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func memoryText(_ mb: Double) -> String {        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}


struct LauncherBackgroundAppsCard: View {
    private let backgroundApps: [(String, String, Color)] = [
        ("Browser", "1.2 GB", .blue),
        ("Cloud Sync", "640 MB", .purple),
        ("Video Call", "420 MB", .green),
        ("Photo Editor", "310 MB", .orange)
    ]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Background activity", systemImage: "app.badge")
                    .font(.system(size: 11, weight: .semibold))
                Spacer(minLength: 4)
                Text("2.6 GB")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.purple)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * 0.58)
                }
            }
            .frame(height: 5)

            VStack(spacing: 8) {
                ForEach(backgroundApps, id: \.0) { name, memory, tint in
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tint.opacity(0.16))
                            .overlay {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(tint)
                            }
                            .frame(width: 19, height: 19)
                        Text(name)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text(memory)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
    }
}
