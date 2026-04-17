import Carbon.HIToolbox
import AppKit

/// Registers a global keyboard shortcut (⌘⇧V) via Carbon HIToolbox.
/// This API requires no Accessibility or Input Monitoring permission — App Store safe.
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var isRegistered: Bool { hotKeyRef != nil }

    private init() {}

    // MARK: - Public

    func register() {
        guard hotKeyRef == nil else { return }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x41535443 // 'ASTC'
        hotKeyID.id = 1

        var ref: EventHotKeyRef?
        let err = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard err == noErr, let ref else {
            print("[HotkeyManager] Failed to register ⌘⇧V hotkey (error \(err))")
            return
        }
        hotKeyRef = ref

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventCallback,
            1,
            &spec,
            nil,
            &eventHandlerRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}

// MARK: - Carbon callback

private func hotkeyEventCallback(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async { HistoryManager.shared.showHistory() }
    return noErr
}
