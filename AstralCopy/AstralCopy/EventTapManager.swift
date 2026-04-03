import AppKit
import Carbon.HIToolbox

/// Installs a CGEvent tap to intercept Ctrl+V and show the clipboard history instead.
/// Falls back to Ctrl+V via NSEvent global monitor if the event tap can't be created.
@MainActor
final class EventTapManager {
    static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var fallbackMonitor: Any?

    /// Whether the Ctrl+V override is currently active
    var isActive: Bool { eventTap != nil }

    /// Whether we're using the fallback hotkey (Ctrl+V monitor) instead of the full event tap
    var isFallbackMode: Bool { fallbackMonitor != nil && eventTap == nil }

    private init() {}

    // MARK: - Public

    func install() {
        guard eventTap == nil else { return }

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
            print("[EventTapManager] Event tap failed — falling back to Ctrl+V monitor")
            installFallback()
            return
        }

        // Event tap succeeded — remove fallback if it was active
        removeFallback()

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
        removeFallback()
    }

    /// Called by the C callback when macOS disables the tap (e.g. after sleep/timeout).
    func reenableTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// Simulate a real Cmd+V so the frontmost app receives the standard system paste.
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

    // MARK: - Fallback (Cmd+Shift+V)

    /// Registers a global key monitor for Ctrl+V when the event tap isn't available.
    /// This can't block the event (NSEvent monitor is passive), but Ctrl+V has no system default
    /// paste behaviour on macOS, so the history picker still appears without side effects.
    private func installFallback() {
        guard fallbackMonitor == nil else { return }
        fallbackMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let isV = event.keyCode == UInt16(kVK_ANSI_V)
            let hasCtrl = event.modifierFlags.contains(.control)
            let noCmd = !event.modifierFlags.contains(.command)
            let noShift = !event.modifierFlags.contains(.shift)
            let noOpt = !event.modifierFlags.contains(.option)

            if isV && hasCtrl && noCmd && noShift && noOpt {
                DispatchQueue.main.async {
                    HistoryManager.shared.showHistory()
                }
            }
        }
    }

    private func removeFallback() {
        if let monitor = fallbackMonitor {
            NSEvent.removeMonitor(monitor)
            fallbackMonitor = nil
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

    // Ctrl+V: keyCode 9 with Control modifier only (no Cmd/Shift/Option).
    // Cmd+V is intentionally left untouched so standard paste continues to work normally.
    let isControlOnly = flags.contains(.maskControl)
        && !flags.contains(.maskCommand)
        && !flags.contains(.maskShift)
        && !flags.contains(.maskAlternate)

    if keyCode == kVK_ANSI_V && isControlOnly {
        // Show the history picker on the main thread
        DispatchQueue.main.async {
            HistoryManager.shared.showHistory()
        }
        // Block the original Ctrl+V so it doesn't propagate
        return nil
    }

    return Unmanaged.passRetained(event)
}
