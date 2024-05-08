import SwiftUI
import DesignSystem

struct CommentModerationView: View {
    @StateObject private var viewModel: CommentModerationViewModel

    init(viewModel: CommentModerationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: .DS.Padding.double) {
            Divider()
                .foregroundStyle(Color.DS.Background.secondary)
            VStack(spacing: .DS.Padding.double) {
                titleHStack
                mainActionView
                secondaryActionView
            }
            .padding(.horizontal, .DS.Padding.double)
        }
    }

    private var titleHStack: some View {
        HStack(spacing: 0) {
            switch viewModel.state {
            case .pending:
                Image.DS.icon(named: .clock)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: .DS.Padding.double, height: .DS.Padding.double)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .padding(.trailing, .DS.Padding.half)
            case .approved, .liked:
                Image.DS.icon(named: .checkmark)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .padding(.trailing, 2)
            case .trash:
                EmptyView()
            }
            Text(viewModel.state.title)
                .style(.caption)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }

    @ViewBuilder
    private var mainActionView: some View {
        switch viewModel.state.mainAction {
        case let .cta(title, iconName):
            DSButton(
                title: title,
                iconName: iconName,
                style: DSButtonStyle(
                    emphasis: .primary,
                    size: .large
                )) {
                    withAnimation(.smooth) {
                        viewModel.didTapPrimaryCTA()
                    }
                }
        case .reply:
            ContentPreview(
                image: .init(url: viewModel.imageURL),
                text: viewModel.userName
            ) {
                viewModel.didTapReply()
            }
        }
    }

    @ViewBuilder
    private var secondaryActionView: some View {
        if case .more = viewModel.state.secondaryAction {
            DSButton(
                title: Strings.moreOptionsButtonTitle,
                style: .init(emphasis: .tertiary, size: .large)) {
                    viewModel.didTapMore()
                }
        } else if case .like = viewModel.state.secondaryAction {
            DSButton(
                title: viewModel.state == .approved ? String(
                    format: Strings.commentLikeTitle,
                    viewModel.userName
                ) : Strings.commentLikedTitle,
                iconName: viewModel.state == .approved ? .starOutline : .starFill,
                style: .init(
                    emphasis: .tertiary,
                    size: .large
                )
            ) {
                withAnimation(.interactiveSpring) {
                    viewModel.didTapLike()
                }
            }
        }
    }
}

private extension CommentModerationView {
    enum Strings {
        static let moreOptionsButtonTitle = NSLocalizedString(
            "notifications.comment.moderation.more.cta.title",
            value: "More options",
            comment: "More button title for comment moderation options sheet."
        )

        static let commentLikedTitle = NSLocalizedString(
            "notifications.comment.liked.title",
            value: "Comment liked",
            comment: "Liked state title for comment like button."
        )

        static let commentLikeTitle = NSLocalizedString(
            "notifications.comment.like.title",
            value: "Like %@'s comment",
            comment: "Like title for comment like button."
        )
    }
}

private extension CommentModerationState {
    enum MainAction {
        case cta(title: String, iconName: IconName)
        case reply
    }

    enum SecondaryAction {
        case more
        case like
        case none
    }

    var title: String {
        switch self {
        case .pending:
            return NSLocalizedString(
                "notifications.comment.moderation.pending.title",
                value: "Comment pending moderation",
                comment: "Title for Comment Moderation Pending State")
        case .approved, .liked:
            return NSLocalizedString(
                "notifications.comment.moderation.approved.title",
                value: "Comment approved",
                comment: "Title for Comment Moderation Approved State")
        case .trash:
            return NSLocalizedString(
                "notifications.comment.moderation.trash.title",
                value: "Comment in trash",
                comment: "Title for Comment Moderation Trash State")
        }
    }

    var mainAction: MainAction {
        switch self {
        case .pending:
            return .cta(
                title: NSLocalizedString(
                    "notifications.comment.approval.cta.title",
                    value: "Approve Comment",
                    comment: "Title for Comment Approval CTA"
                ),
                iconName: .checkmark
            )
        case .approved:
            return .reply
        case .liked:
            return .reply
        case .trash:
            return .cta(
                title: NSLocalizedString(
                    "notifications.comment.delete.cta.title",
                    value: "Delete Permanently",
                    comment: "Title for Comment Deletion CTA"
                ),
                iconName: .trash
            )
        }
    }

    var secondaryAction: SecondaryAction {
        switch self {
        case .pending:
            return .more
        case .approved, .liked:
            return .like
        case .trash:
            return .none
        }
    }
}

//#Preview {
//    GeometryReader { proxy in
//        if #available(iOS 17.0, *) {
//            ScrollView(.horizontal) {
//                LazyHStack(spacing: 0) {
//                    CommentModerationView(
//                        viewModel: CommentModerationViewModel(
//                            state: .pending,
//                            imageURL: URL(string: "https://i.pravatar.cc/300"),
//                            userName: "John Smith"
//                        )
//                    )
//                    .frame(
//                        width: proxy.size.width
//                    )
//                    CommentModerationView(
//                        viewModel: CommentModerationViewModel(
//                            state: .approved,
//                            imageURL: URL(string: "https://i.pravatar.cc/300"),
//                            userName: "Jane Smith"
//                        )
//                    )
//                    .frame(
//                        width: proxy.size.width
//                    )
//                    CommentModerationView(
//                        viewModel: CommentModerationViewModel(
//                            state: .liked,
//                            imageURL: URL(string: "https://i.pravatar.cc/300"),
//                            userName: "John Smith"
//                        )
//                    )
//                    .frame(
//                        width: proxy.size.width
//                    )
//                    CommentModerationView(
//                        viewModel: CommentModerationViewModel(
//                            state: .trash,
//                            imageURL: URL(string: "https://i.pravatar.cc/300"),
//                            userName: "Jane Smith"
//                        )
//                    )
//                    .frame(
//                        width: proxy.size.width
//                    )
//                }
//            }
//            .scrollTargetBehavior(.paging)
//            .scrollIndicators(.hidden)
//        }
//    }
//}
