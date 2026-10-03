import SwiftUI

/// The "In reply to" strip shown above the content when the comment has a
/// parent.
struct CommentParentStrip: View {
    let parent: CommentListItem

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.footnote)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    private var text: AttributedString {
        var result = AttributedString(String(format: Strings.inReplyToFormat, parent.authorName))
        if let range = result.range(of: parent.authorName) {
            result[range].font = .footnote.weight(.semibold)
        }
        var snippet = AttributedString(": \(parent.snippet)")
        snippet.foregroundColor = .secondary
        result.append(snippet)
        return result
    }
}
