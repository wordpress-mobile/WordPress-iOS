import Foundation
import WordPressShared.WPStyleGuide


class NoteBlockCommentTableViewCell: NoteBlockTextTableViewCell {
    typealias EventHandler = ((_ sender: AnyObject) -> Void)

    // MARK: - Public Properties
    @objc var onDetailsClick: EventHandler?

    @objc var attributedCommentText: NSAttributedString? {
        didSet {
            refreshApprovalColors()
        }
    }
    @objc var commentText: String? {
        set {
            let text = newValue ?? String()
            attributedCommentText = NSMutableAttributedString(string: text, attributes: Style.contentBlockRegularStyle)
        }
        get {
            return attributedCommentText?.string
        }
    }
    @objc var isApproved: Bool = false {
        didSet {
            refreshApprovalColors()
            refreshSeparators()
        }
    }
    @objc var name: String? {
        set {
            titleLabel.text  = newValue
        }
        get {
            return titleLabel.text
        }
    }
    @objc var timestamp: String? {
        didSet {
            refreshDetails()
        }
    }
    @objc var site: String? {
        didSet {
            refreshDetails()
        }
    }



    // MARK: - Public Methods
    @objc func downloadGravatarWithURL(_ url: URL?) {
        let gravatar = url.flatMap { Gravatar($0) }

        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)
    }

    @objc func downloadGravatarWithEmail(_ email: String?) {
        guard let unwrappedEmail = email else {
            gravatarImageView.image = placeholderImage
            return
        }

        gravatarImageView.downloadGravatarWithEmail(unwrappedEmail, placeholderImage: placeholderImage)
    }


    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        // Setup Labels
        titleLabel.font = Style.blockBoldFont
        detailsLabel.font = Style.blockRegularFont

        // Setup Recognizers
        detailsLabel.gestureRecognizers = [ UITapGestureRecognizer(target: self, action: #selector(NoteBlockCommentTableViewCell.detailsWasPressed(_:))) ]
        detailsLabel.isUserInteractionEnabled = true
    }



    // MARK: - Approval Color Helpers
    override func refreshSeparators() {
        // Left Separator
        separatorsView.leftVisible = !isApproved
        separatorsView.leftColor = Style.blockUnapprovedSideColor

        // Bottom Separator
        let bottomInsets = isApproved ? readableSeparatorInsets : separatorUnapprovedInsets
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = bottomInsets
        separatorsView.bottomColor = Style.blockSeparatorColorForComment(isApproved: isApproved)

        // Background
        separatorsView.backgroundColor = Style.blockBackgroundColorForComment(isApproved: isApproved)
    }

    fileprivate func refreshDetails() {
        var details = timestamp ?? String()
        if let unwrappedSite = site {
            details = String(format: "%@ • %@", details, unwrappedSite)
        }

        detailsLabel.text = details
    }

    fileprivate func refreshApprovalColors() {
        titleLabel.textColor = Style.blockTitleColorForComment(isApproved: isApproved)
        detailsLabel.textColor = Style.blockDetailsColorForComment(isApproved: isApproved)
        linkColor = Style.blockLinkColorForComment(isApproved: isApproved)
        attributedText = isApproved ? attributedCommentText : attributedCommentUnapprovedText
    }

    fileprivate var attributedCommentUnapprovedText: NSAttributedString? {
        guard let commentText = attributedCommentText?.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }

        let range = NSRange(location: 0, length: commentText.length)
        let textColor = Style.blockUnapprovedTextColor
        commentText.addAttribute(.foregroundColor, value: textColor, range: range)

        return commentText
    }




    // MARK: - Event Handlers
    @IBAction func detailsWasPressed(_ sender: AnyObject) {
        onDetailsClick?(sender)
    }


    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications

    // MARK: - Private Calculated Properties
    fileprivate var placeholderImage: UIImage {
        return Style.blockGravatarPlaceholderImage(isApproved: isApproved)
    }

    // MARK: - Private Constants
    fileprivate let separatorUnapprovedInsets = UIEdgeInsets.zero

    // MARK: - IBOutlets
    @IBOutlet fileprivate weak var actionsView: UIView!
    @IBOutlet fileprivate weak var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var detailsLabel: UILabel!
}
