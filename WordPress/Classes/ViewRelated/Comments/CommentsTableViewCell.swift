import Foundation
import WordPressShared.WPTableViewCell

open class CommentsTableViewCell: WPTableViewCell {
    // MARK: - Public Properties
    @objc open var author: String? {
        didSet {
            refreshDetailsLabel()
        }
    }
    @objc open var postTitle: String? {
        didSet {
            refreshDetailsLabel()
        }
    }
    @objc open var content: String? {
        didSet {
            refreshDetailsLabel()
        }
    }
    @objc open var timestamp: String? {
        didSet {
            refreshTimestampLabel()
        }
    }
    @objc open var approved: Bool = false {
        didSet {
            refreshTimestampLabel()
            refreshDetailsLabel()
            refreshBackground()
            refreshImages()
        }
    }


    // MARK: - Public Methods
    @objc open func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }

    @objc open func downloadGravatarWithGravatarEmail(_ email: String?) {
        guard let unwrappedEmail = email else {
            gravatarImageView.image = placeholderImage
            return
        }

        gravatarImageView.downloadGravatarWithEmail(unwrappedEmail, placeholderImage: placeholderImage)
    }


    // MARK: - Overwritten Methods
    open override func awakeFromNib() {
        super.awakeFromNib()

        assert(gravatarImageView != nil)
        assert(detailsLabel != nil)
        assert(timestampImageView != nil)
        assert(timestampLabel != nil)
    }

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



    // MARK: - Private Helpers
    fileprivate func refreshDetailsLabel() {
        detailsLabel.attributedText = attributedDetailsText(approved)
        layoutIfNeeded()
    }

    fileprivate func refreshTimestampLabel() {
        guard let timestamp = timestamp else {
            return
        }
        let style               = Style.timestampStyle(isApproved: approved)
        let formattedTimestamp: String
        if approved {
            formattedTimestamp = timestamp
        } else {
            let pendingLabel = NSLocalizedString("Pending", comment: "Status name for a comment that hasn't yet been approved.")
            formattedTimestamp = "\(timestamp) · \(pendingLabel)"
        }
        timestampLabel?.attributedText = NSAttributedString(string: formattedTimestamp, attributes: style)
    }

    fileprivate func refreshBackground() {
        let color = Style.backgroundColor(isApproved: approved)
        backgroundColor = color
    }

    fileprivate func refreshImages() {
        timestampImageView.image = Style.timestampImage(isApproved: approved)
        if !approved {
            timestampImageView.tintColor = WPStyleGuide.alertYellowDark()
        }
    }



    // MARK: - Details Helpers
    fileprivate func attributedDetailsText(_ isApproved: Bool) -> NSAttributedString {
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



    // MARK: - Aliases
    typealias Style = WPStyleGuide.Comments

    // MARK: - Private Properties
    fileprivate var gravatarURL: URL?

    // MARK: - Private Calculated Properties
    fileprivate var placeholderImage: UIImage {
        return Style.gravatarPlaceholderImage(isApproved: approved)
    }

    // MARK: - IBOutlets
    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var detailsLabel: UILabel!
    @IBOutlet fileprivate var timestampImageView: UIImageView!
    @IBOutlet fileprivate var timestampLabel: UILabel!
}
