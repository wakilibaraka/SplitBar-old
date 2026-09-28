import Carbon.HIToolbox
import Foundation

public final class GlobalShortcutService: @unchecked Sendable {
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actionMap: [UInt32: ShortcutAction] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var currentHandler: (@Sendable (ShortcutAction) -> Void)?
    private var nextHotKeyID: UInt32 = 1

    public init() {
    }

    deinit {
        unregisterAll()
    }

    public func register(
        bindings: [ShortcutBinding],
        handler: @escaping @Sendable (ShortcutAction) -> Void
    ) -> [ShortcutRegistrationResult] {
        unregisterAll()

        let conflicts = shortcutConflicts(bindings: bindings)
        if !conflicts.isEmpty {
            return conflicts.map { .conflict($0) }
        }

        self.currentHandler = handler
        installEventHandlerIfNeeded()

        var results: [ShortcutRegistrationResult] = []

        for binding in bindings {
            let id = nextHotKeyID
            nextHotKeyID += 1

            let hotKeyID = EventHotKeyID(signature: OSType(0x45444543), id: id)
            var hotKeyRef: EventHotKeyRef?

            let status = RegisterEventHotKey(
                binding.chord.carbonKeyCode,
                binding.chord.carbonModifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                hotKeyRefs[id] = ref
                actionMap[id] = binding.action
                results.append(.registered(binding.id))
            } else {
                results.append(.systemFailure(binding.id, status))
            }
        }

        return results
    }

    public func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actionMap.removeAll()
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        currentHandler = nil
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return noErr }

            let service = Unmanaged<GlobalShortcutService>.fromOpaque(userData).takeUnretainedValue()
            if let action = service.actionMap[hotKeyID.id], let handler = service.currentHandler {
                DispatchQueue.main.async {
                    handler(action)
                }
            }
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
    }
}
