import DesignSystem
import SwiftUI

struct CommentRowView: View {
    let item: CommentListItem
    let titleState: PostTitleResolver.TitleState

    // Same geometry as the legacy ListTableViewCell: an 8pt dot leading the
    // avatar, painted clear (not hidden) when the comment isn't pending.
    private var indicatorColor: Color {
        item.status == .pending ? Color(UIAppColor.yellow(.shade20)) : .clear
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 8, height: 8)
                avatar
            }
            VStack(alignment: .leading, spacing: 4) {
                headline
                Text(item.snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let date = item.date {
                    Text(date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        // The pending state is otherwise conveyed only by the dot's color,
        // which VoiceOver cannot read once the row's children are combined.
        .accessibilityValue(item.status == .pending ? Strings.pendingAccessibilityValue : "")
    }

    private var avatar: some View {
        CommentAvatarView(url: item.avatarURL)
    }

    @ViewBuilder
    private var headline: some View {
        switch titleState {
        case .resolved(let title):
            Text(headlineText(postTitle: title))
                .font(.subheadline)
        case .loading:
            HStack(spacing: 4) {
                Text(item.authorName)
                    .font(.subheadline.weight(.semibold))
                Text("Sample Post Title")
                    .font(.subheadline)
                    .redacted(reason: .placeholder)
            }
            .lineLimit(1)
        case .unavailable:
            Text(item.authorName)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func headlineText(postTitle: String) -> AttributedString {
        var text = AttributedString(
            String.localizedStringWithFormat(Strings.authorOnPost, item.authorName, postTitle)
        )
        for segment in [item.authorName, postTitle] {
            if let range = text.range(of: segment) {
                text[range].font = .subheadline.weight(.semibold)
            }
        }
        return text
    }
}

#Preview {
    List {
        CommentRowView(item: .preview(id: 1, status: .pending), titleState: .resolved("A Post Title"))
        CommentRowView(item: .preview(id: 2, status: .approved), titleState: .loading)
        CommentRowView(item: .preview(id: 3, status: .approved), titleState: .unavailable)
    }
    .listStyle(.plain)
}

extension CommentListItem {
    static func preview(id: Int64, status: Status) -> CommentListItem {
        CommentListItem(
            id: id,
            authorName: "Priya Nair",
            avatarURL: nil,
            postID: 1,
            snippet: "Really appreciate the detailed writeup, this is exactly the kind of review I was hoping to find.",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            status: status
        )
    }
}
