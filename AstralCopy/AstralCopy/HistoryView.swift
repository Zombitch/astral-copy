import SwiftUI

/// The clipboard history list shown when the user presses Cmd+V.
struct HistoryView: View {
    @ObservedObject private var clipboard = ClipboardService.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    @ObservedObject private var appSettings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            if clipboard.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .frame(minWidth: 320, minHeight: 200)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("history.empty")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        List {
            ForEach(clipboard.history) { item in
                HistoryRowView(item: item, compact: appSettings.compactMode)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        historyManager.pasteItem(item)
                    }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Row

struct HistoryRowView: View {
    let item: ClipboardItem
    let compact: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            contentView
            Spacer()
            Text(item.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, compact ? 2 : 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch item.content {
        case .text(let string):
            Text(string)
                .lineLimit(compact ? 1 : 3)
                .font(.system(compact ? .caption : .body, design: .monospaced))
                .foregroundStyle(.primary)
                .truncationMode(.tail)

        case .image(let nsImage):
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: compact ? 30 : 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
