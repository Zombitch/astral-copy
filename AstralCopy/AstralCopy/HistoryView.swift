import SwiftUI

/// The clipboard history list shown when the user presses Cmd+V.
struct HistoryView: View {
    @ObservedObject private var clipboard = ClipboardService.shared
    @ObservedObject private var historyManager = HistoryManager.shared

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
                HistoryRowView(item: item)
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

    var body: some View {
        HStack(spacing: 10) {
            contentView
            Spacer()
            Text(item.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var contentView: some View {
        switch item.content {
        case .text(let string):
            Text(string)
                .lineLimit(3)
                .font(.system(.body, design: .monospaced))
                .truncationMode(.tail)

        case .image(let nsImage):
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
