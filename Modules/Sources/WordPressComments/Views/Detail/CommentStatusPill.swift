import SwiftUI

/// The pinned status pill above the author header. Reads the live header
/// status (the screen's status source of truth), so it stays in sync while a
/// moderation action settles.
struct CommentStatusPill: View {
    let status: CommentListItem.Status

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
            .accessibilityLabel(label)
    }

    private var tint: Color {
        switch status {
        case .approved: .green
        case .pending: .orange
        case .spam, .trash: .red
        case .other: .gray
        }
    }

    private var symbol: String {
        switch status {
        case .approved: "checkmark.circle"
        case .pending: "clock"
        case .spam: "nosign"
        case .trash: "trash"
        case .other: "questionmark.circle"
        }
    }

    private var label: String {
        switch status {
        case .approved: Strings.statusApproved
        case .pending: Strings.statusPending
        case .spam: Strings.statusSpam
        case .trash: Strings.statusTrash
        // A custom/unknown status is shown verbatim: the app can't localize a
        // value it doesn't model.
        case .other(let raw): raw
        }
    }
}
