import SwiftUI

/// A list row that opens a comment.
///
/// This is a `Button` with its own chevron, not a `NavigationLink`. A link in
/// the row pops the detail screen when moderation removes the row, and
/// value-based links are disabled because Comments has no `NavigationStack`
/// above it. The owner pushes the detail screen with a hidden link outside
/// its rows.
struct CommentRowButton: View {
    let item: CommentListItem
    let titleState: PostTitleResolver.TitleState
    let showsPendingStatus: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                CommentRowView(
                    item: item,
                    titleState: titleState,
                    showsPendingStatus: showsPendingStatus
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
