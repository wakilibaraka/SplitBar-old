import Foundation

public enum BluetoothDeviceType: String, Codable, Equatable, Sendable {
    case headphones
    case mouse
    case keyboard
    case trackpad
    case phone
    case watch
    case other

    public var iconSystemName: String {
        switch self {
        case .headphones:
            return "headphones"
        case .mouse:
            return "magicmouse.fill"
        case .keyboard:
            return "keyboard.fill"
        case .trackpad:
            return "hand.draw.fill"
        case .phone:
            return "iphone"
        case .watch:
            return "applewatch"
        case .other:
            return "dot.radiowaves.left.and.right"
        }
    }
}

public struct BluetoothDevice: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let isConnected: Bool
    public let batteryPercentage: Int?
    public let deviceType: BluetoothDeviceType

    public init(
        id: String,
        name: String,
        isConnected: Bool,
        batteryPercentage: Int?,
        deviceType: BluetoothDeviceType
    ) {
        self.id = id
        self.name = name
        self.isConnected = isConnected
        self.batteryPercentage = batteryPercentage
        self.deviceType = deviceType
    }
}

public struct BluetoothState: Equatable, Sendable {
    public let isBluetoothEnabled: Bool
    public let devices: [BluetoothDevice]
    public let lastUpdated: Date

    public init(
        isBluetoothEnabled: Bool,
        devices: [BluetoothDevice],
        lastUpdated: Date
    ) {
        self.isBluetoothEnabled = isBluetoothEnabled
        self.devices = devices
        self.lastUpdated = lastUpdated
    }

    public static func defaultSample() -> BluetoothState {
        let sampleDevices: [BluetoothDevice] = [
            BluetoothDevice(
                id: "sample_airpods",
                name: "AirPods Pro",
                isConnected: true,
                batteryPercentage: 88,
                deviceType: .headphones
            ),
            BluetoothDevice(
                id: "sample_mouse",
                name: "Magic Mouse",
                isConnected: true,
                batteryPercentage: 74,
                deviceType: .mouse
            ),
            BluetoothDevice(
                id: "sample_keyboard",
                name: "Magic Keyboard",
                isConnected: false,
                batteryPercentage: nil,
                deviceType: .keyboard
            )
        ]
        return BluetoothState(
            isBluetoothEnabled: true,
            devices: sampleDevices,
            lastUpdated: Date()
        )
    }
}
