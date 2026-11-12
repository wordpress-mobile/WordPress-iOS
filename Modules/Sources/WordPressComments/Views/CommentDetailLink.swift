import SwiftUI

/// Pushes the detail screen for `selection` and clears it on pop.
///
/// Attach it outside the list rows: moderation can remove the selected row
/// while its detail is still open.
struct CommentDetailLink: View {
    @Binding var selection: CommentListItem?
    let context: CommentDetailContext

    var body: some View {
        NavigationLink(
            isActive: Binding(
                get: { selection != nil },
                set: { isActive in
                    if !isActive { selection = nil }
                }
            )
        ) {
            if let selection {
                CommentDetailView(commentID: selection.id, seed: selection, context: context)
                    .id(selection.id)
            }
        } label: {
            EmptyView()
        }
        .hidden()
    }
}
