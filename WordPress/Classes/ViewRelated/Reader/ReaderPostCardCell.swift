import AutomatticTracks
import Foundation
import WordPressShared
import Gridicons

private struct Constants {
    static let featuredMediaCornerRadius: CGFloat = 4
    static let imageBorderWidth: CGFloat = 1
    static let featuredMediaTopSpacing: CGFloat = 8
    static let headerBottomSpacing: CGFloat = 8
    static let summaryMaxNumberOfLines: NSInteger = 2
}

@objc public protocol ReaderPostCellDelegate: NSObjectProtocol {
    func readerCell(_ cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, followActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, shareActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, reblogActionForProvider provider: ReaderPostContentProvider)
    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String?
}

@objc open class ReaderPostCardCell: UITableViewCell {
    // MARK: - Properties

    // Wrapper views
    @IBOutlet fileprivate weak var contentStackView: UIStackView!

    // Header realated Views

    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var headerBlogButton: UIButton!
    @IBOutlet fileprivate weak var blogNameLabel: UILabel!
    @IBOutlet fileprivate weak var blogHostNameLabel: UILabel!
    @IBOutlet fileprivate weak var bylineLabel: UILabel!
    @IBOutlet weak var bylineSeparatorLabel: UILabel!

    // Card views
    @IBOutlet fileprivate weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet fileprivate weak var titleLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var summaryLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet fileprivate weak var actionStackView: UIStackView!

    // Helper Views
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons

    @IBOutlet var actionButtons: [UIButton]!
    @IBOutlet fileprivate weak var saveForLaterButton: UIButton!
    @IBOutlet fileprivate weak var likeActionButton: UIButton!
    @IBOutlet fileprivate weak var commentActionButton: UIButton!
    @IBOutlet fileprivate weak var menuButton: UIButton!
    @IBOutlet fileprivate weak var reblogActionButton: UIButton!

    // Layout Constraints
    @IBOutlet fileprivate weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    @objc open weak var delegate: ReaderPostCellDelegate?
    @objc open weak var contentProvider: ReaderPostContentProvider?

    fileprivate var featuredImageDesiredWidth = CGFloat()

    fileprivate var currentLoadedCardImageURL: String?
    fileprivate var isSmallWidth: Bool {
        let width = superview?.frame.width ?? 0
        return  width <= 320
    }

    // MARK: - Accessors
    var loggedInActionVisibility: ReaderActionsVisibility = .visible(enabled: true)

    @objc open var headerBlogButtonIsEnabled: Bool {
        get {
            return headerBlogButton.isEnabled
        }
        set {
            if headerBlogButton.isEnabled != newValue {
                headerBlogButton.isEnabled = newValue
                if newValue {
                    blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelTextColor()
                } else {
                    blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelDisabledTextColor()
                }
            }
        }
    }

    fileprivate lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImageView)
    }()

    fileprivate lazy var readerCardTitleAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()

    fileprivate lazy var readerCardSummaryAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()

    fileprivate lazy var readerCardReadingTimeAttributes: [NSAttributedString.Key: Any] = {
        return WPStyleGuide.readerCardReadingTimeAttributes()
    }()

    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()

        // This view only exists to help IB with filling in the bottom space of
        // the cell that is later autosized according to the content's intrinsicContentSize.
        // Otherwise, IB will make incorrect size adjustments and/or complain along the way.
        // This is because most of our subviews actually need to match the exact height of
        // their instrinsicContentSize.
        // Set the helper to hidden on awake so that it is not included or calculated in the layout.
        // Note: Ideally IB would let us have a "Remove at build time" option for views, BUT IT DONT.
        // Brent C. Aug/25/2016
        interfaceVerticalSizingHelperView.isHidden = true

        setupMenuButton()

        // Buttons must be set up before applying styles,
        // as this tints the images used in the buttons
        applyStyles()

        applyOpaqueBackgroundColors()

        configureFeaturedImageView()
        setupSummaryLabel()
        setupAttributionView()
        adjustInsetsForTextDirection()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureFeaturedImageIfNeeded()
        configureButtonTitles()

        // Update colors
        applyStyles()
        setupMenuButton()
        configureFeaturedImageView()
        configureAvatarImageView()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
    }


    // MARK: - Configuration

    fileprivate func setupAttributionView() {
        attributionView.delegate = self
    }

    fileprivate func setupSummaryLabel() {
        summaryLabel.numberOfLines = Constants.summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .byTruncatingTail
    }

    fileprivate func setupMenuButton() {
        guard let icon = UIImage(named: "icon-menu-vertical-ellipsis") else {
            return
        }

        let tintColor = UIColor(light: .muriel(color: .gray, .shade50),
                                dark: .textSubtle)

        let highlightColor = UIColor(light: .muriel(color: .gray, .shade10),
                                     dark: .textQuaternary)

        let tintedIcon = icon.imageWithTintColor(tintColor)
        let highlightIcon = icon.imageWithTintColor(highlightColor)

        menuButton.setImage(tintedIcon, for: .normal)
        menuButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func adjustInsetsForTextDirection() {
        let buttonsToAdjust: [UIButton] = [
            likeActionButton,
            commentActionButton,
            saveForLaterButton,
            reblogActionButton]
        for button in buttonsToAdjust {
            button.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    /**
        Applies the default styles to the cell's subviews
    */
    fileprivate func applyStyles() {
        backgroundColor = .clear
        contentView.backgroundColor = .listBackground
        borderedView.backgroundColor = .listForeground

        WPStyleGuide.applyReaderCardBlogNameStyle(blogNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(blogHostNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineSeparatorLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)

        // Action Buttons
        WPStyleGuide.applyReaderCardSaveForLaterButtonStyle(saveForLaterButton)
        WPStyleGuide.applyReaderCardReblogActionButtonStyle(reblogActionButton)
        WPStyleGuide.applyReaderCardLikeButtonStyle(likeActionButton)
        WPStyleGuide.applyReaderCardCommentButtonStyle(commentActionButton)
    }

    /**
        Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
    */
    fileprivate func applyOpaqueBackgroundColors() {
        blogNameLabel.backgroundColor = .listForeground
        blogHostNameLabel.backgroundColor = .listForeground
        bylineLabel.backgroundColor = .listForeground
        titleLabel.backgroundColor = .listForeground
        summaryLabel.backgroundColor = .listForeground
        commentActionButton.titleLabel?.backgroundColor = .listForeground
        likeActionButton.titleLabel?.backgroundColor = .listForeground
    }

    @objc open func configureCell(_ contentProvider: ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureHeader()
        configureAvatarImageView()
        configureFeaturedImageIfNeeded()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureActionButtons()
        configureButtonTitles()
        prepareForVoiceOver()
    }

    fileprivate func configureHeader() {
        guard let contentProvider = contentProvider else {
            return
        }

        // Always reset
        avatarImageView.image = nil

        let size = avatarImageView.frame.size.width * UIScreen.main.scale
        if let url = contentProvider.siteIconForDisplay(ofSize: Int(size)) {

            let mediaRequestAuthenticator = MediaRequestAuthenticator()
            let host = MediaHost(with: contentProvider, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                CrashLogging.logError(error)
            })

            mediaRequestAuthenticator.authenticatedRequest(
                for: url,
                from: host,
                onComplete: { request in
                    self.avatarImageView.downloadImage(usingRequest: request)
                    self.avatarImageView.isHidden = false
            },
                onFailure: { error in
                    CrashLogging.logError(error)
                    self.avatarImageView.isHidden = true
            })
        } else {
            avatarImageView.isHidden = true
        }

        blogNameLabel.text = contentProvider.blogNameForDisplay() ?? ""
        blogHostNameLabel.text = contentProvider.siteHostNameForDisplay() ?? ""

        let dateString: String = datePublished()
        bylineSeparatorLabel.isHidden = dateString.isEmpty
        bylineLabel.text = dateString
    }

    fileprivate func configureAvatarImageView() {
        avatarImageView.layer.borderColor = WPStyleGuide.readerCardBlogIconBorderColor().cgColor
        avatarImageView.layer.borderWidth = Constants.imageBorderWidth
        avatarImageView.layer.masksToBounds = true
    }

    private func configureFeaturedImageView() {
        // Round the corners, and add a border
        featuredImageView.layer.cornerRadius = Constants.featuredMediaCornerRadius
        featuredImageView.layer.borderColor = WPStyleGuide.readerCardFeaturedMediaBorderColor().cgColor
        featuredImageView.layer.borderWidth = Constants.imageBorderWidth
    }

    fileprivate func configureFeaturedImageIfNeeded() {
        guard let content = contentProvider else {
            return
        }
        guard let featuredImageURL = content.featuredImageURLForDisplay?() else {
            imageLoader.prepareForReuse()
            currentLoadedCardImageURL = nil
            featuredImageView.isHidden = true

            contentStackView.setCustomSpacing(Constants.headerBottomSpacing, after: headerStackView)
            return
        }

        contentStackView.setCustomSpacing(Constants.headerBottomSpacing + Constants.featuredMediaTopSpacing, after: headerStackView)

        featuredImageView.layoutIfNeeded()
        if (!featuredImageURL.isGif && featuredImageView.image == nil) ||
            (featuredImageURL.isGif && featuredImageView.animationImages == nil) ||
            featuredImageDesiredWidth != featuredImageView.frame.size.width ||
            featuredImageURL.absoluteString != currentLoadedCardImageURL {
            configureFeaturedImage(featuredImageURL)
        }
    }

    fileprivate func configureFeaturedImage(_ featuredImageURL: URL) {
        guard let contentProvider = contentProvider else {
            return
        }

        featuredImageView.isHidden = false
        currentLoadedCardImageURL = featuredImageURL.absoluteString
        featuredImageDesiredWidth = featuredImageView.frame.width

        let featuredImageHeight = featuredImageView.frame.height

        let size = CGSize(width: featuredImageDesiredWidth, height: featuredImageHeight)
        let host = MediaHost(with: contentProvider, failure: { error in
            // We'll log the error, so we know it's there, but we won't halt execution.
            CrashLogging.logError(error)
        })
        imageLoader.loadImage(with: featuredImageURL, from: host, preferredSize: size)
    }

    fileprivate func configureTitle() {
        if let title = contentProvider?.titleForDisplay(), !title.isEmpty() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: readerCardTitleAttributes)
            titleLabel.isHidden = false
        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }

    fileprivate func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay(), !summary.isEmpty() {
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: readerCardSummaryAttributes)
            summaryLabel.isHidden = false
        } else {
            summaryLabel.attributedText = nil
            summaryLabel.isHidden = true
        }
    }

    fileprivate func configureAttribution() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.none {
            attributionView.configureView(nil)
            attributionView.isHidden = true
        } else {
            attributionView.configureView(contentProvider)
            attributionView.isHidden = false
        }
    }

    fileprivate func configureActionButtons() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() != SourceAttributionStyle.none {
            resetActionButton(commentActionButton)
            resetActionButton(likeActionButton)
            resetActionButton(saveForLaterButton)
            resetActionButton(reblogActionButton)
            return
        }

        configureSaveForLaterButton()
        configureCommentActionButton()
        configureLikeActionButton()
        configureReblogActionButton()

        configureActionButtonsInsets()
    }

    fileprivate func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControl.State())
        button.isSelected = false
        button.isEnabled = false
    }

    private func configureActionButtonsInsets() {
        actionButtons.forEach { button in
            if isSmallWidth {
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
            } else {
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            }
            button.setNeedsLayout()
        }
    }

    fileprivate func configureLikeActionButton() {
        // Show likes if logged in, or if likes exist, but not if external
        guard shouldShowLikeActionButton else {
            resetActionButton(likeActionButton)
            return
        }

        likeActionButton.tag = CardAction.like.rawValue
        likeActionButton.isEnabled = loggedInActionVisibility.isEnabled
        likeActionButton.isSelected = contentProvider!.isLiked()
    }

    fileprivate var shouldShowLikeActionButton: Bool {
        guard loggedInActionVisibility != .hidden else {
            return false
        }

        guard let contentProvider = contentProvider else {
            return false
        }

        let hasLikes = contentProvider.likeCount().intValue > 0

        guard loggedInActionVisibility.isEnabled || hasLikes else {
            return false
        }

        return !contentProvider.isExternal()
    }

    fileprivate func configureCommentActionButton() {
        guard shouldShowCommentActionButton else {
            resetActionButton(commentActionButton)
            return
        }

        commentActionButton.tag = CardAction.comment.rawValue
        commentActionButton.isEnabled = true
    }

    fileprivate var shouldShowCommentActionButton: Bool {
        guard loggedInActionVisibility != .hidden else {
            return false
        }

        guard let contentProvider = contentProvider else {
            return false
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom or jetpack (external is not yet supported).
        let usesWPComAPI = contentProvider.isWPCom() || contentProvider.isJetpack()

        let commentCount = contentProvider.commentCount()?.intValue ?? 0
        let hasComments = commentCount > 0

        return usesWPComAPI && (contentProvider.commentsOpen() || hasComments)
    }


    fileprivate func configureSaveForLaterButton() {
        saveForLaterButton.isEnabled = true
        let postIsSavedForLater = contentProvider?.isSavedForLater() ?? false
        saveForLaterButton.isSelected = postIsSavedForLater
    }

    fileprivate func configureReblogActionButton() {
        reblogActionButton.tag = CardAction.reblog.rawValue
        reblogActionButton.isEnabled = shouldShowReblogActionButton
    }

    fileprivate var shouldShowReblogActionButton: Bool {
        // reblog button is hidden if there's no content
        guard let provider = contentProvider,
            !provider.isPrivate(),
            loggedInActionVisibility.isEnabled else {
            return false
        }
        return true
    }

    fileprivate func configureButtonTitles() {
        guard let provider = contentProvider else {
            return
        }

        let likeCount = provider.likeCount()?.intValue ?? 0
        let commentCount = provider.commentCount()?.intValue ?? 0

        if self.traitCollection.horizontalSizeClass == .compact {
            // remove title text
            let likeTitle = likeCount > 0 ?  String(likeCount) : ""
            let commentTitle = commentCount > 0 ? String(commentCount) : ""
            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)
            WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton, showTitle: false)
            WPStyleGuide.applyReaderReblogActionButtonTitle(reblogActionButton, showTitle: false)

        } else {
            let likeTitle = WPStyleGuide.likeCountForDisplay(likeCount)
            let commentTitle = WPStyleGuide.commentCountForDisplay(commentCount)

            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)

            WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton)
            WPStyleGuide.applyReaderReblogActionButtonTitle(reblogActionButton)
        }


    }

    // MARK: -

    @objc func notifyDelegateHeaderWasTapped() {
        if headerBlogButtonIsEnabled {
            delegate?.readerCell(self, headerActionForProvider: contentProvider!)
        }
    }


    // MARK: - Actions

    @IBAction func didTapHeaderBlogButton(_ sender: UIButton) {
        notifyDelegateHeaderWasTapped()
    }

    @IBAction func didTapMenuButton(_ sender: UIButton) {
        delegate?.readerCell(self, menuActionForProvider: contentProvider!, fromView: sender)
    }

    @IBAction func didTapSaveForLaterButton(_ sender: UIButton) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, saveActionForProvider: provider)
        configureSaveForLaterButton()
    }

    @IBAction func didTapActionButton(_ sender: UIButton) {
        guard let contentProvider = self.contentProvider,
            let tag = CardAction(rawValue: sender.tag) else {
            return
        }

        switch tag {
        case .comment:
            delegate?.readerCell(self, commentActionForProvider: contentProvider)
        case .like:
            delegate?.readerCell(self, likeActionForProvider: contentProvider)
        case .reblog:
            delegate?.readerCell(self, reblogActionForProvider: contentProvider)
        }
    }


    // MARK: - Custom UI Actions

    @IBAction func blogButtonTouchesDidHighlight(_ sender: UIButton) {
        blogNameLabel.isHighlighted = true
    }

    @IBAction func blogButtonTouchesDidEnd(_ sender: UIButton) {
        blogNameLabel.isHighlighted = false
    }


    // MARK: - Private Types

    fileprivate enum CardAction: Int {
        case comment = 1
        case like
        case reblog
    }
}

extension ReaderPostCardCell: ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        delegate?.readerCell(self, attributionActionForProvider: contentProvider!)
    }
}

extension ReaderPostCardCell: Accessible {
    func prepareForVoiceOver() {
        prepareCardForVoiceOver()
        prepareHeaderButtonForVoiceOver()
        prepareSaveForLaterForVoiceOver()
        prepareCommentsForVoiceOver()
        prepareLikeForVoiceOver()
        prepareMenuForVoiceOver()
        prepareReblogForVoiceOver()
    }

    private func prepareCardForVoiceOver() {
        accessibilityLabel = cardAccessibilityLabel()
        accessibilityHint = cardAccessibilityHint()
        accessibilityTraits = UIAccessibilityTraits.button
    }

    private func cardAccessibilityLabel() -> String {
        let authorName = postAuthor()
        let blogTitle = blogName()

        return headerButtonAccessibilityLabel(name: authorName, title: blogTitle) + ", " + postTitle() + ", " + postContent()
    }

    private func cardAccessibilityHint() -> String {
        return NSLocalizedString("Shows the post content", comment: "Accessibility hint for the Reader Cell")
    }

    private func prepareHeaderButtonForVoiceOver() {
        guard headerBlogButtonIsEnabled else {
            /// When the headerbutton is disabled, hide it from VoiceOver as well.
            headerBlogButton.isAccessibilityElement = false
            return
        }

        headerBlogButton.isAccessibilityElement = true

        let authorName = postAuthor()
        let blogTitle = blogName()

        headerBlogButton.accessibilityLabel = headerButtonAccessibilityLabel(name: authorName, title: blogTitle)
        headerBlogButton.accessibilityHint = headerButtonAccessibilityHint(title: blogTitle)
        headerBlogButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func headerButtonAccessibilityLabel(name: String, title: String) -> String {
        return authorNameAndBlogTitle(name: name, title: title) + ", " + datePublished()
    }

    private func authorNameAndBlogTitle(name: String, title: String) -> String {
        let format = NSLocalizedString("Post by %@, from %@", comment: "Spoken accessibility label for blog author and name in Reader cell.")

        return String(format: format, name, title)
    }

    private func headerButtonAccessibilityHint(title: String) -> String {
        let format = NSLocalizedString("Shows all posts from %@", comment: "Spoken accessibility hint for blog name in Reader cell.")
        return String(format: format, title)
    }

    private func prepareSaveForLaterForVoiceOver() {
        let isSavedForLater = contentProvider?.isSavedForLater() ?? false
        saveForLaterButton.accessibilityLabel = isSavedForLater ? NSLocalizedString("Saved Post", comment: "Accessibility label for the 'Save Post' button when a post has been saved.") : NSLocalizedString("Save post", comment: "Accessibility label for the 'Save Post' button.")
        saveForLaterButton.accessibilityHint = isSavedForLater ? NSLocalizedString("Remove this post from my saved posts.", comment: "Accessibility hint for the 'Save Post' button when a post is already saved.") : NSLocalizedString("Saves this post for later.", comment: "Accessibility hint for the 'Save Post' button.")
        saveForLaterButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func prepareCommentsForVoiceOver() {
        commentActionButton.accessibilityLabel = commentsLabel()
        commentActionButton.accessibilityHint = NSLocalizedString("Shows comments", comment: "Spoken accessibility hint for Comments buttons")
        commentActionButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func commentsLabel() -> String {
        let commentCount = contentProvider?.commentCount()?.intValue ?? 0

        let format = commentCount > 1 ? pluralCommentFormat() : singularCommentFormat()

        return String(format: format, "\(commentCount)")
    }

    private func singularCommentFormat() -> String {
        return NSLocalizedString("%@ comment", comment: "Accessibility label for comments button (singular)")
    }

    private func pluralCommentFormat() -> String {
        return NSLocalizedString("%@ comments", comment: "Accessibility label for comments button (plural)")
    }

    private func prepareLikeForVoiceOver() {
        guard likeActionButton.isEnabled == true else {
            return
        }

        likeActionButton.accessibilityLabel = likeLabel()
        likeActionButton.accessibilityHint = likeHint()
        likeActionButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func likeLabel() -> String {
        return isContentLiked() ? isLikedLabel(): isNotLikedLabel()
    }

    private func isContentLiked() -> Bool {
        return contentProvider?.isLiked() ?? false
    }

    private func isLikedLabel() -> String {
        let postInMyLikes = NSLocalizedString("This post is in My Likes", comment: "Post is in my likes. Accessibility label")

        return appendLikedCount(label: postInMyLikes)
    }

    private func isNotLikedLabel() -> String {
        let postNotInMyLikes = NSLocalizedString("This post is not in My Likes", comment: "Post is not in my likes. Accessibility label")

        return appendLikedCount(label: postNotInMyLikes)
    }

    private func appendLikedCount(label: String) -> String {
        if let likeCount = contentProvider?.likeCountForDisplay() {
            return label + ", " + likeCount
        } else {
            return label
        }
    }

    private func likeHint() -> String {
        return isContentLiked() ? doubleTapToUnlike() : doubleTapToLike()
    }

    private func doubleTapToUnlike() -> String {
        return NSLocalizedString("Removes this post from My Likes", comment: "Removes a post from My Likes. Spoken Hint.")
    }

    private func doubleTapToLike() -> String {
        return NSLocalizedString("Adds this post to My Likes", comment: "Adds a post to My Likes. Spoken Hint.")
    }

    private func prepareMenuForVoiceOver() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button on Reader Cell")
        menuButton.accessibilityHint = NSLocalizedString("Shows more actions", comment: "Accessibility label for the More button on Reader Cell.")
        menuButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func prepareReblogForVoiceOver() {
        reblogActionButton.accessibilityLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
        reblogActionButton.accessibilityHint = NSLocalizedString("Reblog this post", comment: "Accessibility hint for the reblog button.")
        reblogActionButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    private func followLabel() -> String {
        return followButtonIsSelected() ? followingLabel() : notFollowingLabel()
    }

    private func followingLabel() -> String {
        return NSLocalizedString("Following", comment: "Accessibility label for following buttons.")
    }

    private func notFollowingLabel() -> String {
        return NSLocalizedString("Not following", comment: "Accessibility label for unselected following buttons.")
    }

    private func followHint() -> String {
        return followButtonIsSelected() ? unfollow(): follow()
    }

    private func unfollow() -> String {
        return NSLocalizedString("Unfollows blog", comment: "Spoken hint describing action for selected following buttons.")
    }

    private func follow() -> String {
        return NSLocalizedString("Follows blog", comment: "Spoken hint describing action for unselected following buttons.")
    }

    private func followButtonIsSelected() -> Bool {
        return contentProvider?.isFollowing() ?? false
    }

    private func blogName() -> String {
        return contentProvider?.blogNameForDisplay() ?? ""
    }

    private func postAuthor() -> String {
        return contentProvider?.authorForDisplay() ?? ""
    }

    private func postTitle() -> String {
        return contentProvider?.titleForDisplay() ?? ""
    }

    private func postContent() -> String {
        return contentProvider?.contentPreviewForDisplay() ?? ""
    }

    private func datePublished() -> String {
        return contentProvider?.dateForDisplay()?.mediumString() ?? ""
    }
}


/// Extension providing getters to some private outlets, for testability
extension ReaderPostCardCell {

    func getHeaderButtonForTesting() -> UIButton {
        return headerBlogButton
    }

    func getSaveForLaterButtonForTesting() -> UIButton {
        return saveForLaterButton
    }

    func getCommentsButtonForTesting() -> UIButton {
        return commentActionButton
    }

    func getLikeButtonForTesting() -> UIButton {
        return likeActionButton
    }

    func getMenuButtonForTesting() -> UIButton {
        return menuButton
    }

    func getReblogButtonForTesting() -> UIButton {
        return reblogActionButton
    }
}
