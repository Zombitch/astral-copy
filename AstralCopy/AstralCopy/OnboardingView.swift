import SwiftUI

/// First-launch onboarding that guides the user through granting permissions.
struct OnboardingView: View {
    @ObservedObject private var permissions = PermissionsManager.shared
    @State private var pollTimer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                Text("onboarding.welcome")
                    .font(.title.bold())
                Text("onboarding.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Permission rows
            VStack(spacing: 16) {
                permissionRow(
                    title: String(localized: "onboarding.accessibility"),
                    description: String(localized: "onboarding.accessibility.description"),
                    granted: permissions.accessibilityGranted,
                    action: permissions.openAccessibilitySettings
                )

                permissionRow(
                    title: String(localized: "onboarding.inputMonitoring"),
                    description: String(localized: "onboarding.inputMonitoring.description"),
                    granted: permissions.inputMonitoringGranted,
                    action: permissions.openInputMonitoringSettings
                )
            }

            Spacer()

            // Done
            HStack {
                Spacer()

                Button("onboarding.done") {
                    if permissions.allPermissionsGranted {
                        EventTapManager.shared.install()
                    }
                    permissions.dismissOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!permissions.allPermissionsGranted)
            }
        }
        .padding(24)
        .frame(width: 480, height: 400)
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                permissions.refreshStatus()
                if permissions.allPermissionsGranted {
                    EventTapManager.shared.install()
                    stopPolling()
                }
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Helpers

    private func permissionRow(
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .font(.title2)
                .foregroundStyle(granted ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !granted {
                Button("onboarding.openSettings") {
                    action()
                }
                .controlSize(.small)
            }
        }
    }
}
