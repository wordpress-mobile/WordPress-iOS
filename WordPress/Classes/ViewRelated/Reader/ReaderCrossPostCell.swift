import AlamofireImage
import Foundation
import AutomatticTracks
import WordPressShared.WPStyleGuide

private struct Constants {
    static let blavatarPlaceholder: String = "post-blavatar-placeholder"
    static let xPostTitlePrefix = "X-post: "
    static let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
    static let siteTemplate = "%@ cross-posted from %@ to %@"
}

open class ReaderCrossPostCell: UITableViewCell {
    @IBOutlet fileprivate weak var blavatarImageView: UIImageView!
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var label: UILabel!
    @IBOutlet weak var borderView: UIView!

    @objc open weak var contentProvider: ReaderPostContentProvider?

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
        backgroundColor = .clear
        contentView.backgroundColor = .listBackground
        borderView?.backgroundColor = .listForeground
        label?.backgroundColor = .listForeground
        titleLabel?.backgroundColor = .listForeground
    }

    fileprivate func applyHighlightedEffect(_ highlighted: Bool, animated: Bool) {
        func updateBorder() {
            label.alpha = highlighted ? 0.50 : WPAlphaFull
            titleLabel.alpha = highlighted ? 0.50 : WPAlphaFull
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

        configureTitleLabel()
        configureLabel()
        configureBlavatarImage()
        configureAvatarImageView()
    }

    fileprivate func configureBlavatarImage() {
        // Always reset
        blavatarImageView.image = nil

        let placeholder = UIImage(named: Constants.blavatarPlaceholder)
        let size = blavatarImageView.frame.size.width * UIScreen.main.scale

        guard let contentProvider = contentProvider,
            let url = contentProvider.siteIconForDisplay(ofSize: Int(size)) else {
                blavatarImageView.image = placeholder
                return
        }

        let host = MediaHost(with: contentProvider) { error in
            CrashLogging.logError(error)
        }

        let mediaAuthenticator = MediaRequestAuthenticator()
        mediaAuthenticator.authenticatedRequest(for: url, from: host, onComplete: { [weak self] request in
            self?.blavatarImageView.af_setImage(withURLRequest: request, placeholderImage: placeholder)
        }) { [weak self] error in
            CrashLogging.logError(error)
            self?.blavatarImageView.image = placeholder
        }
    }

    fileprivate func configureAvatarImageView() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: Constants.blavatarPlaceholder)

        let url = contentProvider?.avatarURLForDisplay()
        if url != nil {
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    private func configureTitleLabel() {
         if var title = contentProvider?.titleForDisplay(), !title.isEmpty() {
            if let prefixRange = title.range(of: Constants.xPostTitlePrefix) {
                title.removeSubrange(prefixRange)
            }

            titleLabel.attributedText = NSAttributedString(string: title, attributes: readerCrossPostTitleAttributes)
            titleLabel.isHidden = false
        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }

    fileprivate func configureLabel() {
        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let template = contentProvider!.isCommentCrossPost() ? Constants.commentTemplate : Constants.siteTemplate

        let authorName: NSString = contentProvider!.authorForDisplay() as NSString
        let siteName = subDomainNameFromPath(contentProvider!.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider!.crossPostOriginSiteURLForDisplay())

        let subtitle = NSString(format: template as NSString, authorName, originName, siteName) as String
        let attrSubtitle = NSMutableAttributedString(string: subtitle, attributes: readerCrossPostSubtitleAttributes)

        attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: NSRange(location: 0, length: authorName.length))

        if let siteRange = subtitle.nsRange(of: siteName) {
            attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: siteRange)
        }

        if let originRange = subtitle.nsRange(of: originName) {
            attrSubtitle.setAttributes(readerCrossPostBoldSubtitleAttributes, range: originRange)
        }

        label.attributedText = attrSubtitle
    }

    fileprivate func subDomainNameFromPath(_ path: String) -> String {
        if let url = URL(string: path), let host = url.host {
            let arr = host.components(separatedBy: ".")
            return arr.first!
        }
        return ""
    }
}
