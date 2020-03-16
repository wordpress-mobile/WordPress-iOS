import Foundation
import WordPressShared.WPStyleGuide


// MARK: - NoteBlockCommentTableViewCell Renders a Comment Block Onscreen
//
class NoteBlockCommentTableViewCell: NoteBlockTextTableViewCell {

    // MARK: - Private Constants
    private typealias Style = WPStyleGuide.Notifications
    private let separatorUnapprovedInsets = UIEdgeInsets.zero

    /// Gravatar ImageView
    ///
    @IBOutlet private weak var gravatarImageView: CircularImageView!

    /// Source's Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Source's Details
    ///
    @IBOutlet private weak var detailsLabel: LongPressGestureLabel!

    /// Returns the Placeholder image, tinted for the current approval state
    ///
    private var placeholderImage: UIImage {
        return Style.blockGravatarPlaceholderImage(isApproved: isApproved)
    }

    /// onUserClick: Executed whenever any of the User's fields gets clicked
    ///
    @objc var onUserClick: (() -> Void)?

    /// onTimeStampLongPress: Executed whenever the user long press on the details label (that includes time stamp)
    ///
    @objc var onTimeStampLongPress: (() -> Void)?

    /// Comment's AttributedText Payload
    ///
    @objc var attributedCommentText: NSAttributedString? {
        didSet {
            refreshApprovalColors()
        }
    }

    /// Comments (Plain)  Text Payload
    ///
    @objc var commentText: String? {
        set {
            let text = newValue ?? String()
            attributedCommentText = NSAttributedString(string: text, attributes: Style.contentBlockRegularStyle)
        }
        get {
            return attributedCommentText?.string
        }
    }

    /// Indicates if the comment is approved, or not.
    ///
    /// -   Note:
    ///     After setting this property you should explicitly call `refreshSeparators` from within `UITableView.willDisplayCell`.
    ///     We're not doing so from `didSet` anymore since doing so might yield invalid `intrinsicContentSize` calculations,
    ///     which appears to be cached, and results in incorrect layouts.
    ///
    @objc var isApproved: Bool = false {
        didSet {
            refreshApprovalColors()
        }
    }

    /// Commenter's Name
    ///
    @objc var name: String? {
        set {
            titleLabel.text  = newValue
        }
        get {
            return titleLabel.text
        }
    }

    /// Timestamp of the comment
    ///
    @objc var timestamp: String? {
        didSet {
            refreshDetails()
        }
    }

    /// Originating Site
    ///
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

        titleLabel.font = Style.blockBoldFont
        titleLabel.isUserInteractionEnabled = true
        titleLabel.gestureRecognizers = [ UITapGestureRecognizer(target: self, action: #selector(titleWasPressed)) ]

        detailsLabel.font = Style.blockRegularFont
        detailsLabel.isUserInteractionEnabled = true
        detailsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(detailsWasPressed)))
        detailsLabel.longPressAction = { [weak self] in self?.onTimeStampLongPress?() }
    }



    // MARK: - Approval Color Helpers

    /// Updates the Separators Insets / Style. This API should be called from within `UITableView.willDisplayCell`.
    ///
    /// -   Note:
    ///     `readableSeparatorInsets`, if executed from within `cellForRowAtIndexPath`, will produce an "invalid" layout cycle (since there won't
    ///     be a superview). Such "Invalid" layout cycle appears to be yielding an invalid `intrinsicContentSize` calculation, which is then cached,
    ///     and we end up with strings cutoff onScreen. =(
    ///
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

    private func refreshDetails() {
        var details = timestamp ?? String()
        if let site = site, !site.isEmpty {
            details = String(format: "%@ • %@", details, site)
        }

        detailsLabel.text = details
    }

    private func refreshApprovalColors() {
        titleLabel.textColor = Style.blockTitleColorForComment(isApproved: isApproved)
        detailsLabel.textColor = Style.blockDetailsColorForComment(isApproved: isApproved)
        linkColor = Style.blockLinkColorForComment(isApproved: isApproved)
        attributedText = isApproved ? attributedCommentText : attributedCommentUnapprovedText
    }

    private var attributedCommentUnapprovedText: NSAttributedString? {
        guard let commentText = attributedCommentText?.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }

        let range = NSRange(location: 0, length: commentText.length)
        let textColor = Style.blockUnapprovedTextColor
        commentText.addAttribute(.foregroundColor, value: textColor, range: range)

        return commentText
    }

    @IBAction func titleWasPressed() {
        onUserClick?()
    }

    @IBAction func detailsWasPressed() {
        onUserClick?()
    }
}
