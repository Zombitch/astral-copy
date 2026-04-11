import ServiceManagement
import SwiftUI

/// Manages launch-at-login via SMAppService (macOS 13+).
@MainActor
final class LaunchSettings: ObservableObject {
    static let shared = LaunchSettings()

    @Published var launchAtLogin: Bool {
        didSet { updateRegistration() }
    }

    private init() {
        // SMAppService is the single source of truth — avoids stale UserDefaults
        // values from previous installs making the toggle appear on when it shouldn't.
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// No-op: the user opts in during onboarding instead of auto-registering.
    func registerIfFirstLaunch() {}

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
