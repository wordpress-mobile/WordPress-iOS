import Foundation
import WordPressShared
import Gridicons
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


@objc public protocol ReaderPostCellDelegate: NSObjectProtocol {
    func readerCell(_ cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, followActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, shareActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(_ cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider)
    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String?
}

@objc open class ReaderPostCardCell: UITableViewCell {
    // MARK: - Properties

    // Wrapper views
    @IBOutlet fileprivate weak var contentStackView: UIStackView!

    // Header realated Views
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var headerBlogButton: UIButton!
    @IBOutlet fileprivate weak var blogNameLabel: UILabel!
    @IBOutlet fileprivate weak var bylineLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: UIButton!

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
    @IBOutlet fileprivate weak var visitButton: UIButton!
    @IBOutlet fileprivate weak var likeActionButton: UIButton!
    @IBOutlet fileprivate weak var commentActionButton: UIButton!
    @IBOutlet fileprivate weak var menuButton: UIButton!

    // Layout Constraints
    @IBOutlet fileprivate weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    @objc open weak var delegate: ReaderPostCellDelegate?
    @objc open weak var contentProvider: ReaderPostContentProvider?

    fileprivate let featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(100.0)
    fileprivate var featuredImageDesiredWidth = CGFloat()

    fileprivate let summaryMaxNumberOfLines = 3
    fileprivate let avgWordsPerMinuteRead = 250
    fileprivate let minimumMinutesToRead = 2
    fileprivate var currentLoadedCardImageURL: String?
    fileprivate var isSmallWidth: Bool {
        let width = superview?.frame.width ?? 0
        return  width <= 320
    }
    fileprivate var isMediumWidth: Bool {
        return superview?.frame.width < 480
    }
    fileprivate var isBigWidth: Bool {
        return !isMediumWidth
    }

    // MARK: - Accessors
    @objc open var hidesFollowButton = false
    var loggedInActionVisibility: ReaderActionsVisibility = .visible(enabled: true)


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
        setupVisitButton()
        setupSaveForLaterButton()
        setupCommentActionButton()
        setupLikeActionButton()

        // Buttons must be set up before applying styles,
        // as this tints the images used in the buttons
        applyStyles()

        applyOpaqueBackgroundColors()
        setupFeaturedImageView()

        setupSummaryLabel()
        setupAttributionView()
        adjustInsetsForTextDirection()
        insetFollowButtonIcon()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureFeaturedImageIfNeeded()
        configureButtonTitles()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
    }


    // MARK: - Configuration

    fileprivate func setupAttributionView() {
        attributionView.delegate = self
    }

    fileprivate func setupFeaturedImageView() {
        featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant
    }

    fileprivate func setupSummaryLabel() {
        summaryLabel.numberOfLines = summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .byTruncatingTail
    }

    fileprivate func setupCommentActionButton() {
        let image = UIImage(named: "icon-reader-comment")?.imageFlippedForRightToLeftLayoutDirection()
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")?.imageFlippedForRightToLeftLayoutDirection()
        commentActionButton.setImage(image, for: UIControl.State())
        commentActionButton.setImage(highlightImage, for: .highlighted)
    }

    fileprivate func setupLikeActionButton() {
        let likeImage = UIImage(named: "icon-reader-like")
        let likedImage = UIImage(named: "icon-reader-liked")

        likeActionButton.setImage(likeImage, for: .normal)
        likeActionButton.setImage(likedImage, for: .highlighted)
        likeActionButton.setImage(likedImage, for: .selected)
        likeActionButton.setImage(likedImage, for: [.highlighted, .selected])
    }

    fileprivate func setupVisitButton() {
        let size = CGSize(width: 20, height: 20)
        let title = NSLocalizedString("Visit", comment: "Verb. Button title.  Tap to visit a website.")
        let icon = Gridicon.iconOfType(.external, withSize: size)
        let tintedIcon = icon.imageFlippedForRightToLeftLayoutDirection()
        let highlightIcon = icon.imageFlippedForRightToLeftLayoutDirection()

        visitButton.setTitle(title, for: UIControl.State())
        visitButton.setImage(tintedIcon, for: .normal)
        visitButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func setupSaveForLaterButton() {
        WPStyleGuide.applyReaderSaveForLaterButtonStyle(saveForLaterButton)
    }

    fileprivate func setupMenuButton() {
        let size = CGSize(width: 20, height: 20)
        let icon = Gridicon.iconOfType(.ellipsis, withSize: size)
        let tintedIcon = icon.imageWithTintColor(.neutral(.shade30))
        let highlightIcon = icon.imageWithTintColor(.neutral)

        menuButton.setImage(tintedIcon, for: .normal)
        menuButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func adjustInsetsForTextDirection() {
        let buttonsToAdjust: [UIButton] = [
            visitButton,
            likeActionButton,
            commentActionButton,
            saveForLaterButton]
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
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth

        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        WPStyleGuide.applyReaderCardBlogNameStyle(blogNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderActionButtonStyle(commentActionButton)
        WPStyleGuide.applyReaderActionButtonStyle(likeActionButton)
        WPStyleGuide.applyReaderActionButtonStyle(visitButton)
    }


    /**
        Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
    */
    fileprivate func applyOpaqueBackgroundColors() {
        blogNameLabel.backgroundColor = .listForeground
        bylineLabel.backgroundColor = .listForeground
        titleLabel.backgroundColor = .listForeground
        summaryLabel.backgroundColor = .listForeground
        commentActionButton.titleLabel?.backgroundColor = .listForeground
        likeActionButton.titleLabel?.backgroundColor = .listForeground
    }

    @objc open func configureCell(_ contentProvider: ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureHeader()
        configureFollowButton()
        configureFeaturedImageIfNeeded()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureActionButtons()
        configureButtonTitles()
        prepareForVoiceOver()
    }

    fileprivate func configureHeader() {
        guard let provider = contentProvider else {
            return
        }

        // Always reset
        avatarImageView.image = nil

        let size = avatarImageView.frame.size.width * UIScreen.main.scale
        if let url = provider.siteIconForDisplay(ofSize: Int(size)) {
            if provider.isPrivate() {
                let request = PrivateSiteURLProtocol.requestForPrivateSite(from: url)
                avatarImageView.downloadImage(usingRequest: request)
            } else {
                avatarImageView.downloadImage(from: url)
            }
            avatarImageView.isHidden = false

        } else {
            avatarImageView.isHidden = true
        }

        var arr = [String]()
        if let authorName = provider.authorForDisplay() {
            arr.append(authorName)
        }
        if let blogName = provider.blogNameForDisplay() {
            arr.append(blogName)
        }
        blogNameLabel.text = arr.joined(separator: ", ")

        let byline = datePublished()
        bylineLabel.text = byline
    }

    fileprivate func configureFollowButton() {
        followButton.isHidden = hidesFollowButton
        followButton.isSelected = contentProvider?.isFollowing() ?? false
    }

    fileprivate func configureFeaturedImageIfNeeded() {
        guard let content = contentProvider else {
            return
        }
        guard let featuredImageURL = content.featuredImageURLForDisplay?() else {
            imageLoader.prepareForReuse()
            currentLoadedCardImageURL = nil
            featuredImageView.isHidden = true
            return
        }

        featuredImageView.layoutIfNeeded()
        if (!featuredImageURL.isGif && featuredImageView.image == nil) ||
            (featuredImageURL.isGif && featuredImageView.animationImages == nil) ||
            featuredImageDesiredWidth != featuredImageView.frame.size.width ||
            featuredImageURL.absoluteString != currentLoadedCardImageURL {
            configureFeaturedImage(featuredImageURL)
        }
    }

    fileprivate func configureFeaturedImage(_ featuredImageURL: URL) {
        guard let content = contentProvider else {
            return
        }

        featuredImageView.isHidden = false
        currentLoadedCardImageURL = featuredImageURL.absoluteString
        featuredImageDesiredWidth = featuredImageView.frame.width
        let size = CGSize(width: featuredImageDesiredWidth, height: featuredMediaHeightConstraintConstant)
        let postInfo = ReaderCardContent(provider: content)
        imageLoader.loadImage(with: featuredImageURL, from: postInfo, preferredSize: size)
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
            return
        }

        configureCommentActionButton()
        configureLikeActionButton()
        configureActionButtonsInsets()

        configureSaveForLaterButton()
    }

    fileprivate func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControl.State())
        button.isSelected = false
        button.isHidden = true
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
        likeActionButton.isHidden = false
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
        commentActionButton.isHidden = false
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
        saveForLaterButton.isHidden = false
        let postIsSavedForLater = contentProvider?.isSavedForLater() ?? false
        saveForLaterButton.isSelected = postIsSavedForLater
    }

    fileprivate func configureButtonTitles() {
        guard let provider = contentProvider else {
            return
        }

        let likeCount = provider.likeCount()?.intValue ?? 0
        let commentCount = provider.commentCount()?.intValue ?? 0

        if !isBigWidth {
            // remove title text
            let likeTitle = likeCount > 0 ?  String(likeCount) : ""
            let commentTitle = commentCount > 0 ? String(commentCount) : ""
            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)
            saveForLaterButton.setTitle("", for: .normal)
        } else {
            let likeTitle = WPStyleGuide.likeCountForDisplay(likeCount)
            let commentTitle = WPStyleGuide.commentCountForDisplay(commentCount)

            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)

            WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton)
        }
    }

    /// Adds some space between the button and title.
    /// Setting the titleEdgeInset.left seems to be ignored in IB for whatever reason,
    /// so we'll add/remove it from the image as needed.
    fileprivate func insetFollowButtonIcon() {
        var insets = followButton.imageEdgeInsets
        insets.right = 2.0
        followButton.imageEdgeInsets = insets
        followButton.flipInsetsForRightToLeftLayoutDirection()
    }

    fileprivate func applyHighlightedEffect(_ highlighted: Bool, animated: Bool) {
        func updateBorder() {
            self.borderedView.layer.borderColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor().cgColor : WPStyleGuide.readerCardCellBorderColor().cgColor
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


    // MARK: -

    @objc func notifyDelegateHeaderWasTapped() {
        if headerBlogButtonIsEnabled {
            delegate?.readerCell(self, headerActionForProvider: contentProvider!)
        }
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, followActionForProvider: provider)
    }

    @IBAction func didTapHeaderBlogButton(_ sender: UIButton) {
        notifyDelegateHeaderWasTapped()
    }

    @IBAction func didTapMenuButton(_ sender: UIButton) {
        delegate?.readerCell(self, menuActionForProvider: contentProvider!, fromView: sender)
    }

    @IBAction func didTapVisitButton(_ sender: UIButton) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, visitActionForProvider: provider)
    }

    @IBAction func didTapSaveForLaterButton(_ sender: UIButton) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, saveActionForProvider: provider)
        configureSaveForLaterButton()
    }

    @IBAction func didTapActionButton(_ sender: UIButton) {
        if contentProvider == nil {
            return
        }

        let tag = CardAction(rawValue: sender.tag)!
        switch tag {
        case .comment :
            delegate?.readerCell(self, commentActionForProvider: contentProvider!)
        case .like :
            delegate?.readerCell(self, likeActionForProvider: contentProvider!)
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
        prepareVisitForVoiceOver()
        prepareFollowButtonForVoiceOver()
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
        guard likeActionButton.isHidden == false else {
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

    private func prepareVisitForVoiceOver() {
        visitButton.accessibilityLabel = NSLocalizedString("Visit", comment: "Verb. Button title. Accessibility label in Reader")
        let hintFormat = NSLocalizedString("Visit %@ in a web view", comment: "A call to action to visit the specified blog via a web view. Accessibility hint in Reader")
        visitButton.accessibilityHint = String(format: hintFormat, blogName())
        visitButton.accessibilityTraits = UIAccessibilityTraits.button
    }

    func prepareFollowButtonForVoiceOver() {
        if hidesFollowButton {
            return
        }

        followButton.accessibilityLabel = followLabel()
        followButton.accessibilityHint = followHint()
        followButton.accessibilityTraits = UIAccessibilityTraits.button
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
        return (contentProvider?.dateForDisplay() as NSDate?)?.mediumString() ?? ""
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

    func getVisitButtonForTesting() -> UIButton {
        return visitButton
    }
}
