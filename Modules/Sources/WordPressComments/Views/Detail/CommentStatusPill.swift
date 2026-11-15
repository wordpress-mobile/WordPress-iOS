import DesignSystem
import SwiftUI

/// The pinned status label above the author header. Reads the live header
/// status (the screen's status source of truth), so it stays in sync while a
/// moderation action settles.
struct CommentStatusPill: View {
    let status: CommentListItem.Status

    var body: some View {
        Label(label, systemImage: symbol)
            .labelStyle(CompactLabelStyle())
            .font(.footnote)
            .foregroundStyle(tint)
            .accessibilityLabel(label)
    }

    private var tint: Color {
        switch status {
        case .approved: Color(UIAppColor.success)
        case .pending: Color(UIAppColor.warning)
        case .spam, .trash: Color(UIAppColor.error)
        case .other: .secondary
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

/// Keeps the icon snug against the text. The automatic style inside a `List`
/// reserves a wide icon column, which pushes the text away from the icon.
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
            configuration.title
        }
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        CommentStatusPill(status: .approved)
        CommentStatusPill(status: .pending)
        CommentStatusPill(status: .spam)
        CommentStatusPill(status: .trash)
        CommentStatusPill(status: .other("hold"))
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
}
#endif
