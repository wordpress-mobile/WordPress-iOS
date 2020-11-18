import AlamofireImage
import Foundation
import AutomatticTracks
import WordPressShared.WPStyleGuide

open class ReaderCrossPostCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet private weak var blavatarImageView: UIImageView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var borderView: UIView!

    private weak var contentProvider: ReaderPostContentProvider?

    // MARK: - Accessors

    private lazy var readerCrossPostTitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCrossPostTitleAttributes()
    }()

    private lazy var readerCrossPostSubtitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCrossPostSubtitleAttributes()
    }()

    private lazy var readerCrossPostBoldSubtitleAttributes: [NSAttributedString.Key: Any] = {
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

    // MARK: - Configuration

    @objc open func configureCell(_ contentProvider: ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureTitleLabel()
        configureLabel()
        configureBlavatarImage()
        configureAvatarImageView()
    }

}

// MARK: - Private Methods

private extension ReaderCrossPostCell {

    struct Constants {
        static let blavatarPlaceholderImage: UIImage? = UIImage(named: "post-blavatar-placeholder")
        static let avatarPlaceholderImage: UIImage? = UIImage(named: "gravatar")
        static let imageBorderWidth: CGFloat = 1
        static let xPostTitlePrefix = "X-post: "
        static let commentTemplate = "%@ left a comment on %@, cross-posted to %@"
        static let siteTemplate = "%@ cross-posted from %@ to %@"
    }

    // MARK: - Appearance

    func applyStyles() {
        backgroundColor = .clear
        contentView.backgroundColor = .listBackground
        borderView?.backgroundColor = .listForeground
        label?.backgroundColor = .listForeground
        titleLabel?.backgroundColor = .listForeground
    }

    func applyHighlightedEffect(_ highlighted: Bool, animated: Bool) {
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

    func configureBlavatarImage() {
        configureAvatarBorder(blavatarImageView)
        let placeholder = Constants.blavatarPlaceholderImage
        let size = blavatarImageView.frame.size.width * UIScreen.main.scale

        // Always reset
        blavatarImageView.image = placeholder

        guard let contentProvider = contentProvider,
            let url = contentProvider.siteIconForDisplay(ofSize: Int(size)) else {
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

    func configureAvatarImageView() {
        configureAvatarBorder(avatarImageView)
        let placeholder = Constants.avatarPlaceholderImage

        // Always reset
        avatarImageView.image = placeholder

        if let url = contentProvider?.avatarURLForDisplay() {
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }
    }

    func configureAvatarBorder(_ imageView: UIImageView) {
        imageView.layer.borderColor = WPStyleGuide.readerCardBlogIconBorderColor().cgColor
        imageView.layer.borderWidth = Constants.imageBorderWidth
        imageView.layer.masksToBounds = true
    }

    func configureTitleLabel() {
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

    func configureLabel() {
        guard let contentProvider = contentProvider else {
            return
        }

        // Compose the subtitle
        // These templates are deliberately not localized (for now) given the intended audience.
        let template = contentProvider.isCommentCrossPost() ? Constants.commentTemplate : Constants.siteTemplate

        let authorName: NSString = contentProvider.authorForDisplay() as NSString
        let siteName = subDomainNameFromPath(contentProvider.siteURLForDisplay())
        let originName = subDomainNameFromPath(contentProvider.crossPostOriginSiteURLForDisplay())

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

    func subDomainNameFromPath(_ path: String) -> String {
        guard let url = URL(string: path),
              let host = url.host else {
            return ""
        }

        return host.components(separatedBy: ".").first ?? ""
    }

}
