import SwiftUI

@main
struct AstralCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar extra — the only visible entry point
        MenuBarExtra {
            MenuBarView()
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — pure menu-bar app
        NSApp.setActivationPolicy(.accessory)

        // Apply saved appearance preference
        AppSettings.shared.applyAppearance()

        // Start clipboard monitoring
        ClipboardService.shared.startMonitoring()

        // AXIsProcessTrusted() is a silent check — never shows a system dialog.
        // We only attempt CGEvent.tapCreate (which CAN trigger a permission popup)
        // when we already know we have permission, so the popup never races our
        // onboarding window.
        if AXIsProcessTrusted() {
            EventTapManager.shared.install()
            if EventTapManager.shared.isActive {
                PermissionsManager.shared.markAllGranted()
            } else {
                // Permission is granted but tap still failed (e.g. after a macOS update).
                // Show onboarding so the user can re-grant or see the fallback status.
                PermissionsManager.shared.showOnboarding()
            }
        } else {
            // No permission yet — go straight to onboarding.
            // The onboarding's polling timer will call install() after the user
            // grants access in System Settings, avoiding any launch-time dialog.
            PermissionsManager.shared.showOnboarding()
        }

        // Register launch-at-login if first run
        LaunchSettings.shared.registerIfFirstLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.uninstall()
    }
}
