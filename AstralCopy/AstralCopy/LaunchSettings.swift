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
        // Default to true if key has never been set
        if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
            self.launchAtLogin = true
        } else {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }

    /// On first launch, register for login automatically.
    func registerIfFirstLaunch() {
        guard !hasLaunchedBefore else { return }
        hasLaunchedBefore = true
        launchAtLogin = true
        updateRegistration()
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
