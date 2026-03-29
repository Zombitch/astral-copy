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

        // Try installing the event tap — its success is the real proof of permissions
        EventTapManager.shared.install()

        if EventTapManager.shared.isActive {
            // Tap succeeded — permissions are definitely granted
            PermissionsManager.shared.markAllGranted()
        } else if EventTapManager.shared.isFallbackMode {
            // Fallback active — show onboarding so user can grant full permissions
            PermissionsManager.shared.showOnboarding()
        } else {
            PermissionsManager.shared.showOnboarding()
        }

        // Register launch-at-login if first run
        LaunchSettings.shared.registerIfFirstLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.uninstall()
    }
}
