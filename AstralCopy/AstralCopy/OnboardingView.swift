import AppKit
import SwiftUI

/// First-launch onboarding that guides the user through granting permissions.
struct OnboardingView: View {
    @ObservedObject private var permissions = PermissionsManager.shared
    @State private var pollTimer: Timer?
    @State private var showingAbout = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 128, height: 128)
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

                /*permissionRow(
                    title: String(localized: "onboarding.inputMonitoring"),
                    description: String(localized: "onboarding.inputMonitoring.description"),
                    granted: permissions.inputMonitoringGranted,
                    action: permissions.openInputMonitoringSettings
                )*/
            }

            Spacer()

            // Footer
            HStack {
                Button("about.button") { showingAbout = true }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

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
            .sheet(isPresented: $showingAbout) { AboutView() }
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
                // Try the event tap directly — its success is the real proof
                EventTapManager.shared.install()
                if EventTapManager.shared.isActive {
                    permissions.markAllGranted()
                    stopPolling()
                } else {
                    permissions.refreshStatus()
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
