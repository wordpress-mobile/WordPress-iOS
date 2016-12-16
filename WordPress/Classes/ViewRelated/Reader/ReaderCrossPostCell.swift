import Foundation
import WordPressShared.WPStyleGuide

open class ReaderCrossPostCell: UITableViewCell
{
    @IBOutlet fileprivate weak var blavatarImageView: UIImageView!
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var label: UILabel!

    open weak var contentProvider: ReaderPostContentProvider?

    let blavatarPlaceholder = "post-blavatar-placeholder"
    let xPostTitlePrefix = "X-post: "

    // MARK: - Accessors

    fileprivate lazy var readerCrossPostTitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostTitleAttributes()
    }()

    fileprivate lazy var readerCrossPostSubtitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostSubtitleAttributes()
    }()

    fileprivate lazy var readerCrossPostBoldSubtitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCrossPostBoldSubtitleAttributes()
    }()

    open var enableLoggedInFeatures: Bool = true

    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = self.isHighlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted == highlighted {
            return
        }
        applyHighlightedEffect(highlighted, animated: animated)
    }


    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }


    // MARK: - Appearance

    fileprivate func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        label?.backgroundColor = WPStyleGuide.greyLighten30()
    }

    fileprivate func applyHighlightedEffect(_ highlighted: Bool, animated: Bool) {
        func updateBorder() {
            label.alpha = highlighted ? 0.50 : WPAlphaFull
        }
        guard animated else {
            updateBorder()
            return
        }
        UIView.animate(withDuration: 0.25,
            delay: 0,
            options: UIViewAnimationOptions(),
            animations:updateBorder,
            completion: nil)
    }


    // MARK: - Configuration

    open func configureCell(_ contentProvider:ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureLabel()
        configureBlavatarImage()
        configureAvatarImageView()
    }

    fileprivate func configureBlavatarImage() {
        // Always reset
        blavatarImageView.image = nil

        let placeholder = UIImage(named: blavatarPlaceholder)

        let size = blavatarImageView.frame.size.width * UIScreen.main.scale
        let url = contentProvider?.siteIconForDisplay(ofSize: Int(size))
        if url != nil {
            blavatarImageView.setImageWith(url!, placeholderImage: placeholder)
        } else {
            blavatarImageView.image = placeholder
        }
    }

    fileprivate func configureAvatarImageView() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: blavatarPlaceholder)

        let url = contentProvider?.avatarURLForDisplay()
        if url != nil {
            avatarImageView.setImageWith(url!, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    fileprivate func configureLabel() {

        // Compose the title.
        var title = contentProvider!.titleForDisplay()
        if (title?.contains(xPostTitlePrefix))! {
            title = title?.components(separatedBy: xPostTitlePrefix).last
        }
        let attrText = NSMutableAttributedString(string: "\(title)\n", attributes: readerCrossPostTitleAttributes)

        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
        let siteTemplate = "%@ cross-posted from %@ to %@"
        let template = contentProvider!.isCommentCrossPost() ? commentTemplate : siteTemplate

        let authorName:NSString = contentProvider!.authorForDisplay() as NSString
        let siteName = subDomainNameFromPath(contentProvider!.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider!.crossPostOriginSiteURLForDisplay())

        let subtitle = NSString(format: template as NSString, authorName, originName, siteName) as String
        let attrSubtitle = NSMutableAttributedString(string: subtitle, attributes: readerCrossPostSubtitleAttributes)
        attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))

        // Add the subtitle to the attributed text
        attrText.append(attrSubtitle)

        label.attributedText = attrText
    }

    fileprivate func subDomainNameFromPath(_ path:String) -> String {
        if let url = URL(string: path), let host = url.host {
            let arr = host.components(separatedBy: ".")
            return "+\(arr.first!)"
        }
        return ""
    }
}
