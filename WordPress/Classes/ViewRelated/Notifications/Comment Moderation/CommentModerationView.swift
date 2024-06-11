import SwiftUI
import DesignSystem

struct CommentModerationView: View {
    @ObservedObject private var viewModel: CommentModerationViewModel

    init(viewModel: CommentModerationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: viewModel.layout == .inputFocused ? 0 : .DS.Padding.double) {
            Divider()
                .foregroundStyle(Color.DS.Background.secondary)
            VStack {
                switch viewModel.state {
                case .pending:
                    Pending(viewModel: viewModel)
                case .approved:
                    Approved(viewModel: viewModel)
                case .trash, .spam:
                    TrashSpam(viewModel: viewModel)
                case .deleted:
                    // This case cannot ocur as there's no deleted state received as response
                    EmptyView()
                }
            }
            .padding(.horizontal, viewModel.layout == .inputFocused ? 0 : .DS.Padding.double)
        }
        .background(
            Color(UIColor.systemBackground)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(.all)

        )
        .animation(.smooth, value: viewModel.state)
    }
}

// MARK: - Subviews

private struct TitleHeader<T: View>: View {
    let title: String?

    @ViewBuilder let icon: () -> T

    init(title: String, @ViewBuilder icon: @escaping () -> T = { EmptyView() }) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 0) {
            icon()
            if let title {
                Text(title)
                    .style(.caption)
                    .foregroundStyle(Color.DS.Foreground.secondary)
            }
        }
    }
}

private struct Container<T: View, V: View>: View {
    let header: V
    let content: T
    let layout: CommentModerationViewModel.Layout

    private var transition: AnyTransition = .opacity

    private let animationDuration = 0.25

    private var insertionAnimationDelay: TimeInterval {
        return animationDuration * 0.8
    }

    private var insertionAnimation: Animation {
        return removalAnimation.delay(insertionAnimationDelay)
    }

    private var removalAnimation: Animation {
        return .smooth(duration: animationDuration)
    }

    init(viewModel: CommentModerationViewModel, @ViewBuilder header: () -> V = { EmptyView() }, @ViewBuilder content: () -> T) {
        self.content = content()
        self.header = header()
        self.layout = viewModel.layout
    }

    var body: some View {
        VStack(spacing: .DS.Padding.double) {
            header
            content
        }
        .padding(.horizontal, layout == .normal ? .DS.Padding.double : 0)
        .transition(
            .asymmetric(
                insertion: transition.animation(insertionAnimation),
                removal: transition.animation(removalAnimation)
            )
        )
    }
}

// MARK: - Pending

private struct Pending: View {
    @ObservedObject var viewModel: CommentModerationViewModel

    var body: some View {
        Container(viewModel: viewModel, header: { header }) {
            VStack {
                DSButton(
                    title: Strings.approveComment,
                    iconName: .checkmark,
                    style: DSButtonStyle(
                        emphasis: .primary,
                        size: .large
                    ),
                    isLoading: $viewModel.isLoading
                ) {
                    viewModel.didTapPrimaryCTA()
                }
                DSButton(
                    title: Strings.moreOptions,
                    style: .init(emphasis: .tertiary, size: .large)) {
                        viewModel.didTapMore()
                    }
            }
        }
    }

    var header: some View {
        TitleHeader(title: Strings.title, icon: { icon })
    }

    @ViewBuilder
    var icon: some View {
        Image.DS.icon(named: .clock)
            .resizable()
            .renderingMode(.template)
            .frame(width: .DS.Padding.double, height: .DS.Padding.double)
            .foregroundStyle(Color.DS.Foreground.secondary)
            .padding(.trailing, .DS.Padding.half)
    }

    enum Strings {
        static let title = NSLocalizedString(
            "notifications.comment.moderation.pending.title",
            value: "Comment pending moderation",
            comment: "Title for Comment Moderation Pending State"
        )
        static let approveComment = NSLocalizedString(
            "notifications.comment.approval.cta.title",
            value: "Approve Comment",
            comment: "Title for Comment Approval CTA"
        )
        static let moreOptions = NSLocalizedString(
            "notifications.comment.moderation.more.cta.title",
            value: "More options",
            comment: "More button title for comment moderation options sheet."
        )
    }
}

// MARK: - Approved

private struct Approved: View {
    @ObservedObject var viewModel: CommentModerationViewModel

    private var likeButtonTitle: String {
        liked ? Strings.commentLikedTitle : String(format: Strings.commentLikeTitle, viewModel.userName)
    }

    private let liked: Bool

    init(viewModel: CommentModerationViewModel) {
        self.viewModel = viewModel
        self.liked = {
            switch viewModel.state {
            case .approved(let liked): return liked
            default: return false
            }
        }()
    }

    var body: some View {
        Container(viewModel: viewModel, header: { header }) {
            VStack {
                textView
                likeButton
            }
        }
    }

    @ViewBuilder
    var header: some View {
        if viewModel.layout == .normal {
            TitleHeader(title: Strings.title, icon: { icon })
        }

    }

    @ViewBuilder
    var icon: some View {
        Image.DS.icon(named: .checkmark)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.DS.Foreground.secondary)
            .padding(.trailing, 2)
    }

    @ViewBuilder
    var textView: some View {
        CommentModerationReplyTextView(
            text: $viewModel.reply,
            layout: viewModel.layout
        )
    }

    @ViewBuilder
    var likeButton: some View {
        if viewModel.layout == .normal {
            DSButton(
                title: likeButtonTitle,
                iconName: liked ? .starFill : .starOutline,
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

    enum Strings {
        static let title = NSLocalizedString(
            "notifications.comment.moderation.approved.title",
            value: "Comment approved",
            comment: "Title for Comment Moderation Approved State"
        )
        static let approveComment = NSLocalizedString(
            "notifications.comment.approval.cta.title",
            value: "Approve Comment",
            comment: "Title for Comment Approval CTA"
        )
        static let moreOptions = NSLocalizedString(
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

// MARK: - Trash & Spam

private struct TrashSpam: View {
    @ObservedObject var viewModel: CommentModerationViewModel

    @State var title: String

    init(viewModel: CommentModerationViewModel) {
        self.viewModel = viewModel
        self.title = Self.title(for: viewModel.state) ?? ""
    }

    var body: some View {
        Container(viewModel: viewModel, header: { TitleHeader(title: title) }) {
            DSButton(
                title: Strings.delete,
                iconName: .trash,
                style: .init(
                    emphasis: .primary,
                    size: .large
                ),
                isLoading: $viewModel.isLoading
            ) {
                self.viewModel.didTapPrimaryCTA()
            }
        }
        .padding(.bottom, .DS.Padding.double)
        .onChange(of: viewModel.state) { state in
            if let title = Self.title(for: state) {
                self.title = title
            }
        }
    }

    static func title(for state: CommentModerationState) -> String? {
        switch state {
        case .spam: return Strings.spamTitle
        case .trash: return Strings.trashTitle
        default: return nil
        }
    }

    enum Strings {
        static let trashTitle = NSLocalizedString(
            "notifications.comment.moderation.trash.title",
            value: "Comment in trash",
            comment: "Title for Comment Moderation Trash State"
        )
        static let spamTitle = NSLocalizedString(
            "notifications.comment.moderation.spam.title",
            value: "Comment in spam",
            comment: "Title for Comment Moderation Spam State"
        )
        static let delete = NSLocalizedString(
            "notifications.comment.delete.cta.title",
            value: "Delete Permanently",
            comment: "Title for Comment Deletion CTA"
        )
    }
}
