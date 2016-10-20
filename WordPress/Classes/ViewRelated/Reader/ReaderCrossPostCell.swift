import Foundation
import WordPressShared.WPStyleGuide

public class ReaderCrossPostCell: UITableViewCell
{
    @IBOutlet private weak var blavatarImageView: UIImageView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var label: UILabel!

    public weak var contentProvider: ReaderPostContentProvider?

    let blavatarPlaceholder = "post-blavatar-placeholder"
    let xPostTitlePrefix = "X-post: "

    // MARK: - Accessors

    private lazy var readerCrossPostTitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostTitleAttributes()
    }()

    private lazy var readerCrossPostSubtitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostSubtitleAttributes()
    }()

    private lazy var readerCrossPostBoldSubtitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostBoldSubtitleAttributes()
    }()

    public var enableLoggedInFeatures: Bool = true

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


    // MARK: - Appearance

    private func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        label?.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        func updateBorder() {
            label.alpha = highlighted ? 0.50 : WPAlphaFull
        }
        guard animated else {
            updateBorder()
            return
        }
        UIView.animateWithDuration(0.25,
            delay: 0,
            options: .CurveEaseInOut,
            animations:updateBorder,
            completion: nil)
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
        let attrText = NSMutableAttributedString(string: "\(title)\n", attributes: readerCrossPostTitleAttributes)

        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
        let siteTemplate = "%@ cross-posted from %@ to %@"
        let template = contentProvider!.isCommentCrossPost() ? commentTemplate : siteTemplate

        let authorName:NSString = contentProvider!.authorForDisplay()
        let siteName = subDomainNameFromPath(contentProvider!.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider!.crossPostOriginSiteURLForDisplay())

        let subtitle = NSString(format: template, authorName, originName, siteName) as String
        let attrSubtitle = NSMutableAttributedString(string: subtitle, attributes: readerCrossPostSubtitleAttributes)
        attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))

        // Add the subtitle to the attributed text
        attrText.appendAttributedString(attrSubtitle)

        label.attributedText = attrText
    }

    private func subDomainNameFromPath(path:String) -> String {
        if let url = NSURL(string: path), host = url.host {
            let arr = host.componentsSeparatedByString(".")
            return "+\(arr.first!)"
        }
        return ""
    }
}
