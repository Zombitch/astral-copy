import SwiftUI

/// App settings window accessible from the menu bar.
struct SettingsView: View {
    @ObservedObject private var launchSettings = LaunchSettings.shared
    @ObservedObject private var permissions = PermissionsManager.shared
    @ObservedObject private var appSettings = AppSettings.shared

    var body: some View {
        Form {
            Section("settings.general") {
                Toggle("settings.launchAtLogin", isOn: $launchSettings.launchAtLogin)
                Toggle("settings.compactMode", isOn: $appSettings.compactMode)
            }

            Section("settings.appearance") {
                Picker("settings.appearance", selection: Binding(
                    get: { appSettings.appearanceMode },
                    set: { appSettings.appearanceMode = $0 }
                )) {
                    ForEach(AppSettings.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("settings.permissions") {
                HStack {
                    Label {
                        Text("settings.accessibility")
                    } icon: {
                        Image(systemName: permissions.accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(permissions.accessibilityGranted ? .green : .red)
                    }
                    Spacer()
                    if !permissions.accessibilityGranted {
                        Button("settings.grant") {
                            permissions.openAccessibilitySettings()
                        }
                        .controlSize(.small)
                    }
                }

                HStack {
                    Label {
                        Text("settings.inputMonitoring")
                    } icon: {
                        Image(systemName: permissions.inputMonitoringGranted ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(permissions.inputMonitoringGranted ? .green : .red)
                    }
                    Spacer()
                    if !permissions.inputMonitoringGranted {
                        Button("settings.grant") {
                            permissions.openInputMonitoringSettings()
                        }
                        .controlSize(.small)
                    }
                }

                Button("settings.refreshPermissions") {
                    permissions.refreshStatus()
                }
            }

            Section("settings.about") {
                LabeledContent("settings.version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 380)
    }
}
