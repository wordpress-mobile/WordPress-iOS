import SwiftUI

/// Parent context with optional navigation to the parent comment.
struct CommentParentStrip: View {
    let parent: CommentListItem
    var onTap: (() -> Void)?

    var body: some View {
        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
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
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}
