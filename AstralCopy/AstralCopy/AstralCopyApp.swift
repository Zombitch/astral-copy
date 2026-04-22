import ApplicationServices
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

        // Start clipboard monitoring (uses NSPasteboard, no permissions needed)
        ClipboardService.shared.startMonitoring()

        // Register the global ⌘⇧V hotkey (Carbon API, no permissions needed)
        HotkeyManager.shared.register()

        // Paste simulation needs Accessibility — prompt once so the user isn't left wondering why paste doesn't work.
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        // Register launch-at-login if first run
        LaunchSettings.shared.registerIfFirstLaunch()

        // Show a one-time welcome screen explaining the hotkey
        if !UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            PermissionsManager.shared.showOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
