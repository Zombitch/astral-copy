import AppKit
import SwiftUI

/// Manages TCC permission checks and the first-launch onboarding flow.
@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published var accessibilityGranted: Bool = false
    @Published var inputMonitoringGranted: Bool = false

    var allPermissionsGranted: Bool {
        accessibilityGranted && inputMonitoringGranted
    }

    private var onboardingWindow: NSWindow?

    private init() {
        refreshStatus()
    }

    // MARK: - Public

    func refreshStatus() {
        accessibilityGranted = AXIsProcessTrusted()
        // Input monitoring is implicitly tested when the event tap succeeds;
        // there's no public API to query it directly, so we approximate.
        inputMonitoringGranted = accessibilityGranted
    }

    func showOnboarding() {
        guard onboardingWindow == nil else { return }

        let view = OnboardingView()
        let hostingView = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = NSLocalizedString("onboarding.title", comment: "")
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Bring our app to front for the onboarding
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    func dismissOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }

    // MARK: - Deep links to System Settings

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }
}
