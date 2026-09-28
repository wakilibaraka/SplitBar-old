import SwiftUI

public struct BluetoothFlyoutView: View {
    public let state: BluetoothState
    public let onConnect: (String) -> Void
    public let onDisconnect: (String) -> Void
    public let onRefresh: () -> Void

    public init(
        state: BluetoothState,
        onConnect: @escaping (String) -> Void,
        onDisconnect: @escaping (String) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.state = state
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(spacing: 12.0) {
            // Status Header
            HStack {
                HStack(spacing: 6.0) {
                    Circle()
                        .fill(state.isBluetoothEnabled ? Color.green : Color.secondary)
                        .frame(width: 8.0, height: 8.0)
                    Text(state.isBluetoothEnabled ? "Bluetooth Active" : "Bluetooth Off")
                        .font(.system(size: 12.0, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    onRefresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh Bluetooth Devices")
                        .font(.system(size: 11.0, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.horizontal, 4.0)

            // Devices List
            if state.devices.isEmpty {
                VStack(spacing: 8.0) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 28.0))
                        .foregroundColor(.secondary)
                    Text("No paired Bluetooth devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120.0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8.0) {
                        ForEach(state.devices) { device in
                            HStack(spacing: 10.0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                                        .fill(device.isConnected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
                                        .frame(width: 32.0, height: 32.0)
                                    Image(systemName: device.deviceType.iconSystemName)
                                        .font(.system(size: 15.0))
                                        .foregroundColor(device.isConnected ? .accentColor : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 2.0) {
                                    Text(device.name)
                                        .font(.system(size: 13.0, weight: .medium))
                                        .lineLimit(1)

                                    HStack(spacing: 6.0) {
                                        Text(device.isConnected ? "Connected" : "Not Connected")
                                            .font(.system(size: 11.0))
                                            .foregroundColor(device.isConnected ? .green : .secondary)

                                        if let battery = device.batteryPercentage {
                                            Text("•")
                                                .font(.system(size: 9.0))
                                                .foregroundColor(.secondary)
                                            HStack(spacing: 2.0) {
                                                Image(systemName: batterySymbol(percentage: battery))
                                                    .font(.system(size: 10.0))
                                                Text("\(battery)%")
                                                    .font(.system(size: 10.0, weight: .medium))
                                            }
                                            .foregroundColor(batteryColor(percentage: battery))
                                        }
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    if device.isConnected {
                                        onDisconnect(device.id)
                                    } else {
                                        onConnect(device.id)
                                    }
                                }) {
                                    Text(device.isConnected ? "Disconnect" : "Connect")
                                        .font(.system(size: 11.0, weight: .medium))
                                        .padding(.horizontal, 8.0)
                                        .padding(.vertical, 4.0)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                                                .fill(device.isConnected ? Color.red.opacity(0.12) : Color.accentColor.opacity(0.12))
                                        )
                                        .foregroundColor(device.isConnected ? .red : .accentColor)
                                }
                                .buttonStyle(.plain)
                                .pointingHandCursor()
                            }
                            .padding(8.0)
                            .liquidGlassCard(cornerRadius: 12.0, isHovered: false)
                        }
                    }
                }
                .frame(maxHeight: 280.0)
            }

            Divider()
                .opacity(0.5)

            // Footer note
            HStack {
                Image(systemName: "lock.shield")
                    .font(.system(size: 11.0))
                    .foregroundColor(.secondary)
                Text("Native IOBluetooth Bridge")
                    .font(.system(size: 11.0))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4.0)
        }
    }

    private func batterySymbol(percentage: Int) -> String {
        if percentage >= 75 {
            return "battery.100"
        } else if percentage >= 50 {
            return "battery.75"
        } else if percentage >= 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private func batteryColor(percentage: Int) -> Color {
        if percentage > 20 {
            return .secondary
        } else {
            return .red
        }
    }
}
