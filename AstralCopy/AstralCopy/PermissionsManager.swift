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
        // If the event tap is already active, permissions are definitely granted
        // regardless of what AXIsProcessTrusted() reports
        if EventTapManager.shared.isActive {
            accessibilityGranted = true
            inputMonitoringGranted = true
            return
        }
        accessibilityGranted = AXIsProcessTrusted()
        inputMonitoringGranted = accessibilityGranted
    }

    /// Called when the event tap installs successfully, proving permissions are granted.
    func markAllGranted() {
        accessibilityGranted = true
        inputMonitoringGranted = true
    }

    func showOnboarding() {
        guard onboardingWindow == nil else { return }

        let view = OnboardingView()
        let hostingView = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = NSLocalizedString("onboarding.title", comment: "")
        window.isReleasedWhenClosed = false
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
