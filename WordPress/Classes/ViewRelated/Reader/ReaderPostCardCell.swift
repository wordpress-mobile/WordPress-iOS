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
    @IBOutlet fileprivate weak var featuredImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var summaryLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet fileprivate weak var actionStackView: UIStackView!

    // Helper Views
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons
    @IBOutlet fileprivate weak var shareButton: UIButton!
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

    // MARK: - Accessors
    @objc open var hidesFollowButton = false
    @objc open var enableLoggedInFeatures = true


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

    fileprivate lazy var readerCardTitleAttributes: [NSAttributedStringKey: Any] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()

    fileprivate lazy var readerCardSummaryAttributes: [NSAttributedStringKey: Any] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()

    fileprivate lazy var readerCardReadingTimeAttributes: [NSAttributedStringKey: Any] = {
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

        applyStyles()
        applyOpaqueBackgroundColors()
        setupFeaturedImageView()
        setupVisitButton()
        setupShareButton()
        setupMenuButton()
        setupSummaryLabel()
        setupAttributionView()
        setupCommentActionButton()
        setupLikeActionButton()
        adjustInsetsForTextDirection()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureFeaturedImageIfNeeded()
        configureButtonTitles()
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
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        commentActionButton.setImage(image, for: UIControlState())
        commentActionButton.setImage(highlightImage, for: .highlighted)
    }

    fileprivate func setupLikeActionButton() {
        let image = UIImage(named: "icon-reader-like")
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selectedImage = UIImage(named: "icon-reader-liked")
        likeActionButton.setImage(image, for: UIControlState())
        likeActionButton.setImage(highlightImage, for: .highlighted)
        likeActionButton.setImage(selectedImage, for: .selected)
    }

    fileprivate func setupVisitButton() {
        let size = CGSize(width: 20, height: 20)
        let title = NSLocalizedString("Visit", comment: "Verb. Button title.  Tap to visit a website.")
        let icon = Gridicon.iconOfType(.external, withSize: size)
        let tintedIcon = icon.imageWithTintColor(WPStyleGuide.greyLighten10())
        let highlightIcon = icon.imageWithTintColor(WPStyleGuide.lightBlue())

        visitButton.setTitle(title, for: UIControlState())
        visitButton.setImage(tintedIcon, for: .normal)
        visitButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func setupShareButton() {
        let size = CGSize(width: 20, height: 20)
        let icon = Gridicon.iconOfType(.share, withSize: size)
        let tintedIcon = icon.imageWithTintColor(WPStyleGuide.greyLighten10())
        let highlightIcon = icon.imageWithTintColor(WPStyleGuide.lightBlue())

        shareButton.setImage(tintedIcon, for: .normal)
        shareButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func setupMenuButton() {
        let size = CGSize(width: 20, height: 20)
        let icon = Gridicon.iconOfType(.ellipsis, withSize: size)
        let tintedIcon = icon.imageWithTintColor(WPStyleGuide.greyLighten10())
        let highlightIcon = icon.imageWithTintColor(WPStyleGuide.lightBlue())

        menuButton.setImage(tintedIcon, for: .normal)
        menuButton.setImage(highlightIcon, for: .highlighted)
    }

    fileprivate func adjustInsetsForTextDirection() {
        let buttonsToAdjust: [UIButton] = [
            visitButton,
            likeActionButton,
            commentActionButton,
            shareButton]
        for button in buttonsToAdjust {
            button.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    /**
        Applies the default styles to the cell's subviews
    */
    fileprivate func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0

        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        WPStyleGuide.applyReaderCardBlogNameStyle(blogNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentActionButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeActionButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(visitButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(shareButton)
    }


    /**
        Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
    */
    fileprivate func applyOpaqueBackgroundColors() {
        blogNameLabel.backgroundColor = UIColor.white
        bylineLabel.backgroundColor = UIColor.white
        titleLabel.backgroundColor = UIColor.white
        summaryLabel.backgroundColor = UIColor.white
        commentActionButton.titleLabel?.backgroundColor = UIColor.white
        likeActionButton.titleLabel?.backgroundColor = UIColor.white
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
            avatarImageView.setImageWith(url)
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
            featuredImageView.image = nil
            currentLoadedCardImageURL = nil
            featuredImageView.isHidden = true
            return
        }

        featuredImageView.layoutIfNeeded()
        if featuredImageView.image == nil || featuredImageDesiredWidth != featuredImageView.frame.size.width || featuredImageURL.absoluteString != currentLoadedCardImageURL {
            configureFeaturedImage(featuredImageURL)
        }
    }

    fileprivate func configureFeaturedImage(_ featuredImageURL: URL) {
        featuredImageView.isHidden = false

        // Always clear the previous image so there is no stale or unexpected image
        // momentarily visible.
        featuredImageView.image = nil
        var url = featuredImageURL
        featuredImageDesiredWidth = featuredImageView.frame.width
        let size = CGSize(width: featuredImageDesiredWidth, height: featuredMediaHeightConstraintConstant)
        if !(contentProvider!.isPrivate()) {
            url = PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
            featuredImageView.setImageWith(url, placeholderImage: nil)

        } else if (url.host != nil) && url.host!.hasSuffix("wordpress.com") {
            // private wpcom image needs special handling.
            let scale = UIScreen.main.scale
            let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
            url = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
            let request = requestForURL(url)
            featuredImageView.setImageWith(request, placeholderImage: nil, success: nil, failure: nil)

        } else {
            // private but not a wpcom hosted image
            featuredImageView.setImageWith(url, placeholderImage: nil)
        }
        currentLoadedCardImageURL = featuredImageURL.absoluteString
    }

    fileprivate func requestForURL(_ url: URL) -> URLRequest {

        var requestURL = url

        let absoluteString = requestURL.absoluteString
        if !absoluteString.hasPrefix("https") {
            let sslURL = absoluteString.replacingOccurrences(of: "http", with: "https")
            requestURL = URL(string: sslURL)!
        }

        let request = NSMutableURLRequest(url: requestURL)
        guard let token = delegate?.readerCellImageRequestAuthToken(self) else {
            return request as URLRequest
        }
        let headerValue = String(format: "Bearer %@", token)
        request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        return request as URLRequest
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
            return
        }

        configureCommentActionButton()
        configureLikeActionButton()
    }

    fileprivate func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControlState())
        button.isSelected = false
        button.isHidden = true
    }

    fileprivate func configureLikeActionButton() {
        // Show likes if logged in, or if likes exist, but not if external
        guard (enableLoggedInFeatures || contentProvider!.likeCount().intValue > 0) && !contentProvider!.isExternal() else {
            resetActionButton(likeActionButton)
            return
        }

        likeActionButton.tag = CardAction.like.rawValue
        likeActionButton.isEnabled = enableLoggedInFeatures
        likeActionButton.isSelected = contentProvider!.isLiked()
        likeActionButton.isHidden = false
    }

    fileprivate func configureCommentActionButton() {

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom or jetpack (external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if contentProvider!.isWPCom() || contentProvider!.isJetpack() {
            let commentCount = contentProvider!.commentCount()?.intValue ?? 0
            if (enableLoggedInFeatures && contentProvider!.commentsOpen()) || commentCount > 0 {

                commentActionButton.tag = CardAction.comment.rawValue
                commentActionButton.isHidden = false

                return
            }
        }
        resetActionButton(commentActionButton)
    }

    fileprivate func configureButtonTitles() {
        guard let provider = contentProvider else {
            return
        }

        let likeCount = provider.likeCount()?.intValue ?? 0
        let commentCount = provider.commentCount()?.intValue ?? 0

        if superview?.frame.width < 480 {
            // remove title text
            let likeTitle = likeCount > 0 ?  String(likeCount) : ""
            let commentTitle = commentCount > 0 ? String(commentCount) : ""
            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)
            shareButton.setTitle("", for: .normal)
            followButton.setTitle("", for: .normal)
            followButton.setTitle("", for: .selected)
            followButton.setTitle("", for: .highlighted)

            insetFollowButtonIcon(false)
        } else {
            // show title text

            let likeTitle = WPStyleGuide.likeCountForDisplay(likeCount)
            let commentTitle = WPStyleGuide.commentCountForDisplay(commentCount)
            let shareTitle = NSLocalizedString("Share", comment: "Verb. Button title.  Tap to share a post.")
            let followTitle = WPStyleGuide.followStringForDisplay(false)
            let followingTitle = WPStyleGuide.followStringForDisplay(true)

            likeActionButton.setTitle(likeTitle, for: .normal)
            commentActionButton.setTitle(commentTitle, for: .normal)
            shareButton.setTitle(shareTitle, for: .normal)

            followButton.setTitle(followTitle, for: .normal)
            followButton.setTitle(followingTitle, for: .selected)
            followButton.setTitle(followingTitle, for: .highlighted)

            insetFollowButtonIcon(true)
        }
    }

    /// Adds some space between the button and title.
    /// Setting the titleEdgeInset.left seems to be ignored in IB for whatever reason,
    /// so we'll add/remove it from the image as needed.
    fileprivate func insetFollowButtonIcon(_ bool: Bool) {
        var insets = followButton.imageEdgeInsets
        insets.right = bool ? 2.0 : 0.0
        followButton.imageEdgeInsets = insets
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
            options: UIViewAnimationOptions(),
            animations: updateBorder,
            completion: nil)
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

    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let provider = contentProvider else {
            return
        }
        delegate?.readerCell(self, shareActionForProvider: provider, fromView: sender)
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
        prepareShareForVoiceOver()
        prepareCommentsForVoiceOver()
        prepareLikeForVoiceOver()
        prepareMenuForVoiceOver()
        prepareVisitForVoiceOver()
    }

    private func prepareCardForVoiceOver() {
        accessibilityLabel = cardAccessibilityLabel()
        accessibilityHint = "Shows the post content"
    }

    private func cardAccessibilityLabel() -> String {
        let authorName = postAuthor()
        let blogTitle = blogName()

        return headerButtonAccessibilityLabel(name: authorName, title: blogTitle) + "." + postTitle() + "." + postContent()
    }

    private func prepareHeaderButtonForVoiceOver() {
        let authorName = postAuthor()
        let blogTitle = blogName()

        headerBlogButton.accessibilityLabel = headerButtonAccessibilityLabel(name: authorName, title: blogTitle)
        headerBlogButton.accessibilityHint = headerButtonAccessibilityHint(title: blogTitle)
        headerBlogButton.accessibilityTraits = UIAccessibilityTraitButton
    }

    private func headerButtonAccessibilityLabel(name: String, title: String) -> String {
        return authorNameAndBlogTitle(name: name, title: title) + "," + datePublished()
    }

    private func authorNameAndBlogTitle(name: String, title: String) -> String {
        let format = NSLocalizedString("Post by %@, from %@", comment: "Spoken accessibility label for blog author and name in Reader cell.")

        return String(format: format, name, title)
    }

    private func headerButtonAccessibilityHint(title: String) -> String {
        let format = NSLocalizedString("Shows all posts from %@", comment: "Spoken accessibility hint for blog name in Reader cell.")
        return String(format: format, title)
    }

    private func prepareShareForVoiceOver() {
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Spoken accessibility label")
        shareButton.accessibilityHint = NSLocalizedString("Shares this post", comment: "Spoken accessibility hint for Share buttons")
        shareButton.accessibilityTraits = UIAccessibilityTraitButton
    }

    private func prepareCommentsForVoiceOver() {
        commentActionButton.accessibilityLabel = commentsLabel()
        commentActionButton.accessibilityHint = NSLocalizedString("Shows comments", comment: "Spoken accessibility hint for Comments buttons")
        commentActionButton.accessibilityTraits = UIAccessibilityTraitButton
    }

    private func commentsLabel() -> String {
        let commentCount = contentProvider?.commentCount()?.intValue ?? 0

        let format = commentCount > 1 ? pluralCommentFormat() : singularCommentFormat()

        return String(format: format, "\(commentCount)")
    }

    private func singularCommentFormat() -> String {
        return NSLocalizedString("%@ comment", comment: "Accesibility label for comments button (singular)")
    }

    private func pluralCommentFormat() -> String {
        return NSLocalizedString("%@ comments", comment: "Accesibility label for comments button (plural)")
    }

    private func prepareLikeForVoiceOver() {
        guard likeActionButton.isHidden == false else {
            return
        }

        likeActionButton.accessibilityLabel = likeLabel()
        likeActionButton.accessibilityHint = likeHint()
        likeActionButton.accessibilityTraits = UIAccessibilityTraitButton
    }

    private func likeLabel() -> String {
        return isContentLiked() ? isLikedLabel(): isNotLikedLabel()
    }

    private func isContentLiked() -> Bool {
        return contentProvider?.isLiked() ?? false
    }

    private func isLikedLabel() -> String {
        guard let likeCount = contentProvider?.likeCountForDisplay() else {
            return NSLocalizedString("Liked", comment: "Accessibility label for active Like Buttons")
        }

        return likeCount
    }

    private func isNotLikedLabel() -> String {
        return NSLocalizedString("Like", comment: "Accessibility label for inactive Like Buttons")
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
        menuButton.accessibilityTraits = UIAccessibilityTraitButton
    }

    private func prepareVisitForVoiceOver() {
        visitButton.accessibilityLabel = NSLocalizedString("Visit", comment: "Verb. Button title. Accessibility label in Reader")
        let hintFormat = NSLocalizedString("Visit %@ in a web view", comment: "A call to action to visit the specified blog via a web view. Accessibility hint in Reader")
        visitButton.accessibilityHint = String(format: hintFormat, blogName())
        visitButton.accessibilityTraits = UIAccessibilityTraitButton
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

    func getShareButtonForTesting() -> UIButton {
        return shareButton
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
