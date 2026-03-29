import ServiceManagement
import SwiftUI

/// Manages launch-at-login via SMAppService (macOS 13+).
@MainActor
final class LaunchSettings: ObservableObject {
    static let shared = LaunchSettings()

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = true {
        didSet { updateRegistration() }
    }

    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false

    private init() {}

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
