import ServiceManagement
import SwiftUI

/// Manages launch-at-login via SMAppService (macOS 13+).
@MainActor
final class LaunchSettings: ObservableObject {
    static let shared = LaunchSettings()

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateRegistration()
        }
    }

    private var hasLaunchedBefore: Bool {
        get { UserDefaults.standard.bool(forKey: "hasLaunchedBefore") }
        set { UserDefaults.standard.set(newValue, forKey: "hasLaunchedBefore") }
    }

    private init() {
        // Default to false if key has never been set — user opts in via onboarding
        if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
            self.launchAtLogin = false
        } else {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }

    /// On first launch, simply mark as seen — launch-at-login stays at its default (off).
    func registerIfFirstLaunch() {
        guard !hasLaunchedBefore else { return }
        hasLaunchedBefore = true
        // Don't auto-enable; the user chooses during onboarding
    }

    func updateRegistration() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[LaunchSettings] Failed to update login item: \(error.localizedDescription)")
        }
    }
}
