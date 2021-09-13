import Foundation
import WordPressShared.WPTableViewCell

open class CommentsTableViewCell: WPTableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var pendingIndicator: UIView!
    @IBOutlet private weak var pendingIndicatorWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    // MARK: - Private Properties

    private var author = String()
    private var postTitle = String()
    private var content = String()
    private var pending: Bool = false
    private var gravatarURL: URL?
    private typealias Style = WPStyleGuide.Comments
    private let placeholderImage = Style.gravatarPlaceholderImage

    // MARK: - Public Properties

    @objc static let reuseIdentifier = "CommentsTableViewCell"
    @objc static let estimatedRowHeight = 150

    // MARK: - Public Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Style.backgroundColor
        pendingIndicator.layer.cornerRadius = pendingIndicatorWidthConstraint.constant / 2
    }

    @objc func configureWithComment(_ comment: Comment) {
        author = comment.authorForDisplay()
        pending = (comment.status == CommentStatusType.pending.description)
        postTitle = comment.titleForDisplay()
        content = comment.contentPreviewForDisplay()

        if let avatarURLForDisplay = comment.avatarURLForDisplay() {
            downloadGravatarWithURL(avatarURLForDisplay)
        } else {
            downloadGravatarWithGravatarEmail(comment.gravatarEmailForDisplay())
        }

        configurePendingIndicator()
        configureCommentLabels()
    }

}

private extension CommentsTableViewCell {

    // MARK: - Gravatar Downloading

    func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }

    func downloadGravatarWithGravatarEmail(_ email: String?) {
        guard let unwrappedEmail = email else {
            gravatarImageView.image = placeholderImage
            return
        }

        gravatarImageView.downloadGravatarWithEmail(unwrappedEmail, placeholderImage: placeholderImage)
    }

    // MARK: - Configure UI

    func configurePendingIndicator() {
        pendingIndicator.backgroundColor = pending ? Style.pendingIndicatorColor : .clear
    }

    func configureCommentLabels() {
        titleLabel.attributedText = attributedTitle()
        // Some Comment content has leading newlines. Let's nix that.
        detailLabel.text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        detailLabel.font = Style.detailFont
        detailLabel.textColor = Style.detailTextColor
    }

    func attributedTitle() -> NSAttributedString {
        let titleFormat = NSLocalizedString("%1$@ on %2$@", comment: "Label displaying the author and post title for a Comment. %1$@ is a placeholder for the author. %2$@ is a placeholder for the post title.")

        let replacementMap = [
            "%1$@": NSAttributedString(string: author, attributes: Style.titleBoldAttributes),
            "%2$@": NSAttributedString(string: postTitle, attributes: Style.titleBoldAttributes)
        ]

        // Replace Author + Title
        let attributedTitle = NSMutableAttributedString(string: titleFormat, attributes: Style.titleRegularAttributes)

        for (key, attributedString) in replacementMap {
            let range = (attributedTitle.string as NSString).range(of: key)
            if range.location != NSNotFound {
                attributedTitle.replaceCharacters(in: range, with: attributedString)
            }
        }

        return attributedTitle
    }

}
