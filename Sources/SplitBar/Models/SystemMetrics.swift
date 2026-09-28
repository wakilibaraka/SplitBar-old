import Foundation

public struct SystemCPUMetrics: Equatable, Sendable {
    public let usagePercent: Double
    public let userPercent: Double
    public let systemPercent: Double

    public init(
        usagePercent: Double,
        userPercent: Double,
        systemPercent: Double
    ) {
        self.usagePercent = usagePercent
        self.userPercent = userPercent
        self.systemPercent = systemPercent
    }
}

public struct SystemMemoryMetrics: Equatable, Sendable {
    public let usedBytes: UInt64
    public let totalBytes: UInt64
    public let usagePercent: Double
    public let freeBytes: UInt64

    public init(
        usedBytes: UInt64,
        totalBytes: UInt64,
        usagePercent: Double,
        freeBytes: UInt64
    ) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.usagePercent = usagePercent
        self.freeBytes = freeBytes
    }
}

public struct SystemDiskMetrics: Equatable, Sendable {
    public let usedBytes: UInt64
    public let totalBytes: UInt64
    public let usagePercent: Double
    public let freeBytes: UInt64

    public init(
        usedBytes: UInt64,
        totalBytes: UInt64,
        usagePercent: Double,
        freeBytes: UInt64
    ) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.usagePercent = usagePercent
        self.freeBytes = freeBytes
    }
}

public struct SystemBatteryMetrics: Equatable, Sendable {
    public let levelPercent: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool

    public init(
        levelPercent: Int,
        isCharging: Bool,
        isPluggedIn: Bool
    ) {
        self.levelPercent = levelPercent
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
    }
}

public struct SystemThermalMetrics: Equatable, Sendable {
    public let stateName: String
    public let isThrottling: Bool

    public init(
        stateName: String,
        isThrottling: Bool
    ) {
        self.stateName = stateName
        self.isThrottling = isThrottling
    }
}

public struct SystemNetworkMetrics: Equatable, Sendable {
    public let bytesInPerSecond: UInt64
    public let bytesOutPerSecond: UInt64

    public init(
        bytesInPerSecond: UInt64,
        bytesOutPerSecond: UInt64
    ) {
        self.bytesInPerSecond = bytesInPerSecond
        self.bytesOutPerSecond = bytesOutPerSecond
    }

    public var formattedDownloadSpeed: String {
        formatBytesRate(bytes: bytesInPerSecond)
    }

    public var formattedUploadSpeed: String {
        formatBytesRate(bytes: bytesOutPerSecond)
    }

    private func formatBytesRate(bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes) B/s"
        } else if bytes < 1024 * 1024 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.1f KB/s", kb)
        } else {
            let mb = Double(bytes) / (1024.0 * 1024.0)
            return String(format: "%.1f MB/s", mb)
        }
    }
}

public struct SystemMetrics: Equatable, Sendable {
    public let cpu: SystemCPUMetrics
    public let memory: SystemMemoryMetrics
    public let disk: SystemDiskMetrics
    public let battery: SystemBatteryMetrics?
    public let thermal: SystemThermalMetrics
    public let network: SystemNetworkMetrics

    public init(
        cpu: SystemCPUMetrics,
        memory: SystemMemoryMetrics,
        disk: SystemDiskMetrics,
        battery: SystemBatteryMetrics?,
        thermal: SystemThermalMetrics,
        network: SystemNetworkMetrics
    ) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.battery = battery
        self.thermal = thermal
        self.network = network
    }
}
