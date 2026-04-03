import SwiftUI

/// Content of the menu bar dropdown.
struct MenuBarView: View {
    @ObservedObject private var clipboard = ClipboardService.shared
    @ObservedObject private var launchSettings = LaunchSettings.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    @ObservedObject private var permissions = PermissionsManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var selectedAppearanceMode: AppSettings.AppearanceMode = AppSettings.shared.appearanceMode
    @State private var showingAbout = false

    var body: some View {
        VStack(spacing: 0) {
            // Footer actions
            VStack(spacing: 4) {
                
                Spacer()
                Toggle("menu.launchAtLogin", isOn: $launchSettings.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Spacer()
                Toggle("menu.compactMode", isOn: $appSettings.compactMode)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Spacer()
                // Appearance picker
                HStack {
                    Text("menu.appearance")
                        .font(.caption)
                    Spacer()
                    Picker("", selection: $selectedAppearanceMode) {
                        ForEach(AppSettings.AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .onChange(of: selectedAppearanceMode) { newValue in
                        appSettings.appearanceMode = newValue
                    }
                    Spacer()
                }

                Spacer()
                Divider()

                // Permissions status
                permissionStatusRow(
                    label: String(localized: "settings.accessibility"),
                    granted: permissions.accessibilityGranted,
                    action: permissions.openAccessibilitySettings
                )
                /*permissionStatusRow(
                    label: String(localized: "settings.inputMonitoring"),
                    granted: permissions.inputMonitoringGranted,
                    action: permissions.openInputMonitoringSettings
                )*/

                // Fallback mode indicator
                if EventTapManager.shared.isFallbackMode {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("menu.fallbackMode")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Button("about.button") { showingAbout = true }
                    .buttonStyle(.borderless)

                Button("menu.quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(8)
        }
        .frame(width: 320)
        .sheet(isPresented: $showingAbout) { AboutView() }
    }

    // MARK: - Helpers

    private func permissionStatusRow(label: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(granted ? .green : .orange)
            Text(label)
                .font(.caption)
            Spacer()
            if granted {
                Text("menu.permission.granted")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Button("menu.permission.enable") {
                    action()
                }
                .font(.caption2)
                .controlSize(.mini)
            }
        }
    }

    @ViewBuilder
    private func menuRow(for item: ClipboardItem) -> some View {
        MenuItemRow(item: item, compact: appSettings.compactMode) {
            historyManager.pasteItem(item)
        }
    }
}

// MARK: - Menu Item Row (with hover)

struct MenuItemRow: View {
    let item: ClipboardItem
    let compact: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                switch item.content {
                case .text(let string):
                    Text(string.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression))
                        .lineLimit(compact ? 1 : 2)
                        .font(.system(compact ? .caption2 : .caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .truncationMode(.tail)
                case .image(let nsImage):
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: compact ? 20 : 32)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
            }
            .padding(.vertical, compact ? 2 : 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
