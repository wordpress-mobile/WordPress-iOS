import Foundation
import WordPressShared.WPStyleGuide

public class ReaderCrossPostCell: UITableViewCell
{

    @IBOutlet private weak var innerContentView: UIView!

    // Header realated Views
    @IBOutlet private weak var cardContentView: UIView!
    @IBOutlet private weak var cardBorderView: UIView!
    @IBOutlet private weak var blavatarImageView: UIImageView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var label: UILabel!

    public weak var contentProvider: ReaderPostContentProvider?

    let blavatarPlaceholder = "post-blavatar-placeholder"
    let xPostTitlePrefix = "X-post: "

    // MARK: - Accessors

    public var enableLoggedInFeatures: Bool = true

    public override var backgroundColor: UIColor? {
        didSet{
            contentView.backgroundColor = backgroundColor
            innerContentView?.backgroundColor = backgroundColor
            cardContentView?.backgroundColor = backgroundColor
            cardBorderView?.backgroundColor = backgroundColor
        }
    }

    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = self.highlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted == highlighted {
            return
        }
        applyHighlightedEffect(highlighted, animated: animated)
    }


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    /**
     Ignore taps in the card margins
     */
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if (!CGRectContainsPoint(cardContentView.frame, point)) {
            return nil
        }
        return super.hitTest(point, withEvent: event)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        applyHighlightedEffect(false, animated: false)
    }


    // MARK: - Appearance

    private func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()

        cardBorderView.layer.borderColor = WPStyleGuide.readerCardCellHighlightedBorderColor().CGColor
        cardBorderView.layer.borderWidth = 1.0
        cardBorderView.alpha = 0.0
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        let duration:NSTimeInterval = animated ? 0.25 : 0
        UIView.animateWithDuration(duration,
            delay: 0,
            options: .CurveEaseInOut,
            animations: {
                self.cardBorderView.alpha = highlighted ? 1.0 : 0.0
            }, completion: nil)
    }


    // MARK: - Configuration

    public func configureCell(contentProvider:ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureLabel()
        configureBlavatarImage()
        configureAvatarImageView()
    }

    private func configureBlavatarImage() {
        // Always reset
        blavatarImageView.image = nil

        let placeholder = UIImage(named: blavatarPlaceholder)

        let size = blavatarImageView.frame.size.width * UIScreen.mainScreen().scale
        let url = contentProvider?.siteIconForDisplayOfSize(Int(size))
        if url != nil {
            blavatarImageView.setImageWithURL(url!, placeholderImage: placeholder)
        } else {
            blavatarImageView.image = placeholder
        }
    }

    private func configureAvatarImageView() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: blavatarPlaceholder)

        let url = contentProvider?.avatarURLForDisplay()
        if url != nil {
            avatarImageView.setImageWithURL(url!, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    private func configureLabel() {

        // Compose the title.
        var title = contentProvider!.titleForDisplay()
        if title.containsString(xPostTitlePrefix) {
            title = title?.componentsSeparatedByString(xPostTitlePrefix).last
        }
        let titleAttributes = WPStyleGuide.readerCrossPostTitleAttributes() as! [String:AnyObject]
        let attrText = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)

        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
        let siteTemplate = "%@ cross-posted from %@ to %@"
        let template = contentProvider!.isCommentCrossPost() ? commentTemplate : siteTemplate

        let authorName:NSString = contentProvider!.authorForDisplay()
        let siteName = subDomainNameFromPath(contentProvider!.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider!.crossPostOriginSiteURLForDisplay())

        let subtitle = NSString(format: template, authorName, originName, siteName) as String
        let subtitleAttributes = WPStyleGuide.readerCrossPostSubtitleAttributes() as! [String:AnyObject]
        let boldSubtitleAttributes = WPStyleGuide.readerCrossPostBoldSubtitleAttributes() as! [String:AnyObject]
        let attrSubtitle = NSMutableAttributedString(string: subtitle, attributes: subtitleAttributes)
        attrSubtitle.setAttributes(boldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))

        // Add the subtitle to the attributed text
        attrText.appendAttributedString(attrSubtitle)

        label.attributedText = attrText
        invalidateIntrinsicContentSize()
    }

    private func subDomainNameFromPath(path:String) -> String {
        if let url = NSURL(string: path), host = url.host {
            let arr = host.componentsSeparatedByString(".")
            return "+\(arr.first!)"
        }
        return ""
    }
}
