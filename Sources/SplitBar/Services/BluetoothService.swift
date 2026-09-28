import Foundation
import IOBluetooth
import IOKit
import OSLog

@MainActor
public final class BluetoothService {
    public private(set) var currentState: BluetoothState
    private var pendingConnections: [String: BluetoothConnectionObserver] = [:]

    public init(initialState: BluetoothState) {
        self.currentState = initialState
    }

    public func fetchCurrentState() -> BluetoothState {
        // Fast-path in unit test environments where IOBluetooth daemon runloop is unavailable
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil {
            return currentState
        }

        let isEnabled = IOBluetoothHostController.default()?.powerState == kBluetoothHCIPowerStateON
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            Logger.general.error("Bluetooth: pairedDevices() returned nil; Bluetooth permission may be denied")
            let unavailable = BluetoothState(isBluetoothEnabled: isEnabled, devices: [], lastUpdated: Date())
            self.currentState = unavailable
            return unavailable
        }

        let batteryByAddress = Self.batteryPercentagesByAddress()
        let devices: [BluetoothDevice] = paired.compactMap { device in
            guard let address = device.addressString else {
                return nil
            }
            return BluetoothDevice(
                id: address,
                name: device.nameOrAddress ?? address,
                isConnected: device.isConnected(),
                batteryPercentage: batteryByAddress[Self.normalizedAddress(address)],
                deviceType: Self.determineDeviceType(device: device)
            )
        }
        .sorted { lhs, rhs in
            // Bağlı cihazlar önce, ardından alfabetik
            if lhs.isConnected != rhs.isConnected {
                return lhs.isConnected
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        let updated = BluetoothState(
            isBluetoothEnabled: isEnabled,
            devices: devices,
            lastUpdated: Date()
        )
        self.currentState = updated
        return updated
    }

    /// Bağlantıyı asenkron açar; IOBluetooth'un senkron `openConnection()` çağrısı saniyelerce ana thread'i bloke eder.
    /// `onComplete`, bağlantı denemesi sonuçlandığında ana thread'de çağrılır.
    public func connect(deviceID: String, onComplete: @escaping @MainActor () -> Void) {
        guard let device = pairedDevice(address: deviceID) else {
            Logger.general.error("Bluetooth connect: paired device not found address=\(deviceID, privacy: .public)")
            onComplete()
            return
        }
        let observer = BluetoothConnectionObserver { [weak self] status in
            if status != kIOReturnSuccess {
                Logger.general.error("Bluetooth connect failed address=\(deviceID, privacy: .public) status=\(status, privacy: .public)")
            }
            self?.pendingConnections[deviceID] = nil
            _ = self?.fetchCurrentState()
            onComplete()
        }
        pendingConnections[deviceID] = observer
        let startStatus = device.openConnection(observer)
        if startStatus != kIOReturnSuccess {
            Logger.general.error("Bluetooth connect could not start address=\(deviceID, privacy: .public) status=\(startStatus, privacy: .public)")
            pendingConnections[deviceID] = nil
            onComplete()
        }
    }

    public func disconnect(deviceID: String) {
        guard let device = pairedDevice(address: deviceID) else {
            Logger.general.error("Bluetooth disconnect: paired device not found address=\(deviceID, privacy: .public)")
            return
        }
        let status = device.closeConnection()
        if status != kIOReturnSuccess {
            Logger.general.error("Bluetooth disconnect failed address=\(deviceID, privacy: .public) status=\(status, privacy: .public)")
        }
        _ = fetchCurrentState()
    }

    private func pairedDevice(address: String) -> IOBluetoothDevice? {
        (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice])?
            .first { $0.addressString == address }
    }

    /// IOBluetooth adresleri "aa-bb-cc-dd-ee-ff", IORegistry adresleri "AA:BB:..." biçiminde olabilir.
    public static nonisolated func normalizedAddress(_ address: String) -> String {
        address.lowercased().replacingOccurrences(of: ":", with: "-")
    }

    /// macOS'un Bluetooth HID cihazları (Magic Mouse/Keyboard/Trackpad vb.) için yayınladığı gerçek pil yüzdelerini okur.
    /// Pil bilgisi yayınlamayan cihazlar sözlükte yer almaz ve arayüzde pil gösterilmez.
    public static nonisolated func batteryPercentagesByAddress() -> [String: Int] {
        var iterator: io_iterator_t = 0
        let matchStatus = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleDeviceManagementHIDEventService"),
            &iterator
        )
        guard matchStatus == KERN_SUCCESS else {
            Logger.general.error("Bluetooth battery: IORegistry query failed status=\(matchStatus, privacy: .public)")
            return [:]
        }
        defer { IOObjectRelease(iterator) }

        var result: [String: Int] = [:]
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            guard
                let percent = IORegistryEntryCreateCFProperty(service, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? Int,
                let address = IORegistryEntryCreateCFProperty(service, "DeviceAddress" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String
            else {
                continue
            }
            result[normalizedAddress(address)] = percent
        }
        return result
    }

    public static nonisolated func determineDeviceType(device: IOBluetoothDevice) -> BluetoothDeviceType {
        let name = (device.name ?? "").lowercased()
        if name.contains("airpod") || name.contains("headphone") || name.contains("buds") || name.contains("beats") {
            return .headphones
        }
        if name.contains("mouse") {
            return .mouse
        }
        if name.contains("keyboard") || name.contains("keychron") {
            return .keyboard
        }
        if name.contains("trackpad") {
            return .trackpad
        }
        if name.contains("iphone") {
            return .phone
        }
        if name.contains("watch") {
            return .watch
        }
        return .other
    }
}

/// IOBluetooth'un asenkron `openConnection(_:)` çağrısı için Objective-C geri çağrı hedefi.
private final class BluetoothConnectionObserver: NSObject {
    private let onComplete: @MainActor (IOReturn) -> Void

    init(onComplete: @escaping @MainActor (IOReturn) -> Void) {
        self.onComplete = onComplete
    }

    @objc(connectionComplete:status:)
    func connectionComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        let onComplete = self.onComplete
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                onComplete(status)
            }
        }
    }
}
