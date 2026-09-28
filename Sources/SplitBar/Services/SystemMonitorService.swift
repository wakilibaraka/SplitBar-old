import Darwin
import Foundation
import IOKit.ps
import MachO

@MainActor
public final class SystemMonitorService {
    private var previousCPUTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    private var previousNetworkSample: (inBytes: UInt64, outBytes: UInt64, timestamp: Date)?
    private var timer: Timer?

    public init() {}

    public func sampleMetrics() -> SystemMetrics {
        let cpu = sampleCPU()
        let memory = sampleMemory()
        let disk = sampleDisk()
        let battery = sampleBattery()
        let thermal = sampleThermal()
        let network = sampleNetwork()

        return SystemMetrics(
            cpu: cpu,
            memory: memory,
            disk: disk,
            battery: battery,
            thermal: thermal,
            network: network
        )
    }

    public func startMonitoring(
        interval: TimeInterval,
        onUpdate: @escaping @MainActor @Sendable (SystemMetrics) -> Void
    ) {
        stopMonitoring()
        onUpdate(sampleMetrics())
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                onUpdate(self.sampleMetrics())
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func sampleCPU() -> SystemCPUMetrics {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()

        let result = withUnsafeMutablePointer(to: &cpuLoad) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(host, HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return SystemCPUMetrics(usagePercent: 0.0, userPercent: 0.0, systemPercent: 0.0)
        }

        let currentTicks = (
            user: cpuLoad.cpu_ticks.0,
            system: cpuLoad.cpu_ticks.1,
            idle: cpuLoad.cpu_ticks.2,
            nice: cpuLoad.cpu_ticks.3
        )

        guard let prev = previousCPUTicks else {
            previousCPUTicks = currentTicks
            let total = currentTicks.user + currentTicks.system + currentTicks.idle + currentTicks.nice
            guard total > 0 else {
                return SystemCPUMetrics(usagePercent: 0.0, userPercent: 0.0, systemPercent: 0.0)
            }
            let active = currentTicks.user + currentTicks.system + currentTicks.nice
            let usage = min(100.0, max(0.0, (Double(active) / Double(total)) * 100.0))
            let user = min(100.0, max(0.0, (Double(currentTicks.user) / Double(total)) * 100.0))
            let system = min(100.0, max(0.0, (Double(currentTicks.system) / Double(total)) * 100.0))
            return SystemCPUMetrics(usagePercent: usage, userPercent: user, systemPercent: system)
        }

        let userDelta = currentTicks.user >= prev.user ? currentTicks.user - prev.user : 0
        let systemDelta = currentTicks.system >= prev.system ? currentTicks.system - prev.system : 0
        let idleDelta = currentTicks.idle >= prev.idle ? currentTicks.idle - prev.idle : 0
        let niceDelta = currentTicks.nice >= prev.nice ? currentTicks.nice - prev.nice : 0
        previousCPUTicks = currentTicks

        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
        guard totalDelta > 0 else {
            return SystemCPUMetrics(usagePercent: 0.0, userPercent: 0.0, systemPercent: 0.0)
        }

        let activeDelta = userDelta + systemDelta + niceDelta
        let usage = min(100.0, max(0.0, (Double(activeDelta) / Double(totalDelta)) * 100.0))
        let user = min(100.0, max(0.0, (Double(userDelta) / Double(totalDelta)) * 100.0))
        let system = min(100.0, max(0.0, (Double(systemDelta) / Double(totalDelta)) * 100.0))

        return SystemCPUMetrics(usagePercent: usage, userPercent: user, systemPercent: system)
    }

    private func sampleMemory() -> SystemMemoryMetrics {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(host, HOST_VM_INFO64, intPtr, &count)
            }
        }

        let total = ProcessInfo.processInfo.physicalMemory
        guard result == KERN_SUCCESS else {
            return SystemMemoryMetrics(
                usedBytes: 0,
                totalBytes: total,
                usagePercent: 0.0,
                freeBytes: total
            )
        }

        let pageSize = UInt64(getpagesize())
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let used = min(total, active + wired + compressed)
        let free = total > used ? total - used : 0
        let usagePercent = total > 0 ? min(100.0, max(0.0, (Double(used) / Double(total)) * 100.0)) : 0.0

        return SystemMemoryMetrics(
            usedBytes: used,
            totalBytes: total,
            usagePercent: usagePercent,
            freeBytes: free
        )
    }

    private func sampleDisk() -> SystemDiskMetrics {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            let total = (attrs[.systemSize] as? NSNumber)?.uint64Value ?? 0
            let free = (attrs[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            let used = total >= free ? total - free : 0
            let usagePercent = total > 0 ? min(100.0, max(0.0, (Double(used) / Double(total)) * 100.0)) : 0.0

            return SystemDiskMetrics(
                usedBytes: used,
                totalBytes: total,
                usagePercent: usagePercent,
                freeBytes: free
            )
        } catch {
            return SystemDiskMetrics(usedBytes: 0, totalBytes: 1, usagePercent: 0.0, freeBytes: 1)
        }
    }

    private func sampleBattery() -> SystemBatteryMetrics? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let firstSource = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, firstSource)?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }

        let currentCapacity = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false
        let isPluggedIn = (desc[kIOPSPowerSourceStateKey as String] as? String) == (kIOPSACPowerValue as String)

        let percent = maxCapacity > 0 ? Int((Double(currentCapacity) / Double(maxCapacity)) * 100.0) : 0
        return SystemBatteryMetrics(
            levelPercent: percent,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn
        )
    }

    private func sampleThermal() -> SystemThermalMetrics {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            return SystemThermalMetrics(stateName: "Nominal", isThrottling: false)
        case .fair:
            return SystemThermalMetrics(stateName: "Fair", isThrottling: false)
        case .serious:
            return SystemThermalMetrics(stateName: "Serious", isThrottling: true)
        case .critical:
            return SystemThermalMetrics(stateName: "Critical", isThrottling: true)
        @unknown default:
            return SystemThermalMetrics(stateName: "Normal", isThrottling: false)
        }
    }

    private func sampleNetwork() -> SystemNetworkMetrics {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return SystemNetworkMetrics(bytesInPerSecond: 0, bytesOutPerSecond: 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            if (flags & IFF_UP) != 0 && (flags & IFF_LOOPBACK) == 0 {
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = current.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        totalIn += UInt64(networkData.pointee.ifi_ibytes)
                        totalOut += UInt64(networkData.pointee.ifi_obytes)
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        let now = Date()
        guard let prev = previousNetworkSample else {
            previousNetworkSample = (inBytes: totalIn, outBytes: totalOut, timestamp: now)
            return SystemNetworkMetrics(bytesInPerSecond: 0, bytesOutPerSecond: 0)
        }

        let interval = now.timeIntervalSince(prev.timestamp)
        previousNetworkSample = (inBytes: totalIn, outBytes: totalOut, timestamp: now)

        guard interval > 0.05 else {
            return SystemNetworkMetrics(bytesInPerSecond: 0, bytesOutPerSecond: 0)
        }

        let inDelta = totalIn >= prev.inBytes ? totalIn - prev.inBytes : 0
        let outDelta = totalOut >= prev.outBytes ? totalOut - prev.outBytes : 0

        let inRate = UInt64(Double(inDelta) / interval)
        let outRate = UInt64(Double(outDelta) / interval)

        return SystemNetworkMetrics(bytesInPerSecond: inRate, bytesOutPerSecond: outRate)
    }
}
