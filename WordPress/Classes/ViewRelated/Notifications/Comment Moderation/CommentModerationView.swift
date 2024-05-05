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
                }
            }
            .padding(.horizontal, .DS.Padding.double)
        }
        .animation(.smooth, value: viewModel.state)
    }
}

// MARK: - Subviews

private struct Container<T: View, V: View>: View {

    let title: String
    let icon: V
    let content: T

    private let animationDuration = 0.25

    private var animation: Animation {
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
                insertion: .opacity.animation(animation.delay(animationDuration * 1)),
                removal: .opacity.animation(animation)
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

    let viewModel: CommentModerationViewModel

    var body: some View {
        Container(title: Strings.title, icon: { icon }) {
            VStack {
                DSButton(
                    title: Strings.approveComment,
                    iconName: .checkmark,
                    style: DSButtonStyle(
                        emphasis: .primary,
                        size: .large
                    )) {
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

    let viewModel: CommentModerationViewModel
    let liked: Bool

    private var likeButtonTitle: String {
        liked ? Strings.commentLikedTitle : String(format: Strings.commentLikeTitle, viewModel.userName)
    }

    var body: some View {
        Container(title: Strings.title, icon: { icon }) {
            VStack {
                ContentPreview(
                    image: .init(url: viewModel.imageURL, placeholder: Image("gravatar")),
                    text: viewModel.userName
                ) {
                }
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
                )
            ) {
            }
        }.onChange(of: viewModel.state) { state in
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

// MARK: - Preview

struct CommentModerationView_Previews: PreviewProvider {
    static let viewModel = CommentModerationViewModel(
        state: .pending,
        imageURL: URL(string: "https://i.pravatar.cc/300"),
        userName: "John Smith"
    )

    static var previews: some View {
        ZStack {
            VStack(spacing: .DS.Padding.double) {
                Button("Pending") {
                    viewModel.state = .pending
                }
                Button("Approve") {
                    viewModel.state = .approved(liked: false)
                }
                Button("Spam") {
                    viewModel.state = .spam
                }
                Button("Trash") {
                    viewModel.state = .trash
                }
            }
            VStack {
                Spacer()
                CommentModerationView(viewModel: viewModel)
            }
        }
    }
}
