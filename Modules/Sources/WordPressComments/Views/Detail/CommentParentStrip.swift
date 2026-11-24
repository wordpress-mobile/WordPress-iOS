import SwiftUI

/// Parent context, optionally used as a navigation-link label.
struct CommentParentStrip: View {
    let parent: CommentListItem
    var showsDisclosureIndicator = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String.localizedStringWithFormat(Strings.inReplyToFormat, parent.authorName))
                    .font(.footnote.weight(.semibold))
                Text(parent.snippet)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
