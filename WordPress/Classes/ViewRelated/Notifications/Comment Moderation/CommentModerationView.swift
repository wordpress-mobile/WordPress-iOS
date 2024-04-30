import SwiftUI
import DesignSystem

struct CommentModerationView: View {
    struct Model {
        let imageURL: URL?
        let userName: String
    }

    var viewModel: CommentModerationViewModel?
    @State private var state: ModerationState
    private var model: Model

    init(state: ModerationState, model: Model) {
        _state = State(initialValue: state)
        self.model = model
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
        HStack(spacing: .DS.Padding.half) {
            switch state {
            case .pending:
                Image.DS.icon(named: .exclamationCircle)
                    .font(.DS.caption)
                    .foregroundStyle(Color.DS.Foreground.secondary)
            case .approved, .liked:
                Image.DS.icon(named: .checkmark)
                    .font(.DS.caption)
                    .foregroundStyle(Color.DS.Foreground.secondary)
            case .trash:
                EmptyView()
            }
            Text(state.title)
                .style(.caption)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }

    @ViewBuilder
    private var mainActionView: some View {
        switch state.mainAction {
        case let .cta(title, iconName):
            DSButton(
                title: title,
                iconName: iconName,
                style: DSButtonStyle(
                    emphasis: .primary,
                    size: .large
                )) {
                    withAnimation(.smooth) {
                        if case .pending = state {
                            state = .approved
                        }
                    }
                }
        case .reply:
            ContentPreview(
                image: .init(url: model.imageURL),
                text: model.userName
            ) {
                viewModel?.didTapReply()
            }
        }
    }

    @ViewBuilder
    private var secondaryActionView: some View {
        if case .more = state.secondaryAction {
            DSButton(
                title: Strings.moreOptionsButtonTitle,
                style: .init(emphasis: .tertiary, size: .large)) {
                    // More options action
                }
        } else if case .like = state.secondaryAction {
            DSButton(
                title: state == .approved ? String(
                    format: Strings.commentLikeTitle,
                    model.userName
                ) : Strings.commentLikedTitle,
                iconName: state == .approved ? .starOutline : .starFill,
                style: .init(
                    emphasis: .tertiary,
                    size: .large
                )
            ) {
                withAnimation(.interactiveSpring) {
                    state = state == .approved ? .liked : .approved
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

extension CommentModerationView {
    enum ModerationState: CaseIterable {
        case pending
        case approved
        case liked
        case trash

        fileprivate enum MainAction {
            case cta(title: String, iconName: IconName)
            case reply
        }

        fileprivate enum SecondaryAction {
            case more
            case like
            case none
        }

        fileprivate var title: String {
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

        fileprivate var mainAction: MainAction {
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

        fileprivate var secondaryAction: SecondaryAction {
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
}

#Preview {
    GeometryReader { proxy in
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    CommentModerationView(
                        state: .pending,
                        model: .init(
                            imageURL: URL(string: "https://i.pravatar.cc/300"),
                            userName: "John Smith"
                        )
                    )
                    .frame(
                        width: proxy.size.width
                    )
                    CommentModerationView(
                        state: .approved,
                        model: .init(
                            imageURL: URL(string: "https://i.pravatar.cc/300"),
                            userName: "Jane Smith"
                        )
                    )
                    .frame(
                        width: proxy.size.width
                    )
                    CommentModerationView(
                        state: .liked,
                        model: .init(
                            imageURL: URL(string: "https://i.pravatar.cc/300"),
                            userName: "John Smith"
                        )
                    )
                    .frame(
                        width: proxy.size.width
                    )
                    CommentModerationView(
                        state: .trash,
                        model: .init(
                            imageURL: URL(string: "https://i.pravatar.cc/300"),
                            userName: "Jane Smith"
                        )
                    )
                    .frame(
                        width: proxy.size.width
                    )
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
    }
}
