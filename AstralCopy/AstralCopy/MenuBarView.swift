import SwiftUI

/// Content of the menu bar dropdown.
struct MenuBarView: View {
    @ObservedObject private var clipboard = ClipboardService.shared
    @ObservedObject private var launchSettings = LaunchSettings.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    @ObservedObject private var permissions = PermissionsManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Recent items header
            HStack {
                Text("menu.recentItems")
                    .font(.headline)
                Spacer()
                if !clipboard.history.isEmpty {
                    Button("menu.clearAll") {
                        clipboard.clearHistory()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Quick list of last 10 items
            if clipboard.history.isEmpty {
                Text("history.empty")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(clipboard.history.prefix(10)) { item in
                            menuRow(for: item)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer actions
            VStack(spacing: 4) {
                Button {
                    historyManager.showHistory()
                } label: {
                    Label("menu.showAll", systemImage: "list.clipboard")
                }
                .buttonStyle(.borderless)

                Toggle("menu.launchAtLogin", isOn: $launchSettings.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Divider()

                // Permissions status
                permissionStatusRow(
                    label: String(localized: "settings.accessibility"),
                    granted: permissions.accessibilityGranted,
                    action: permissions.openAccessibilitySettings
                )
                permissionStatusRow(
                    label: String(localized: "settings.inputMonitoring"),
                    granted: permissions.inputMonitoringGranted,
                    action: permissions.openInputMonitoringSettings
                )

                Divider()

                Button("menu.quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(8)
        }
        .frame(width: 320)
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
        Button {
            historyManager.pasteItem(item)
        } label: {
            HStack(spacing: 8) {
                switch item.content {
                case .text(let string):
                    Text(string)
                        .lineLimit(2)
                        .font(.system(.caption, design: .monospaced))
                        .truncationMode(.tail)
                case .image(let nsImage):
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}
