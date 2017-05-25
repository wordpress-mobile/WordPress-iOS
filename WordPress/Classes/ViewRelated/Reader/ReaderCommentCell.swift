import UIKit
import WordPressShared
import Gridicons

@objc protocol ReaderCommentCellDelegate: WPRichContentViewDelegate {
    func cell(_ cell: ReaderCommentCell, didTapAuthor comment: Comment)
    func cell(_ cell: ReaderCommentCell, didTapLike comment: Comment)
    func cell(_ cell: ReaderCommentCell, didTapReply comment: Comment)
}

class ReaderCommentCell: UITableViewCell {
    struct Constants {
        // Because a stackview is managing layout we tweak text insets to fine tune things.
        // Insets:
        // Top 2: Just a bit of vertical padding so the text isn't too close to the label above.
        // Left -4: So the left edge of the text matches the left edge of the other views.
        // Bottom -16: Removes some of the padding normally added to the bottom of a textview.
        static let textViewInsets = UIEdgeInsets(top: 2, left: -4, bottom: -16, right: 0)
        static let buttonSize = CGSize(width: 20, height: 20)
    }

    var enableLoggedInFeatures = false

    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var authorButton: UIButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var textView: WPRichContentView!
    @IBOutlet var replyButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var actionBar: UIStackView!
    @IBOutlet var leadingContentConstraint: NSLayoutConstraint!

    weak var delegate: ReaderCommentCellDelegate? {
        didSet {
            textView.delegate = delegate
        }
    }

    var comment: Comment?

    var showReply: Bool {
        if let comment = comment, let post = comment.post as? ReaderPost {
            return post.commentsOpen && enableLoggedInFeatures
        }
        return false
    }

    var showLike: Bool {
        if let comment = comment, let post = comment.post as? ReaderPost,
            let blog = blogWithBlogID(post.siteID) {
            return blog.supports(.commentLikes)
        }
        return false
    }

    override var indentationLevel: Int {
        didSet {
            updateLeadingContentConstraint()
        }
    }

    override var indentationWidth: CGFloat {
        didSet {
            updateLeadingContentConstraint()
        }
    }

    // MARK: - Lifecycle Methods


    override func awakeFromNib() {
        super.awakeFromNib()

        setupReplyButton()
        setupLikeButton()
        applyStyles()
    }


    // MARK: = Setup


    func applyStyles() {
        WPStyleGuide.applyReaderCardSiteButtonStyle(authorButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(timeLabel)

        authorButton.titleLabel?.lineBreakMode = .byTruncatingTail

        textView.textContainerInset = Constants.textViewInsets
    }


    func setupReplyButton() {
        let icon = Gridicon.iconOfType(.reply, withSize: Constants.buttonSize)
        let tintedIcon = icon.imageWithTintColor(WPStyleGuide.grey())?.rotate180Degrees()
        let highlightedIcon = icon.imageWithTintColor(WPStyleGuide.lightBlue())?.rotate180Degrees()

        replyButton.setImage(tintedIcon, for: .normal)
        replyButton.setImage(highlightedIcon, for: .highlighted)

        let title = NSLocalizedString("Reply", comment: "Verb. Title of the Reader comments screen reply button. Tapping the button sends a reply to a comment or post.")
        replyButton.setTitle(title, for: .normal)
        replyButton.setTitleColor(WPStyleGuide.grey(), for: .normal)
    }


    func setupLikeButton() {
        let size = Constants.buttonSize
        let tintedIcon = Gridicon.iconOfType(.starOutline, withSize: size).imageWithTintColor(WPStyleGuide.grey())
        let highlightedIcon = Gridicon.iconOfType(.star, withSize: size).imageWithTintColor(WPStyleGuide.lightBlue())
        let selectedIcon = Gridicon.iconOfType(.star, withSize: size).imageWithTintColor(WPStyleGuide.jazzyOrange())

        likeButton.setImage(tintedIcon, for: .normal)
        likeButton.setImage(highlightedIcon, for: .highlighted)
        likeButton.setImage(selectedIcon, for: .selected)

        likeButton.setTitleColor(WPStyleGuide.grey(), for: .normal)
    }


    // MARK: - Configuration


    func configureCell(comment: Comment) {
        self.comment = comment

        configureAvatar()
        configureAuthorButton()
        configureTime()
        configureText()
        configureActionBar()
    }


    func configureAvatar() {
        guard let comment = comment else {
            return
        }

        let placeholder = UIImage(named: "gravatar")
        if let url = comment.avatarURLForDisplay() {
            avatarImageView.setImageWith(url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }


    func configureAuthorButton() {
        guard let comment = comment else {
            return
        }

        authorButton.isEnabled = true
        authorButton.setTitle(comment.author, for: .normal)
        authorButton.setTitleColor(WPStyleGuide.lightBlue(), for: .highlighted)
        authorButton.setTitleColor(WPStyleGuide.greyDarken30(), for: .disabled)

        if comment.authorIsPostAuthor() {
            authorButton.setTitleColor(WPStyleGuide.jazzyOrange(), for: .normal)
        } else if comment.hasAuthorUrl() {
            authorButton.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)
        } else {
            authorButton.isEnabled = false
        }
    }


    func configureTime() {
        guard let comment = comment else {
            return
        }

        timeLabel.text = (comment.dateForDisplay() as NSDate).mediumString()
    }


    func configureText() {
        guard let comment = comment else {
            return
        }

        textView.isPrivate = comment.isPrivateContent()
        // Use `content` vs `contentForDisplay`. Hierarchcial comments are already
        // correctly formatted during the sync process.
        textView.content = comment.content
    }


    func configureActionBar() {
        guard let comment = comment else {
            return
        }

        actionBar.isHidden = !enableLoggedInFeatures
        replyButton.isHidden = !showReply
        likeButton.isHidden = !showLike

        if (!likeButton.isHidden) {
            var title = NSLocalizedString("Like", comment: "Verb. Button title. Tap to like a commnet")
            let count = comment.numberOfLikes().intValue
            if count == 1 {
                title = "\(count) \(title)"
            } else if count > 1 {
                title = NSLocalizedString("Likes", comment: "Noun. Button title.  Tap to like a comment.")
                title = "\(count) \(title)"
            }
            likeButton.setTitle(title, for: .normal)
            likeButton.isSelected = comment.isLiked
        }
    }


    func updateLeadingContentConstraint() {
        leadingContentConstraint.constant = CGFloat(indentationLevel) * indentationWidth
    }


    func ensureTextViewLayout() {
        textView.updateLayoutForAttachments()
    }


    // MARK: - Actions


    @IBAction func handleAuthorTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapAuthor: comment)
    }


    @IBAction func handleReplyTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapReply: comment)
    }


    @IBAction func handleLikeTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapLike: comment)
    }

}

// MARK: - Helpers
//
private extension ReaderCommentCell {
    func blogWithBlogID(_ blogID: NSNumber?) -> Blog? {
        guard let blogID = blogID else {
            return nil
        }

        let mainContext = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: mainContext)
        return service.blog(byBlogId: blogID)
    }
}
