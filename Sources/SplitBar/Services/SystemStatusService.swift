import AppKit
import CoreAudio
import CoreWLAN
import Foundation
import IOKit.ps
import IOBluetooth

public struct SystemStatusSnapshot: Equatable, Sendable {
    public var batteryLevel: Int
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public var wifiOn: Bool
    public var wifiBars: Int
    public var bluetoothOn: Bool
    public var volumeLevel: Double
    public var isMuted: Bool

    public init(
        batteryLevel: Int,
        isCharging: Bool,
        isPluggedIn: Bool,
        wifiOn: Bool,
        wifiBars: Int,
        bluetoothOn: Bool,
        volumeLevel: Double,
        isMuted: Bool
    ) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.wifiOn = wifiOn
        self.wifiBars = wifiBars
        self.bluetoothOn = bluetoothOn
        self.volumeLevel = volumeLevel
        self.isMuted = isMuted
    }

    public static func placeholder() -> SystemStatusSnapshot {
        SystemStatusSnapshot(
            batteryLevel: 100,
            isCharging: false,
            isPluggedIn: true,
            wifiOn: true,
            wifiBars: 3,
            bluetoothOn: true,
            volumeLevel: 0.68,
            isMuted: false
        )
    }
}

@MainActor
public final class SystemStatusService {
    public private(set) var currentSnapshot = SystemStatusSnapshot.placeholder()
    private var timer: Timer?
    private let queryQueue = DispatchQueue(label: "com.baraka.splitbar.systemstatus", qos: .utility)
    private var queryInFlight = false

    public init() {}

    public func startMonitoring(
        interval: TimeInterval,
        onUpdate: @escaping @MainActor @Sendable (SystemStatusSnapshot) -> Void
    ) {
        stopMonitoring()
        onUpdate(currentSnapshot)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshInBackground(onUpdate: onUpdate)
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshInBackground(
        onUpdate: @escaping @MainActor @Sendable (SystemStatusSnapshot) -> Void
    ) {
        guard !queryInFlight else { return }
        queryInFlight = true
        queryQueue.async { [weak self] in
            let snapshot = Self.sampleSnapshot()
            Task { @MainActor in
                guard let self else { return }
                self.queryInFlight = false
                if snapshot != self.currentSnapshot {
                    self.currentSnapshot = snapshot
                    onUpdate(snapshot)
                }
            }
        }
    }

    nonisolated private static func sampleSnapshot() -> SystemStatusSnapshot {
        let battery = sampleBattery()
        let wifi = sampleWiFi()
        let volume = sampleOutputVolume()
        return SystemStatusSnapshot(
            batteryLevel: battery.level,
            isCharging: battery.charging,
            isPluggedIn: battery.plugged,
            wifiOn: wifi.on,
            wifiBars: wifi.bars,
            bluetoothOn: sampleBluetoothPower(),
            volumeLevel: volume.level,
            isMuted: volume.muted
        )
    }

    nonisolated private static func sampleBattery() -> (level: Int, charging: Bool, plugged: Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let firstSource = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, firstSource)?.takeUnretainedValue() as? [String: Any]
        else {
            return (100, false, true)
        }
        let current = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let capacityMax = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let charging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false
        let plugged = (desc[kIOPSPowerSourceStateKey as String] as? String) == (kIOPSACPowerValue as String)
        let level = capacityMax > 0 ? Int((Double(current) / Double(capacityMax)) * 100.0) : 0
        return (min(100, max(0, level)), charging, plugged)
    }

    nonisolated private static func sampleWiFi() -> (on: Bool, bars: Int) {
        guard let interface = CWWiFiClient.shared().interface(),
              interface.powerOn()
        else {
            return (false, 0)
        }
        let rssi = interface.rssiValue()
        let bars: Int
        if rssi >= -60 {
            bars = 3
        } else if rssi >= -70 {
            bars = 2
        } else if rssi >= -80 {
            bars = 1
        } else {
            bars = 0
        }
        return (true, bars)
    }

    nonisolated private static func sampleBluetoothPower() -> Bool {
        guard let controller = IOBluetoothHostController.default() else { return false }
        return controller.powerState == kBluetoothHCIPowerStateON
    }

    nonisolated private static func sampleOutputVolume() -> (level: Double, muted: Bool) {
        var deviceID = AudioDeviceID(0)
        var deviceSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddress, 0, nil, &deviceSize, &deviceID
        ) == noErr, deviceID != 0 else {
            return (0.0, false)
        }

        func scalar(element: UInt32) -> Float32? {
            var value = Float32(0)
            var valueSize = UInt32(MemoryLayout<Float32>.size)
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            guard AudioObjectHasProperty(deviceID, &address),
                  AudioObjectGetPropertyData(deviceID, &address, 0, nil, &valueSize, &value) == noErr
            else {
                return nil
            }
            return value
        }

        func muted(element: UInt32) -> Bool? {
            var value = UInt32(0)
            var valueSize = UInt32(MemoryLayout<UInt32>.size)
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            guard AudioObjectHasProperty(deviceID, &address),
                  AudioObjectGetPropertyData(deviceID, &address, 0, nil, &valueSize, &value) == noErr
            else {
                return nil
            }
            return value != 0
        }

        let level = scalar(element: 1) ?? scalar(element: 0) ?? 0
        let mute = muted(element: 1) ?? muted(element: 0) ?? false
        return (Double(min(1, max(0, level))), mute)
    }

    @discardableResult
    nonisolated static func setOutputVolume(_ level: Double) -> Bool {
        var deviceID = AudioDeviceID(0)
        var deviceSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddress, 0, nil, &deviceSize, &deviceID
        ) == noErr, deviceID != 0 else {
            return false
        }
        for element: UInt32 in [1, 0] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            var value = Float32(min(1, max(0, level)))
            guard AudioObjectHasProperty(deviceID, &address) else { continue }
            let status = AudioObjectSetPropertyData(
                deviceID, &address, 0, nil,
                UInt32(MemoryLayout<Float32>.size), &value
            )
            if status == noErr {
                return true
            }
        }
        return false
    }
}
