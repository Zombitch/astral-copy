import AppKit
import SwiftUI

/// Manages the floating history panel that appears when Cmd+V is pressed.
@MainActor
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var isVisible = false

    private var panel: NSPanel?

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
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .hudWindow],
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
    }

    func dismissHistory() {
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
