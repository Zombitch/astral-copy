import AppKit
import SwiftUI

// MARK: - ClipboardItem

/// Represents a single clipboard entry (text or image).
struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let content: Content
    let date: Date

    enum Content: Equatable {
        case text(String)
        case image(NSImage)

        static func == (lhs: Content, rhs: Content) -> Bool {
            switch (lhs, rhs) {
            case let (.text(a), .text(b)):
                return a == b
            case let (.image(a), .image(b)):
                return a.tiffRepresentation == b.tiffRepresentation
            default:
                return false
            }
        }
    }
}

// MARK: - ClipboardService

/// Monitors the system pasteboard and stores the last 50 items.
@MainActor
final class ClipboardService: ObservableObject {
    static let shared = ClipboardService()

    @Published private(set) var history: [ClipboardItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    static let maxItems = 50

    private init() {
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Public API

    func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForChanges()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func clearHistory() {
        history.removeAll()
    }

    func remove(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
    }

    /// Write the selected item to the pasteboard so the next Cmd+V simulates a real paste.
    func select(_ item: ClipboardItem) {
        // Temporarily stop monitoring so we don't re-capture our own write
        let savedChangeCount = pasteboard.changeCount

        pasteboard.clearContents()

        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            if let tiff = image.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
        }

        // Update change count so the next poll doesn't treat this as a new copy
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Private

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if let item = readFromPasteboard() {
            // Deduplicate: remove identical earlier entry
            history.removeAll { $0.content == item.content }
            history.insert(item, at: 0)

            // Cap at max
            if history.count > Self.maxItems {
                history = Array(history.prefix(Self.maxItems))
            }
        }
    }

    private func readFromPasteboard() -> ClipboardItem? {
        // Try text first
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            return ClipboardItem(id: UUID(), content: .text(string), date: Date())
        }

        // Try image types
        let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]
        for type in imageTypes {
            if let data = pasteboard.data(forType: type),
               let image = NSImage(data: data) {
                return ClipboardItem(id: UUID(), content: .image(image), date: Date())
            }
        }

        return nil
    }
}
