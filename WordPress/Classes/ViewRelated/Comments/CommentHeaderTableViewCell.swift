import UIKit

class CommentHeaderTableViewCell: UITableViewCell, Reusable {

    enum Title {
        /// Title for a top-level comment on a post.
        case post

        /// Title for the comment threads.
        case thread

        /// Title for a comment that's a reply to another comment.
        /// Requires a String describing the replied author's name.
        case reply(String)

        var stringValue: String {
            switch self {
            case .post:
                return .postCommentTitleText
            case .thread:
                return .commentThreadTitleText
            case .reply(let author):
                return String(format: .replyCommentTitleFormat, author)
            }
        }
    }

    // MARK: Initialization

    required init() {
        super.init(style: .subtitle, reuseIdentifier: Self.defaultReuseID)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the header cell.
    /// - Parameters:
    ///   - title: The title type for the header. See `Title`.
    ///   - subtitle: A text snippet of the parent object.
    ///   - showsDisclosureIndicator: When this is `false`, the cell is configured to look non-interactive.
    func configure(for title: Title, subtitle: String, showsDisclosureIndicator: Bool = true) {
        textLabel?.setText(title.stringValue)
        detailTextLabel?.setText(subtitle)
        accessoryType = showsDisclosureIndicator ? .disclosureIndicator : .none
        selectionStyle = showsDisclosureIndicator ? .default : .none
    }

    // MARK: Helpers

    private typealias Style = WPStyleGuide.CommentDetail.Header

    private func configureStyle() {
        accessoryType = .disclosureIndicator

        textLabel?.font = Style.font
        textLabel?.textColor = Style.textColor
        textLabel?.numberOfLines = 2

        detailTextLabel?.font = Style.detailFont
        detailTextLabel?.textColor = Style.detailTextColor
        detailTextLabel?.numberOfLines = 1
    }

}

// MARK: Localization

private extension String {
    static let postCommentTitleText = NSLocalizedString("Comment on", comment: "Provides hint that the current screen displays a comment on a post. "
                                                            + "The title of the post will displayed below this string. "
                                                            + "Example: Comment on \n My First Post")
    static let replyCommentTitleFormat = NSLocalizedString("Reply to %1$@", comment: "Provides hint that the screen displays a reply to a comment."
                                                           + "%1$@ is a placeholder for the comment author that's been replied to."
                                                           + "Example: Reply to Pamela Nguyen")
    static let commentThreadTitleText = NSLocalizedString("Comments on", comment: "Sentence fragment. "
                                                          + "The full phrase is 'Comments on' followed by the title of a post on a separate line.")
}
