import SwiftUI
import DesignSystem

struct ShareFooterView: View {
    private let title: String
    private let onShareClicked: () -> Void
    @Environment(\.colorScheme) var colorScheme

    init(kind: ShareFooterView.Kind, onShareClicked: @escaping () -> Void) {
        self.onShareClicked = onShareClicked
        switch kind {
        case .comment:
            title = Strings.shareCommentTitle
        case .post:
            title = Strings.sharePostTitle
        case .blog:
            title = Strings.shareBlogTitle
        }
    }

    var body: some View {
        VStack {
            if colorScheme == .light {
                Divider()
                    .frame(height: 1)
                    .foregroundStyle(Color.DS.Background.secondary)
            }
            DSButton(
                title: title,
                iconName: .blockShare,
                style: .init(emphasis: .primary, size: .large),
                action: onShareClicked
            )
            .padding(.top, .DS.Padding.double)
            .padding(.horizontal, .DS.Padding.medium)
            .padding(.bottom, .DS.Padding.medium)
        }.background(Color.DS.Background.primary)
    }

    enum Kind: String {
        case comment
        case post
        case blog
    }
}

private enum Strings {
    static let sharePostTitle = NSLocalizedString(
        "share.button.title.post",
        value: "Share your post",
        comment: "The title for the post share button"
    )
    static let shareCommentTitle = NSLocalizedString(
        "share.button.title.comment",
        value: "Share your comment",
        comment: "The title for the comment share button"
    )
    static let shareBlogTitle = NSLocalizedString(
        "share.button.title.blog",
        value: "Share your blog",
        comment: "The title for the blog share button"
    )
}
