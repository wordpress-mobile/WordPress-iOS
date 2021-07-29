import UIKit
import AutomatticTracks

protocol ReaderDetailHeaderViewDelegate {
    func didTapBlogName()
    func didTapMenuButton(_ sender: UIView)
    func didTapHeaderAvatar()
    func didTapFollowButton(completion: @escaping () -> Void)
    func didSelectTopic(_ topic: String)
}

class ReaderDetailHeaderView: UIStackView, NibLoadable {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var blavatarImageView: UIImageView!
    @IBOutlet weak var blogURLLabel: UILabel!
    @IBOutlet weak var blogNameButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleBottomPaddingView: UIView!
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorSeparatorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var iPadFollowButton: UIButton!

    @IBOutlet weak var collectionViewPaddingView: UIView!
    @IBOutlet weak var topicsCollectionView: TopicsCollectionView!

    /// Temporary work around until white headers are shipped app-wide,
    /// allowing Reader Detail to use a blue navbar.
    var useCompatibilityMode: Bool = false

    /// The post to show details in the header
    ///
    private var post: ReaderPost?

    /// The user interface direction for the view's semantic content attribute.
    ///
    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    /// Any interaction with the header is sent to the delegate
    ///
    var delegate: ReaderDetailHeaderViewDelegate?

    func configure(for post: ReaderPost) {
        self.post = post

        configureSiteImage()
        configureURL()
        configureBlogName()
        configureTitle()
        configureByLabel()
        configureAuthorLabel()
        configureDateLabel()
        configureFollowButton()
        configureNotifications()
        configureTopicsCollectionView()

        prepareForVoiceOver()
        prepareMenuForVoiceOver()
        preparePostTitleForVoiceOver()
    }

    func refreshFollowButton() {
        configureFollowButton()
    }

    @IBAction func didTapBlogName(_ sender: Any) {
        delegate?.didTapBlogName()
    }

    @IBAction func didTapMenuButton(_ sender: UIButton) {
        delegate?.didTapMenuButton(sender)
    }

    @IBAction func didTapFollowButton(_ sender: Any) {
        followButton.isSelected = !followButton.isSelected
        iPadFollowButton.isSelected = !followButton.isSelected
        followButton.isUserInteractionEnabled = false

        delegate?.didTapFollowButton() { [weak self] in
            self?.followButton.isUserInteractionEnabled = true
        }
    }

    @objc func didTapHeaderAvatar(_ gesture: UITapGestureRecognizer) {
        if gesture.state != .ended {
            return
        }

        delegate?.didTapHeaderAvatar()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.applyReaderCardBylineLabelStyle(blogURLLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)

        titleLabel.backgroundColor = .basicBackground
        blogNameButton.setTitleColor(WPStyleGuide.readerCardBlogNameLabelTextColor(), for: .normal)
        blogNameButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .bold)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        configureFollowButton()
    }

    private func configureSiteImage() {
        let placeholder = UIImage(named: "post-blavatar-placeholder")
        blavatarImageView.image = placeholder

        let size = blavatarImageView.frame.size.width * UIScreen.main.scale
        if let url = post?.siteIconForDisplay(ofSize: Int(size)) {
            blavatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }
    }

    private func configureURL() {
        guard let siteURL = post?.siteURLForDisplay() as NSString? else {
            return
        }

        blogURLLabel.text = siteURL.components(separatedBy: "//").last
    }

    private func configureBlogName() {
        let blogName = post?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, for: UIControl.State())
        blogNameButton.setTitle(blogName, for: .highlighted)
        blogNameButton.setTitle(blogName, for: .disabled)
        blogNameButton.isAccessibilityElement = false
        blogNameButton.naturalContentHorizontalAlignment = .leading

        // Enable button only if not previewing a site.
        if let topic = post?.topic {
            blogNameButton.isEnabled = !ReaderHelpers.isTopicSite(topic)
        }

        // If the button is enabled also listen for taps on the avatar.
        if blogNameButton.isEnabled {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(didTapHeaderAvatar(_:)))
            blavatarImageView.addGestureRecognizer(tgr)
        }
    }

    private func configureTitle() {
        if let title = post?.titleForDisplay() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: WPStyleGuide.readerDetailTitleAttributes())
            titleLabel.isHidden = false

        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }

    private func configureByLabel() {
        byLabel.text = NSLocalizedString("By ", comment: "Label for the post author in the post detail.")
    }

    private func configureAuthorLabel() {
        guard
            let displayName = post?.authorDisplayName,
            !displayName.isEmpty
        else {
            authorLabel.isHidden = true
            authorSeparatorLabel.isHidden = true
            byLabel.isHidden = true
            return
        }

        authorLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .bold)
        authorLabel.text = displayName

        authorLabel.isHidden = false
        authorSeparatorLabel.isHidden = false
        byLabel.isHidden = false

    }

    private func configureDateLabel() {
        dateLabel.text = post?.dateForDisplay()?.toMediumString()
    }

    private func configureFollowButton() {
        followButton.isSelected = post?.isFollowing() ?? false
        iPadFollowButton.isSelected = post?.isFollowing() ?? false

        followButton.setImage(UIImage.gridicon(.readerFollow, size: CGSize(width: 24, height: 24)).imageWithTintColor(.primary), for: .normal)
        followButton.setImage(UIImage.gridicon(.readerFollowing, size: CGSize(width: 24, height: 24)).imageWithTintColor(.gray(.shade20)), for: .selected)
        WPStyleGuide.applyReaderFollowButtonStyle(iPadFollowButton)

        let isCompact = traitCollection.horizontalSizeClass == .compact
        followButton.isHidden = !isCompact
        iPadFollowButton.isHidden = isCompact
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    func configureTopicsCollectionView() {
        guard
            let post = post,
            let tags = post.tagsForDisplay(),
            !tags.isEmpty
        else {
            topicsCollectionView.isHidden = true
            collectionViewPaddingView.isHidden = true
            return
        }

        let featuredImageIsDisplayed = useCompatibilityMode || ReaderDetailFeaturedImageView.shouldDisplayFeaturedImage(with: post)
        collectionViewPaddingView.isHidden = !featuredImageIsDisplayed

        topicsCollectionView.topicDelegate = self
        topicsCollectionView.topics = tags
        topicsCollectionView.isHidden = false
    }

    @objc private func preferredContentSizeChanged() {
        configureTitle()
    }

    private func prepareForVoiceOver() {
        guard let post = post else {
            blogNameButton.isAccessibilityElement = false
            return
        }

        blogNameButton.isAccessibilityElement = true
        blogNameButton.accessibilityTraits = [.staticText, .button]
        blogNameButton.accessibilityHint = NSLocalizedString("Shows the site's posts.", comment: "Accessibility hint for the site name and URL button on Reader's Post Details.")
        if let label = blogNameLabel(post) {
            blogNameButton.accessibilityLabel = label
        }
    }

    private func prepareMenuForVoiceOver() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button on Reader's post details")
        menuButton.accessibilityTraits = UIAccessibilityTraits.button
        menuButton.accessibilityHint = NSLocalizedString("Shows more options.", comment: "Accessibility hint for the More button on Reader's post details")
    }

    private func blogNameLabel(_ post: ReaderPost) -> String? {
        guard let postedIn = post.blogNameForDisplay(),
            let postedBy = post.authorDisplayName,
            let postedAtURL = post.siteURLForDisplay()?.components(separatedBy: "//").last else {
                return nil
        }

        guard let postedOn = post.dateCreated?.toMediumString() else {
            let format = NSLocalizedString("Posted in %@, at %@, by %@.", comment: "Accessibility label for the blog name in the Reader's post details, without date. Placeholders are blog title, blog URL, author name")
            return String(format: format, postedIn, postedAtURL, postedBy)
        }

        let format = NSLocalizedString("Posted in %@, at %@, by %@, %@", comment: "Accessibility label for the blog name in the Reader's post details. Placeholders are blog title, blog URL, author name, published date")
        return String(format: format, postedIn, postedAtURL, postedBy, postedOn)
    }

    private func preparePostTitleForVoiceOver() {
        guard let title = post?.titleForDisplay() else {
            return
        }
        isAccessibilityElement = false

        titleLabel.accessibilityLabel = title
        titleLabel.accessibilityTraits = .header
    }

}

extension ReaderDetailHeaderView: ReaderTopicCollectionViewCoordinatorDelegate {
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didChangeState: ReaderTopicCollectionViewState) {
        self.layoutIfNeeded()
    }

    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didSelectTopic topic: String) {
        delegate?.didSelectTopic(topic)
    }
}
