import Foundation
import WordPressShared.WPStyleGuide

open class ReaderCrossPostCell: UITableViewCell {
    @IBOutlet fileprivate weak var blavatarImageView: UIImageView!
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var label: UILabel!

    @objc open weak var contentProvider: ReaderPostContentProvider?

    @objc let blavatarPlaceholder = "post-blavatar-placeholder"
    @objc let xPostTitlePrefix = "X-post: "

    // MARK: - Accessors

    fileprivate lazy var readerCrossPostTitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCrossPostTitleAttributes()
    }()

    fileprivate lazy var readerCrossPostSubtitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCrossPostSubtitleAttributes()
    }()

    fileprivate lazy var readerCrossPostBoldSubtitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCrossPostBoldSubtitleAttributes()
    }()

    @objc open var enableLoggedInFeatures: Bool = true

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
        contentView.backgroundColor = .listBackground
        label?.backgroundColor = .listBackground
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
            options: UIView.AnimationOptions(),
            animations: updateBorder)
    }


    // MARK: - Configuration

    @objc open func configureCell(_ contentProvider: ReaderPostContentProvider) {
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
            blavatarImageView.downloadImage(from: url, placeholderImage: placeholder)
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
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    fileprivate func configureLabel() {

        // Compose the title.
        var title = contentProvider!.titleForDisplay() ?? ""
        if let prefixRange = title.range(of: xPostTitlePrefix) {
            title.removeSubrange(prefixRange)
        }

        let attrText = NSMutableAttributedString(string: "\(title)\n", attributes: readerCrossPostTitleAttributes)

        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
        let siteTemplate = "%@ cross-posted from %@ to %@"
        let template = contentProvider!.isCommentCrossPost() ? commentTemplate : siteTemplate

        let authorName: NSString = contentProvider!.authorForDisplay() as NSString
        let siteName = subDomainNameFromPath(contentProvider!.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider!.crossPostOriginSiteURLForDisplay())

        let subtitle = NSString(format: template as NSString, authorName, originName, siteName) as String
        let attrSubtitle = NSMutableAttributedString(string: subtitle, attributes: readerCrossPostSubtitleAttributes)
        attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))

        // Add the subtitle to the attributed text
        attrText.append(attrSubtitle)

        label.attributedText = attrText
    }

    fileprivate func subDomainNameFromPath(_ path: String) -> String {
        if let url = URL(string: path), let host = url.host {
            let arr = host.components(separatedBy: ".")
            return "+\(arr.first!)"
        }
        return ""
    }
}
