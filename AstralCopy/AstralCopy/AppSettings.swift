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

    @AppStorage("compactMode") var compactMode: Bool = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set {
            appearanceModeRaw = newValue.rawValue
            applyAppearance()
        }
    }

    private init() {
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
