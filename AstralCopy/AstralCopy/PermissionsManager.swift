import AppKit
import SwiftUI

/// Manages the first-launch onboarding window.
/// No TCC permissions are requested — the app works without Accessibility or Input Monitoring.
@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    private var onboardingWindow: NSWindow?

    private init() {}

    // MARK: - Public

    func showOnboarding() {
        guard onboardingWindow == nil else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = NSHostingView(rootView: OnboardingView())
        window.title = NSLocalizedString("onboarding.title", comment: "")
        window.isReleasedWhenClosed = false
        // Prevent macOS from hiding the window when another app becomes foreground
        // — default for .accessory apps is to hide windows on deactivation.
        window.hidesOnDeactivate = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    func dismissOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
