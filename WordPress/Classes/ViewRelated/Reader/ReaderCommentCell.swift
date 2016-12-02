import UIKit
import WordPressShared
import Gridicons

@objc protocol ReaderCommentCellDelegate: WPRichContentViewDelegate
{
    func cell(cell: ReaderCommentCell, didTapAuthor comment: Comment)
    func cell(cell: ReaderCommentCell, didTapLike comment: Comment)
    func cell(cell: ReaderCommentCell, didTapReply comment: Comment)
}

class ReaderCommentCell : UITableViewCell
{
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
        get {
            if let comment = comment, let post = comment.post as? ReaderPost {
                return post.commentsOpen && enableLoggedInFeatures
            }
            return false
        }
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

        authorButton.titleLabel?.lineBreakMode = .ByTruncatingTail

        textView.textContainerInset = Constants.textViewInsets
    }


    func setupReplyButton() {
        let icon = Gridicon.iconOfType(.Reply, withSize: Constants.buttonSize)
        let tintedIcon = icon.imageWithTintColor(WPStyleGuide.grey())
        let highlightedIcon = icon.imageWithTintColor(WPStyleGuide.lightBlue())

        replyButton.setImage(tintedIcon, forState: .Normal)
        replyButton.setImage(highlightedIcon, forState: .Highlighted)

        let title = NSLocalizedString("Reply", comment: "Verb. Title of the Reader comments screen reply button. Tapping the button sends a reply to a comment or post.")
        replyButton.setTitle(title, forState: .Normal)
    }


    func setupLikeButton() {
        let size = Constants.buttonSize
        let tintedIcon = Gridicon.iconOfType(.StarOutline, withSize: size).imageWithTintColor(WPStyleGuide.grey())
        let highlightedIcon = Gridicon.iconOfType(.Star, withSize: size).imageWithTintColor(WPStyleGuide.lightBlue())
        let selectedIcon = Gridicon.iconOfType(.Star, withSize: size).imageWithTintColor(WPStyleGuide.jazzyOrange())

        likeButton.setImage(tintedIcon, forState: .Normal)
        likeButton.setImage(highlightedIcon, forState: .Highlighted)
        likeButton.setImage(selectedIcon, forState: .Selected)
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
            avatarImageView.setImageWithURL(url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }


    func configureAuthorButton() {
        guard let comment = comment else {
            return
        }

        authorButton.enabled = true
        authorButton.setTitle(comment.author, forState: .Normal)
        authorButton.setTitleColor(WPStyleGuide.lightBlue(), forState: .Highlighted)
        authorButton.setTitleColor(WPStyleGuide.greyDarken30(), forState: .Disabled)

        if comment.authorIsPostAuthor() {
            authorButton.setTitleColor(WPStyleGuide.jazzyOrange(), forState: .Normal)
        } else if comment.hasAuthorUrl() {
            authorButton.setTitleColor(WPStyleGuide.wordPressBlue(), forState: .Normal)
        } else {
            authorButton.enabled = false
        }
    }


    func configureTime() {
        guard let comment = comment else {
            return
        }
        timeLabel.text = comment.dateForDisplay().shortString()
    }


    func configureText() {
        guard let comment = comment else {
            return
        }

        textView.isPrivate = comment.isPrivateContent()
        textView.content = comment.contentForDisplay()
    }


    func configureActionBar() {
        guard let comment = comment else {
            return
        }

        actionBar.hidden = !enableLoggedInFeatures
        replyButton.hidden = !showReply

        var title = NSLocalizedString("Like", comment: "Verb. Button title. Tap to like a commnet")
        let count = comment.numberOfLikes().integerValue
        if count == 1 {
            title = "\(count) \(title)"
        } else if count > 1 {
            title = NSLocalizedString("Likes", comment: "Noun. Button title.  Tap to like a comment.")
            title = "\(count) \(title)"
        }
        likeButton.setTitle(title, forState: .Normal)
        likeButton.selected = comment.isLiked
    }


    func updateLeadingContentConstraint() {
        leadingContentConstraint.constant = CGFloat(indentationLevel) * indentationWidth
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
