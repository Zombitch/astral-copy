import AppKit
import Carbon.HIToolbox

/// Installs a CGEvent tap to intercept Cmd+V and show the clipboard history instead.
@MainActor
final class EventTapManager {
    static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Whether the Cmd+V override is currently active
    var isActive: Bool { eventTap != nil }

    private init() {}

    // MARK: - Public

    func install() {
        guard eventTap == nil else { return }
        guard PermissionsManager.shared.accessibilityGranted else { return }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        // The callback must be a C function pointer — use a static context
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: nil
        )

        guard let tap else {
            print("[EventTapManager] Failed to create event tap — permissions missing?")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func uninstall() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Called by the C callback when macOS disables the tap (e.g. after sleep/timeout).
    func reenableTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// Simulate a real Cmd+V so the frontmost app receives the paste.
    func simulatePaste() {
        // Temporarily disable our tap so we don't intercept our own simulated paste
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        let source = CGEventSource(stateID: .combinedSessionState)

        // Key down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Re-enable after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            if let tap = self?.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
    }
}

// MARK: - C callback

/// Global C-function callback for the CGEvent tap.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // If the tap is disabled by the system (e.g. after sleep), re-enable it
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        DispatchQueue.main.async { EventTapManager.shared.reenableTap() }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // Cmd+V: keyCode 9 with Command modifier, without other modifiers (Shift/Ctrl/Option)
    let isCommandOnly = flags.contains(.maskCommand)
        && !flags.contains(.maskShift)
        && !flags.contains(.maskControl)
        && !flags.contains(.maskAlternate)

    if keyCode == kVK_ANSI_V && isCommandOnly {
        // Show the history picker on the main thread
        DispatchQueue.main.async {
            HistoryManager.shared.showHistory()
        }
        // Block the original Cmd+V
        return nil
    }

    return Unmanaged.passRetained(event)
}
