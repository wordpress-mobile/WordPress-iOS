import Foundation
import WordPressShared.WPTableViewCell

open class CommentsTableViewCell: WPTableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var timestampImageView: UIImageView!
    @IBOutlet private weak var timestampLabel: UILabel!

    // MARK: - Private Properties

    private var author: String?
    private var postTitle: String?
    private var content: String?
    private var timestamp: String?
    private var approved: Bool = false
    private var gravatarURL: URL?
    private typealias Style = WPStyleGuide.Comments

    private var placeholderImage: UIImage {
        return Style.gravatarPlaceholderImage(isApproved: approved)
    }

    // MARK: - Public Properties

    @objc static let reuseIdentifier = "CommentsTableViewCell"

    // MARK: - Public Methods

    @objc func configureWithComment(_ comment: Comment) {
        author = comment.authorForDisplay() ?? String()
        approved = (comment.status == CommentStatusApproved)
        postTitle = comment.titleForDisplay()
        content = comment.contentPreviewForDisplay()
        timestamp = comment.dateCreated.mediumString()

        if let avatarURLForDisplay = comment.avatarURLForDisplay() {
            downloadGravatarWithURL(avatarURLForDisplay)
        } else {
            downloadGravatarWithGravatarEmail(comment.gravatarEmailForDisplay())
        }

        refreshDetailsLabel()
        refreshTimestampLabel()
        refreshBackground()
        refreshImages()
    }

    // MARK: - Overwritten Methods

    open override func setSelected(_ selected: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setSelected(selected, animated: animated)
        refreshBackground()
    }

    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setHighlighted(highlighted, animated: animated)
        refreshBackground()
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

    // MARK: - Refresh UI

    func refreshDetailsLabel() {
        detailsLabel.attributedText = attributedDetailsText(approved)
        layoutIfNeeded()
    }

    func refreshTimestampLabel() {
        guard let timestamp = timestamp else {
            return
        }

        let style = Style.timestampStyle(isApproved: approved)
        let formattedTimestamp: String

        if approved {
            formattedTimestamp = timestamp
        } else {
            let pendingLabel = NSLocalizedString("Pending", comment: "Status name for a comment that hasn't yet been approved.")
            formattedTimestamp = "\(timestamp) · \(pendingLabel)"
        }

        timestampLabel?.attributedText = NSAttributedString(string: formattedTimestamp, attributes: style)
    }

    func refreshBackground() {
        backgroundColor = Style.backgroundColor(isApproved: approved)
    }

    func refreshImages() {
        timestampImageView.image = Style.timestampImage(isApproved: approved)
        if !approved {
            timestampImageView.tintColor = WPStyleGuide.alertYellowDark()
        }
    }

    func attributedDetailsText(_ isApproved: Bool) -> NSAttributedString {
        // Unwrap
        let unwrappedAuthor     = author ?? String()
        let unwrappedTitle      = postTitle ?? NSLocalizedString("(No Title)", comment: "Empty Post Title")
        let unwrappedContent    = content ?? String()

        // Styles
        let detailsBoldStyle    = Style.detailsBoldStyle(isApproved: isApproved)
        let detailsItalicsStyle = Style.detailsItalicsStyle(isApproved: isApproved)
        let detailsRegularStyle = Style.detailsRegularStyle(isApproved: isApproved)
        let regularRedStyle     = Style.detailsRegularRedStyle(isApproved: isApproved)

        // Localize the format
        var details = NSLocalizedString("%1$@ on %2$@: %3$@", comment: "'AUTHOR on POST TITLE: COMMENT' in a comment list")
        if unwrappedContent.isEmpty {
            details = NSLocalizedString("%1$@ on %2$@", comment: "'AUTHOR on POST TITLE' in a comment list")
        }

        // Arrange the Replacement Map
        let replacementMap  = [
            "%1$@": NSAttributedString(string: unwrappedAuthor, attributes: detailsBoldStyle),
            "%2$@": NSAttributedString(string: unwrappedTitle, attributes: detailsItalicsStyle),
            "%3$@": NSAttributedString(string: unwrappedContent, attributes: detailsRegularStyle)
        ]

        // Replace Author + Title + Content
        let attributedDetails = NSMutableAttributedString(string: details, attributes: regularRedStyle)

        for (key, attributedString) in replacementMap {
            let range = (attributedDetails.string as NSString).range(of: key)
            if range.location == NSNotFound {
                continue
            }

            attributedDetails.replaceCharacters(in: range, with: attributedString)
        }

        return attributedDetails
    }

}
