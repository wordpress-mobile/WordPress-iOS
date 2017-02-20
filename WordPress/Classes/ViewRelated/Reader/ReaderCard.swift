import Foundation
import WordPressShared
import Gridicons


public protocol ReaderCardDelegate: NSObjectProtocol {
    func readerCard(_ card: ReaderCard, headerActionForPost post: ReaderPost)
    func readerCard(_ card: ReaderCard, commentActionForPost post: ReaderPost)
    func readerCard(_ card: ReaderCard, followActionForPost post: ReaderPost)
    func readerCard(_ card: ReaderCard, shareActionForPost post: ReaderPost, fromView sender: UIView)
    func readerCard(_ card: ReaderCard, visitActionForPost post: ReaderPost)
    func readerCard(_ card: ReaderCard, likeActionForPost post: ReaderPost)
    func readerCard(_ card: ReaderCard, menuActionForPost post: ReaderPost, fromView sender: UIView)
    func readerCard(_ card: ReaderCard, attributionActionForPost post: ReaderPost)
    func readerCardImageRequestAuthToken() -> String?
}


@IBDesignable
public class ReaderCard: UIView {
    // MARK: - Properties

    // Wrapper views
    @IBOutlet fileprivate weak var contentView: UIView!
    @IBOutlet fileprivate weak var cardStackView: UIStackView!

    // Header realated Views
    @IBOutlet fileprivate weak var headerImageView: UIImageView!
    @IBOutlet fileprivate weak var headerButton: UIButton!
    @IBOutlet fileprivate weak var headerAuthorLabel: UILabel!
    @IBOutlet fileprivate weak var headerDateLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: UIButton!

    // Card views
    @IBOutlet fileprivate weak var featuredImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var summaryLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet fileprivate weak var actionStackView: UIStackView!

    // Helper Views
    @IBOutlet fileprivate weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons
    @IBOutlet fileprivate weak var shareButton: UIButton!
    @IBOutlet fileprivate weak var visitButton: UIButton!
    @IBOutlet fileprivate weak var likeButton: UIButton!
    @IBOutlet fileprivate weak var commentButton: UIButton!
    @IBOutlet fileprivate weak var menuButton: UIButton!

    // Layout Constraints
    @IBOutlet fileprivate weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    fileprivate let featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(100.0)
    fileprivate var featuredImageDesiredWidth = CGFloat()

    fileprivate let summaryMaxNumberOfLines = 3
    fileprivate var currentLoadedCardImageURL: String?

    fileprivate lazy var readerCardTitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()


    fileprivate lazy var readerCardSummaryAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()


    fileprivate lazy var readerCardReadingTimeAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardReadingTimeAttributes()
    }()


    var cardContentMargins: UIEdgeInsets {
        get {
            return cardStackView.layoutMargins
        }
        set {
            cardStackView.layoutMargins = newValue
        }
    }


    // MARK: - Public Accessors

    open var hidesFollowButton = false
    open var enableLoggedInFeatures = true
    open weak var delegate: ReaderCardDelegate?

    open var readerPost: ReaderPost? {
        didSet {
            configureCard()
        }
    }


    open var headerButtonIsEnabled: Bool {
        get {
            return headerButton.isEnabled
        }
        set {
            if headerButton.isEnabled != newValue {
                headerButton.isEnabled = newValue
                if newValue {
                    headerAuthorLabel.textColor = WPStyleGuide.readerCardBlogNameLabelTextColor()
                } else {
                    headerAuthorLabel.textColor = WPStyleGuide.readerCardBlogNameLabelDisabledTextColor()
                }
            }
        }
    }


    open var hidesActionbar: Bool {
        get {
            return actionStackView.isHidden
        }
        set {
            actionStackView.isHidden = newValue
        }
    }


    // MARK: - Lifecycle Methods


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }


    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }


    func setupView() {
        // Load the xib and set up the subviews.
        Bundle.main.loadNibNamed("ReaderCard", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = bounds
        addSubview(contentView)

        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        layoutIfNeeded()

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
        setupcommentButton()
        setuplikeButton()
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


    fileprivate func setupcommentButton() {
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        commentButton.setImage(image, for: UIControlState())
        commentButton.setImage(highlightImage, for: .highlighted)
    }


    fileprivate func setuplikeButton() {
        let image = UIImage(named: "icon-reader-like")
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selectedImage = UIImage(named: "icon-reader-liked")
        likeButton.setImage(image, for: UIControlState())
        likeButton.setImage(highlightImage, for: .highlighted)
        likeButton.setImage(selectedImage, for: .selected)
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
            likeButton,
            commentButton,
            shareButton]

        for button in buttonsToAdjust {
            button.flipInsetsForRightToLeftLayoutDirection()
        }
    }


    /// Applies the default styles to subviews
    ///
    fileprivate func applyStyles() {
        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        WPStyleGuide.applyReaderCardBlogNameStyle(headerAuthorLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(headerDateLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(visitButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(shareButton)
    }


    /// Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
    ///
    fileprivate func applyOpaqueBackgroundColors() {
        headerAuthorLabel.backgroundColor = UIColor.white
        headerDateLabel.backgroundColor = UIColor.white
        titleLabel.backgroundColor = UIColor.white
        summaryLabel.backgroundColor = UIColor.white
        commentButton.titleLabel?.backgroundColor = UIColor.white
        likeButton.titleLabel?.backgroundColor = UIColor.white
    }


    fileprivate func configureCard() {
        configureHeader()
        configureFollowButton()
        configureFeaturedImageIfNeeded()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureCommentButton()
        configureLikeButton()
        configureButtonTitles()
    }


    fileprivate func configureHeader() {
        guard let post = readerPost else {
            return
        }

        // Always reset
        headerImageView.image = nil

        let size = headerImageView.frame.size.width * UIScreen.main.scale
        if let url = post.siteIconForDisplay(ofSize: Int(size)) {
            headerImageView.setImageWith(url)
            headerImageView.isHidden = false
        } else {
            headerImageView.isHidden = true
        }

        var arr = [String]()
        if let authorName = post.authorForDisplay() {
            arr.append(authorName)
        }
        if let blogName = post.blogNameForDisplay() {
            arr.append(blogName)
        }
        headerAuthorLabel.text = arr.joined(separator: ", ")

        let date = (readerPost?.dateForDisplay() as NSDate?)?.mediumString() ?? ""
        headerDateLabel.text = date
    }


    fileprivate func configureFollowButton() {
        followButton.isHidden = hidesFollowButton
        followButton.isSelected = readerPost?.isFollowing ?? false
    }


    fileprivate func configureFeaturedImageIfNeeded() {
        guard let post = readerPost else {
            return
        }
        guard let featuredImageURL = post.featuredImageURLForDisplay() else {
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
        if !(readerPost!.isPrivate()) {
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
        guard let token = delegate?.readerCardImageRequestAuthToken() else {
            return request as URLRequest
        }
        let headerValue = String(format: "Bearer %@", token)
        request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        return request as URLRequest
    }


    fileprivate func configureTitle() {
        if let title = readerPost?.titleForDisplay(), !title.isEmpty() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: readerCardTitleAttributes)
            titleLabel.isHidden = false
        } else {
            titleLabel.attributedText = nil
            titleLabel.isHidden = true
        }
    }


    fileprivate func configureSummary() {
        if let summary = readerPost?.contentPreviewForDisplay(), !summary.isEmpty() {
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: readerCardSummaryAttributes)
            summaryLabel.isHidden = false
        } else {
            summaryLabel.attributedText = nil
            summaryLabel.isHidden = true
        }
    }


    fileprivate func configureAttribution() {
        if readerPost == nil || readerPost?.sourceAttributionStyle() == SourceAttributionStyle.none {
            attributionView.configureView(nil)
            attributionView.isHidden = true
        } else {
            attributionView.configureView(readerPost)
            attributionView.isHidden = false
        }
    }


    fileprivate func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControlState())
        button.isSelected = false
        button.isHidden = true
    }


    fileprivate func configureLikeButton() {
        resetActionButton(likeButton)
        guard let post = readerPost else {
            return
        }
        // Show likes if logged in, or if likes exist, but not if external
        guard (enableLoggedInFeatures || post.likeCount.intValue > 0) && !post.isExternal else {
            return
        }

        likeButton.isEnabled = enableLoggedInFeatures
        likeButton.isSelected = post.isLiked
        likeButton.isHidden = false
    }


    fileprivate func configureCommentButton() {
        resetActionButton(commentButton)
        guard let post = readerPost else {
            return
        }
        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if post.isWPCom {
            if (enableLoggedInFeatures && post.commentsOpen) || post.commentCount.intValue > 0 {
                commentButton.isHidden = false
            }
        }
    }


    fileprivate func configureButtonTitles() {
        guard let post = readerPost else {
            return
        }

        let likeCount = post.likeCount.intValue
        let commentCount = post.commentCount.intValue

        if let width = superview?.frame.width, width < CGFloat(480.0) {
            // remove title text
            let likeTitle = likeCount > 0 ?  post.likeCount.stringValue : ""
            let commentTitle = commentCount > 0 ? post.commentCount.stringValue : ""
            likeButton.setTitle(likeTitle, for: UIControlState())
            commentButton.setTitle(commentTitle, for: UIControlState())
            shareButton.setTitle("", for: UIControlState())
            followButton.setTitle("", for: UIControlState())
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

            likeButton.setTitle(likeTitle, for: UIControlState())
            commentButton.setTitle(commentTitle, for: UIControlState())
            shareButton.setTitle(shareTitle, for: UIControlState())

            followButton.setTitle(followTitle, for: UIControlState())
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


    // MARK: - Actions


    @IBAction func didTapFollowButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, followActionForPost: post)
    }


    @IBAction func didTapHeaderBlogButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, headerActionForPost: post)
    }


    @IBAction func didTapMenuButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, menuActionForPost: post, fromView: sender)
    }


    @IBAction func didTapVisitButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, visitActionForPost: post)
    }


    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, shareActionForPost: post, fromView: sender)
    }


    @IBAction func didTapCommentButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, commentActionForPost: post)
    }


    @IBAction func didTapLikeButton(_ sender: UIButton) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, likeActionForPost: post)
    }


    // MARK: - Custom UI Actions

    @IBAction func blogButtonTouchesDidHighlight(_ sender: UIButton) {
        headerAuthorLabel.isHighlighted = true
    }


    @IBAction func blogButtonTouchesDidEnd(_ sender: UIButton) {
        headerAuthorLabel.isHighlighted = false
    }

}


extension ReaderCard : ReaderCardDiscoverAttributionViewDelegate {
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        guard let post = readerPost else {
            return
        }
        delegate?.readerCard(self, attributionActionForPost: post)
    }
}
