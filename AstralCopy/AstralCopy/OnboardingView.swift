import AppKit
import SwiftUI

/// One-time welcome screen shown on first launch.
/// Explains the global hotkey, menu bar access, and launch-at-login — no permissions needed.
struct OnboardingView: View {
    @ObservedObject private var launchSettings = LaunchSettings.shared
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

            // Feature highlights
            VStack(spacing: 16) {
                infoRow(
                    icon: "keyboard",
                    title: String(localized: "onboarding.hotkey.title"),
                    description: String(localized: "onboarding.hotkey.description")
                )
                infoRow(
                    icon: "doc.on.clipboard",
                    title: String(localized: "onboarding.menubar.title"),
                    description: String(localized: "onboarding.menubar.description")
                )
            }

            Divider()

            // Launch at Login toggle
            launchToggleRow()

            Spacer()

            // Footer
            HStack {
                Button("about.button") { showingAbout = true }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("onboarding.done") {
                    PermissionsManager.shared.dismissOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
            .sheet(isPresented: $showingAbout) { AboutView() }
        }
        .padding(24)
        .frame(width: 530, height: 530)
    }

    // MARK: - Helpers

    private func launchToggleRow() -> some View {
        HStack(spacing: 14) {
            // Gradient icon — mirrors the iOS Settings aesthetic while staying on-brand
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "power.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "onboarding.launchAtLogin"))
                    .font(.headline)
                Text(String(localized: "onboarding.launchAtLogin.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $launchSettings.launchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.accentColor.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
