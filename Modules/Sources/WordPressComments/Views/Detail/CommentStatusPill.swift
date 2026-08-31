import DesignSystem
import SwiftUI

/// The pinned status pill above the author header.
struct CommentStatusPill: View {
    let status: CommentListItem.Status

    var body: some View {
        Text(label)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
            .accessibilityLabel(label)
    }

    private var tint: Color {
        switch status {
        case .approved: Color(UIAppColor.green(.shade40))
        case .pending: Color(UIAppColor.yellow(.shade20))
        case .spam: Color(UIAppColor.orange(.shade40))
        case .trash: Color(UIAppColor.red(.shade40))
        case .other: Color(UIAppColor.gray(.shade30))
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
