import SwiftUI

/// Global app preferences for appearance and display mode.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum AppearanceMode: String, CaseIterable {
        case system
        case light
        case dark

        var localizedName: String {
            switch self {
            case .system: String(localized: "settings.appearance.system")
            case .light: String(localized: "settings.appearance.light")
            case .dark: String(localized: "settings.appearance.dark")
            }
        }
    }

    @Published var compactMode: Bool {
        didSet { UserDefaults.standard.set(compactMode, forKey: "compactMode") }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    private init() {
        self.compactMode = UserDefaults.standard.bool(forKey: "compactMode")
        let raw = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: raw) ?? .system
        applyAppearance()
    }

    func applyAppearance() {
        switch appearanceMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
