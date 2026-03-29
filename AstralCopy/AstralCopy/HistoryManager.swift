import AppKit
import SwiftUI

/// Manages the floating history panel that appears when Cmd+V is pressed.
@MainActor
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var isVisible = false

    private var panel: NSPanel?
    private var closeObserver: NSObjectProtocol?

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

        // Stay in sync if the user closes the panel via the close button or clicking away
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.isVisible = false
            self?.panel = nil
            if let obs = self?.closeObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.closeObserver = nil
            }
        }
    }

    func dismissHistory() {
        if let obs = closeObserver {
            NotificationCenter.default.removeObserver(obs)
            closeObserver = nil
        }
        panel?.close()
        panel = nil
        isVisible = false
    }

    /// Called when the user selects an item from the history list.
    func pasteItem(_ item: ClipboardItem) {
        ClipboardService.shared.select(item)
        dismissHistory()

        // Small delay to let the pasteboard update before simulating paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            EventTapManager.shared.simulatePaste()
        }
    }
}
