import AppKit
import CoreGraphics
import Darwin
import Foundation
import IOKit
import IOKit.ps

public protocol DisplayBrightnessControlling: Sendable {
    var displayName: String { get }
    var isAvailable: Bool { get }
    func currentLevel() -> Double?
    func setLevel(_ level: Double) -> Bool
}

public struct UnavailableBrightnessService: DisplayBrightnessControlling, Sendable {
    public let displayName = "No controllable display"
    public var isAvailable: Bool { false }
    public init() {}
    public func currentLevel() -> Double? { nil }
    public func setLevel(_ level: Double) -> Bool { false }
}

public struct SystemBrightnessService: DisplayBrightnessControlling, Sendable {
    public let displayName = "Display brightness"
    public init() {}

    public var isAvailable: Bool {
        currentLevel() != nil
    }

    public func currentLevel() -> Double? {
        withBrightnessService { port in
            var value: Float = 0
            guard IODisplayGetFloatParameter(port, 0, kIODisplayBrightnessKey as CFString, &value) == kIOReturnSuccess else {
                return nil
            }
            return Double(value)
        }
    }

    public func setLevel(_ level: Double) -> Bool {
        withBrightnessService { port in
            IODisplaySetFloatParameter(port, 0, kIODisplayBrightnessKey as CFString, Float(min(1, max(0, level)))) == kIOReturnSuccess
        } ?? false
    }

    private func withBrightnessService<T>(_ body: (io_service_t) -> T?) -> T? {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("IODisplayConnect"),
              IOServiceGetMatchingServices(0, matching, &iterator) == kIOReturnSuccess else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        while case let candidate = IOIteratorNext(iterator), candidate != 0 {
            defer { IOObjectRelease(candidate) }
            if let result = body(candidate) {
                return result
            }
        }
        return nil
    }
}

public final class DDCBrightnessService: DisplayBrightnessControlling, @unchecked Sendable {
    public let displayName: String
    private let displayID: CGDirectDisplayID
    private let ioService: IOAVServiceFunctionSet?
    private let queue = DispatchQueue(label: "com.baraka.splitbar.ddc", qos: .utility)

    public init?(displayID: CGDirectDisplayID) {
        guard let functions = DDCBrightnessService.loadPrivateFunctions() else {
            return nil
        }
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: 8)
        var displayCount: UInt32 = 0
        guard CGGetOnlineDisplayList(8, &onlineDisplays, &displayCount) == .success,
              onlineDisplays.prefix(Int(displayCount)).contains(displayID),
              displayID != CGMainDisplayID() || !SystemBrightnessService().isAvailable
        else {
            return nil
        }
        self.displayID = displayID
        self.ioService = functions
        self.displayName = "External display"
    }

    public var isAvailable: Bool { ioService != nil }

    public func currentLevel() -> Double? {
        readVCP(feature: 0x10)?.current
    }

    public func setLevel(_ level: Double) -> Bool {
        writeVCP(feature: 0x10, value: UInt16((min(1, max(0, level)) * 100).rounded()))
    }

    private static let candidateFrameworks = [
        "/System/Library/PrivateFrameworks/AppleMCCSControl.framework/Versions/Current/AppleMCCSControl",
        "/System/Library/PrivateFrameworks/DisplayServices.framework/Versions/Current/DisplayServices"
    ]

    private static func loadPrivateFunctions() -> IOAVServiceFunctionSet? {
        for path in candidateFrameworks {
            guard let handle = dlopen(path, RTLD_LAZY),
                  let create = dlsym(handle, "IOAVServiceCreateWithService"),
                  let read = dlsym(handle, "IOAVServiceReadI2C"),
                  let write = dlsym(handle, "IOAVServiceWriteI2C")
            else {
                continue
            }
            typealias CreateFn = @convention(c) (CFAllocator?, io_service_t) -> Unmanaged<AnyObject>?
            typealias ReadFn = @convention(c) (AnyObject?, UInt32, UInt32, UnsafeMutableRawPointer?, UInt32) -> Int32
            typealias WriteFn = @convention(c) (AnyObject?, UInt32, UInt32, UnsafeRawPointer?, UInt32) -> Int32
            let createFn = unsafeBitCast(create, to: CreateFn.self)
            let readFn = unsafeBitCast(read, to: ReadFn.self)
            let writeFn = unsafeBitCast(write, to: WriteFn.self)
            return IOAVServiceFunctionSet(handle: handle, create: createFn, read: readFn, write: writeFn)
        }
        return nil
    }

    private func ioServiceForDisplay() -> AnyObject? {
        guard let functions = ioService else { return nil }
        let targetVendor = CGDisplayVendorNumber(displayID)
        let targetModel = CGDisplayModelNumber(displayID)
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("IODisplayConnect"),
              IOServiceGetMatchingServices(0, matching, &iterator) == kIOReturnSuccess
        else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        while case let candidate = IOIteratorNext(iterator), candidate != 0 {
            defer { IOObjectRelease(candidate) }
            guard let vendor = IORegistryEntryCreateCFProperty(candidate, kDisplayVendorID as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber,
                  let model = IORegistryEntryCreateCFProperty(candidate, kDisplayProductID as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber,
                  vendor.uint32Value == targetVendor,
                  model.uint32Value == targetModel
            else {
                continue
            }
            return functions.create(nil, candidate)?.takeRetainedValue()
        }
        return nil
    }

    private func ddcChecksum(_ bytes: [UInt8]) -> UInt8 {
        bytes.reduce(0, ^)
    }

    private func writeVCP(feature: UInt8, value: UInt16) -> Bool {
        guard let functions = ioService,
              let service = ioServiceForDisplay() else {
            return false
        }
        let high = UInt8((value >> 8) & 0xFF)
        let low = UInt8(value & 0xFF)
        var packet: [UInt8] = [0x6E, 0x51, 0x84, 0x03, feature, high, low]
        packet.append(ddcChecksum(packet))
        return packet.withUnsafeBufferPointer { buffer in
            functions.write(service, 0x37, 0x51, buffer.baseAddress, UInt32(buffer.count)) == 0
        }
    }

    private func readVCP(feature: UInt8) -> (current: Double, maximum: Double)? {
        guard let functions = ioService,
              let service = ioServiceForDisplay() else {
            return nil
        }
        var request: [UInt8] = [0x6E, 0x51, 0x82, 0x01, feature]
        request.append(ddcChecksum(request))
        let wrote = request.withUnsafeBufferPointer { buffer in
            functions.write(service, 0x37, 0x51, buffer.baseAddress, UInt32(buffer.count)) == 0
        }
        guard wrote else { return nil }
        let replySize: UInt32 = 12
        let replyBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(replySize), alignment: 1)
        defer { replyBuffer.deallocate() }
        guard functions.read(service, 0x37, 0x6F, replyBuffer, replySize) == 0 else {
            return nil
        }
        let bytes = Array(UnsafeBufferPointer(start: replyBuffer.assumingMemoryBound(to: UInt8.self), count: Int(replySize)))
        guard bytes.count >= 11, bytes[2] == 0x02, bytes[4] == feature else {
            return nil
        }
        let maximum = Double(UInt16(bytes[6]) << 8 | UInt16(bytes[7]))
        let current = Double(UInt16(bytes[8]) << 8 | UInt16(bytes[9]))
        guard maximum > 0 else { return nil }
        return (current / maximum, maximum)
    }
}

private struct IOAVServiceFunctionSet {
    let handle: UnsafeMutableRawPointer
    let create: @convention(c) (CFAllocator?, io_service_t) -> Unmanaged<AnyObject>?
    let read: @convention(c) (AnyObject?, UInt32, UInt32, UnsafeMutableRawPointer?, UInt32) -> Int32
    let write: @convention(c) (AnyObject?, UInt32, UInt32, UnsafeRawPointer?, UInt32) -> Int32
}

public enum DisplayBrightness {
    public static func builtIn() -> (any DisplayBrightnessControlling)? {
        let service = SystemBrightnessService()
        return service.isAvailable ? service : nil
    }

    public static func externalDDC() -> (any DisplayBrightnessControlling)? {
        for displayID in onlineDisplayIDs() where displayID != CGMainDisplayID() {
            if let service = DDCBrightnessService(displayID: displayID) {
                return service
            }
        }
        return nil
    }

    public static func externalDisplayCount() -> Int {
        onlineDisplayIDs().filter { $0 != CGMainDisplayID() }.count
    }

    private static func onlineDisplayIDs() -> [CGDirectDisplayID] {
        var displays = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(8, &displays, &count) == .success else {
            return []
        }
        return Array(displays.prefix(Int(count)))
    }
}
