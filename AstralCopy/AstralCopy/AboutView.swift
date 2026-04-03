import AppKit
import SwiftUI

/// Displays app information, description and studio credits.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Icon + title
            VStack(spacing: 8) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 72, height: 72)

                Text("AstralCopy")
                    .font(.title.bold())

                Text("about.studio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("about.intro")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    featureRow(symbol: "doc.on.clipboard", text: "about.feature.history")
                    featureRow(symbol: "keyboard",         text: "about.feature.shortcut")
                    featureRow(symbol: "checkmark.shield", text: "about.feature.cmdv")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack {
                Spacer()
                Button("onboarding.done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400, height: 360)
    }

    private func featureRow(symbol: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
