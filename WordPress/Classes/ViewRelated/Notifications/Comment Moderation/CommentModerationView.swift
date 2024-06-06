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
                switch viewModel.state {
                case .pending:
                    Pending(viewModel: viewModel)
                case .approved(let liked):
                    Approved(viewModel: viewModel, liked: liked)
                case .trash, .spam:
                    TrashSpam(viewModel: viewModel)
                case .deleted:
                    // This case cannot ocur as there's no deleted state received as response
                    EmptyView()
                }
            }
            .padding(.horizontal, .DS.Padding.double)
        }
        .background(Color.DS.Background.primary)
        .animation(.smooth, value: viewModel.state)
    }
}

// MARK: - Subviews

private struct Container<T: View, V: View>: View {

    let title: String
    let icon: V
    let content: T

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

    init(title: String, @ViewBuilder icon: () -> V = { EmptyView() }, @ViewBuilder content: () -> T) {
        self.content = content()
        self.icon = icon()
        self.title = title
    }

    var body: some View {
        VStack(spacing: .DS.Padding.double) {
            titleHStack
            content
        }
        .padding(.horizontal, .DS.Padding.double)
        .transition(
            .asymmetric(
                insertion: transition.animation(insertionAnimation),
                removal: transition.animation(removalAnimation)
            )
        )
    }

    var titleHStack: some View {
        HStack(spacing: 0) {
            icon
            Text(title)
                .style(.caption)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }
}

private struct Pending: View {
    @ObservedObject var viewModel: CommentModerationViewModel

    var body: some View {
        Container(title: Strings.title, icon: { icon }) {
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

private struct Approved: View {

    @ObservedObject var viewModel: CommentModerationViewModel

    let liked: Bool

    init(viewModel: CommentModerationViewModel, liked: Bool) {
        self.viewModel = viewModel
        self.liked = liked
    }

    private var likeButtonTitle: String {
        liked ? Strings.commentLikedTitle : String(format: Strings.commentLikeTitle, viewModel.userName)
    }

    var body: some View {
        Container(title: Strings.title, icon: { icon }) {
            VStack {
                ReplyTextSwiftUIView(replyTextView: viewModel.textView)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
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
    }

    @ViewBuilder
    var icon: some View {
        Image.DS.icon(named: .checkmark)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.DS.Foreground.secondary)
            .padding(.trailing, 2)
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

final class FooView: UIView {
    override var intrinsicContentSize: CGSize {
        return .init(width: UIView.noIntrinsicMetric, height: 100)
    }
}

struct ReplyTextSwiftUIView: UIViewRepresentable {
    let replyTextView: NewReplyTextView

    init(replyTextView: NewReplyTextView) {
        self.replyTextView = replyTextView
    }

    func makeUIView(context: Context) -> NewReplyTextView {
        replyTextView.translatesAutoresizingMaskIntoConstraints = true
        replyTextView.sizeToFit()
        return replyTextView
    }

    func updateUIView(_ uiView: NewReplyTextView, context: Context) {
        uiView.sizeToFit()
    }

    typealias UIViewType = NewReplyTextView
}

private struct TrashSpam: View {
    @ObservedObject var viewModel: CommentModerationViewModel

    @State var title: String

    init(viewModel: CommentModerationViewModel) {
        self.viewModel = viewModel
        self.title = Self.title(for: viewModel.state) ?? ""
    }

    var body: some View {
        Container(title: title) {
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

struct CommentModerationView_Previews: PreviewProvider {
    static let viewModel: CommentModerationViewModel = {
        let comment = Comment(context: ContextManager.shared.mainContext)
        let vm = CommentModerationViewModel(
            comment: comment,
            coordinator: .init(commentDetailViewController: .init(comment: comment, isLastInList: false)),
            notification: nil,
            stateChanged: { _ in }
        )
        vm.state = .approved(liked: false)
        return vm
    }()

    static var previews: some View {
        VStack {
            Spacer()
            CommentModerationView(viewModel: Self.viewModel)
        }
    }
}
