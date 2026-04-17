import AppKit
import SwiftUI

/// Manages the floating history panel that appears when Ctrl+V is pressed.
@MainActor
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var isVisible = false

    private var panel: NSPanel?
    private var closeObserver: NSObjectProtocol?
    private var clickOutsideMonitor: Any?

    private init() {}

    // MARK: - Public

    func showHistory() {
        guard !isVisible else {
            dismissHistory()
            return
        }

        isVisible = true

        let historyView = HistoryView()
        let hostingView = NSHostingView(rootView: historyView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.title = NSLocalizedString("history.title", comment: "")
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        // Position near the mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        panel.setFrameOrigin(NSPoint(
            x: mouseLocation.x - 180,
            y: mouseLocation.y - 420
        ))

        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        // Dismiss when the user clicks outside the panel
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return }
            // Convert the click location to the panel's coordinate space and check containment
            let clickLocation = event.locationInWindow
            let screenLocation = event.window?.convertPoint(toScreen: clickLocation) ?? NSEvent.mouseLocation
            if !panel.frame.contains(screenLocation) {
                Task { @MainActor in
                    self.dismissHistory()
                }
            }
        }

        // Stay in sync if the user closes the panel via the close button
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isVisible = false
                self?.panel = nil
                if let obs = self?.closeObserver {
                    NotificationCenter.default.removeObserver(obs)
                    self?.closeObserver = nil
                }
            }
        }
    }

    func dismissHistory() {
        if let obs = closeObserver {
            NotificationCenter.default.removeObserver(obs)
            closeObserver = nil
        }
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        panel?.close()
        panel = nil
        isVisible = false
    }

    /// Called when the user selects an item from the history list.
    /// Writes the item to the clipboard; the user pastes with Cmd+V in their target app.
    func pasteItem(_ item: ClipboardItem) {
        ClipboardService.shared.select(item)
        dismissHistory()
    }
}
