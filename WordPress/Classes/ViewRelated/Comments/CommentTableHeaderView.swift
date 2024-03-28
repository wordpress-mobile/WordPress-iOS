import SwiftUI

class CommentTableHeaderView: UITableViewHeaderFooterView, Reusable {

    enum Subtitle {
        /// Subtext for a top-level comment on a post.
        case post

        /// Subtext for a reply to a comment.
        /// Requires a String describing the replied author's name.
        case reply(String)

        /// Subtext for the comment threads.
        case commentThread

        fileprivate var stringValue: String {
            switch self {
            case .post:
                return Constants.postCommentSubText
            case .reply(let authorName):
                return String(format: Constants.replyCommentSubTextFormat, authorName)
            case .commentThread:
                return Constants.commentThreadSubText
            }
        }
    }

    private let hostingController: UIHostingController<CommentHeaderView>

    init(title: String,
         subtitle: Subtitle,
         showsDisclosureIndicator: Bool = false,
         reuseIdentifier: String? = CommentTableHeaderView.defaultReuseID,
         action: @escaping () -> Void) {
        let headerView = CommentHeaderView(
            title: title,
            subtitle: subtitle,
            showsDisclosureIndicator: showsDisclosureIndicator,
            action: action
        )
        hostingController = .init(rootView: headerView)
        super.init(reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private methods

private extension CommentTableHeaderView {

    func configureView() {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)
        contentView.pinSubviewToAllEdges(hostingController.view)
    }

    enum Constants {
        static let postCommentSubText = NSLocalizedString(
            "comment.header.subText.post",
            value: "Comment on",
            comment: """
                Provides a hint that the current screen displays a comment on a post.
                The title of the post will be displayed below this text.
                Example: Comment on \n My First Post
                """
        )

        static let replyCommentSubTextFormat = NSLocalizedString(
            "comment.header.subText.reply",
            value: "Reply to %1$@",
            comment: """
                Provides a hint that the current screen displays a reply to a comment.
                %1$@ is a placeholder for the comment author's name that's been replied to.
                Example: Reply to Pamela Nguyen
                """
        )

        static let commentThreadSubText = NSLocalizedString(
            "comment.header.subText.commentThread",
            value: "Comments on",
            comment: """
                Sentence fragment.
                The full phrase is 'Comments on' followed by the title of the post on a separate line.
                """
        )
    }
}

// MARK: - SwiftUI

private struct CommentHeaderView: View {

    @State var title: String
    @State var subtitle: CommentTableHeaderView.Subtitle
    @State var showsDisclosureIndicator: Bool

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                text
                Spacer()
                if showsDisclosureIndicator {
                    disclosureIndicator
                }
            }
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .background(.ultraThinMaterial)
    }

    var text: some View {
        VStack(alignment: .leading) {
            Text(subtitle.stringValue)
                .lineLimit(1)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
            Text(title)
                .lineLimit(1)
                .font(.subheadline)
                .foregroundColor(Color(.text))
        }
    }

    var disclosureIndicator: some View {
        Image(systemName: "chevron.forward")
            .renderingMode(.template)
            .foregroundColor(Color(.secondaryLabel))
            .font(.caption.weight(.semibold))
            .imageScale(.large)
    }
}
