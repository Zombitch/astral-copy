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

        // First-launch onboarding
        if !PermissionsManager.shared.allPermissionsGranted {
            PermissionsManager.shared.showOnboarding()
        }

        // Start clipboard monitoring
        ClipboardService.shared.startMonitoring()

        // Attempt to install the event tap for Cmd+V override
        EventTapManager.shared.install()

        // Register launch-at-login if first run
        LaunchSettings.shared.registerIfFirstLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.uninstall()
    }
}
