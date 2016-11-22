import Foundation
import WordPressShared

@objc public protocol ReaderPostCellDelegate: NSObjectProtocol
{
    func readerCell(_ cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, tagActionForProvider provider: ReaderPostContentProvider)
    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider)
    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String?
}

@objc open class ReaderPostCardCell: UITableViewCell
{
    // MARK: - Properties

    // Wrapper views
    @IBOutlet fileprivate weak var contentStackView: UIStackView!

    // Header realated Views
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var headerBlogButton: UIButton!
    @IBOutlet fileprivate weak var blogNameLabel: UILabel!
    @IBOutlet fileprivate weak var bylineLabel: UILabel!
    @IBOutlet fileprivate weak var menuButton: UIButton!

    // Card views
    @IBOutlet fileprivate weak var featuredImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var summaryLabel: ReaderPostCardContentLabel!
    @IBOutlet fileprivate weak var tagButton: UIButton!
    @IBOutlet fileprivate weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet fileprivate weak var actionStackView: UIStackView!

    // Helper Views
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons
    @IBOutlet fileprivate weak var likeActionButton: UIButton!
    @IBOutlet fileprivate weak var commentActionButton: UIButton!

    // Layout Constraints
    @IBOutlet fileprivate weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    open weak var delegate: ReaderPostCellDelegate?
    open weak var contentProvider: ReaderPostContentProvider?

    fileprivate let featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(196.0)
    fileprivate var featuredImageDesiredWidth = CGFloat()

    fileprivate let summaryMaxNumberOfLines = 3
    fileprivate let avgWordsPerMinuteRead = 250
    fileprivate let minimumMinutesToRead = 2
    fileprivate var currentLoadedCardImageURL: String?

    // MARK: - Accessors

    open var enableLoggedInFeatures = true


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

    open var headerBlogButtonIsEnabled: Bool {
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

    fileprivate lazy var readerCardTitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()

    fileprivate lazy var readerCardSummaryAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()

    fileprivate lazy var readerCardReadingTimeAttributes: [String: AnyObject] = {
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
        setupSummaryLabel()
        setupAttributionView()
        setupCommentActionButton()
        setupLikeActionButton()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureFeaturedImageIfNeeded()
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

    /**
        Applies the default styles to the cell's subviews
    */
    fileprivate func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0

        WPStyleGuide.applyReaderCardBlogNameStyle(blogNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(commentActionButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeActionButton)
    }


    /**
        Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
    */
    fileprivate func applyOpaqueBackgroundColors() {
        blogNameLabel.backgroundColor = UIColor.white
        bylineLabel.backgroundColor = UIColor.white
        titleLabel.backgroundColor = UIColor.white
        summaryLabel.backgroundColor = UIColor.white
        tagButton.titleLabel?.backgroundColor = UIColor.white
        commentActionButton.titleLabel?.backgroundColor = UIColor.white
        likeActionButton.titleLabel?.backgroundColor = UIColor.white
    }

    open func configureCell(_ contentProvider:ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureHeader()
        configureFeaturedImageIfNeeded()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureTag()
        configureActionButtons()
        configureActionStackViewIfNeeded()
    }

    fileprivate func configureHeader() {
        // Always reset
        avatarImageView.image = UIImage(named: "post-blavatar-placeholder")

        let size = avatarImageView.frame.size.width * UIScreen.main.scale
        if let url = contentProvider?.siteIconForDisplay(ofSize: Int(size)) {
            avatarImageView.setImageWith(url)
        }

        blogNameLabel.text = contentProvider?.blogNameForDisplay()

        var byline = (contentProvider?.dateForDisplay() as NSDate?)?.shortString() ?? ""
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline)
        }

        bylineLabel.text = byline
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
        let size = CGSize(width:featuredImageDesiredWidth, height:featuredMediaHeightConstraintConstant)
        if !(contentProvider!.isPrivate()) {
            url = PhotonImageURLHelper.photonURL(with: size, forImageURL: url)
            featuredImageView.setImageWith(url, placeholderImage:nil)

        } else if (url.host != nil) && url.host!.hasSuffix("wordpress.com") {
            // private wpcom image needs special handling.
            let scale = UIScreen.main.scale
            let scaledSize = CGSize(width:size.width * scale, height: size.height * scale)
            url = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
            let request = requestForURL(url)
            featuredImageView.setImageWith(request, placeholderImage: nil, success: nil, failure: nil)

        } else {
            // private but not a wpcom hosted image
            featuredImageView.setImageWith(url, placeholderImage:nil)
        }
        currentLoadedCardImageURL = featuredImageURL.absoluteString
    }

    fileprivate func requestForURL(_ url:URL) -> URLRequest {

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

    fileprivate func configureTag() {
        var tag = ""
        if let rawTag = contentProvider?.primaryTag() {
            if (rawTag.characters.count > 0) {
                tag = "#\(rawTag)"
            }
        }
        let hidden = tag.characters.count == 0
        tagButton.isHidden = hidden
        tagButton.setTitle(tag, for: UIControlState())
        tagButton.setTitle(tag, for: .highlighted)
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

    fileprivate func resetActionButton(_ button:UIButton) {
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

        let title = contentProvider!.likeCountForDisplay()
        likeActionButton.setTitle(title, for: UIControlState())
        likeActionButton.isSelected = contentProvider!.isLiked()
        likeActionButton.isHidden = false
    }

    fileprivate func configureCommentActionButton() {

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if contentProvider!.isWPCom() {
            if (enableLoggedInFeatures && contentProvider!.commentsOpen()) || contentProvider!.commentCount().intValue > 0 {

                commentActionButton.tag = CardAction.comment.rawValue

                let title = contentProvider?.commentCount().stringValue
                commentActionButton.setTitle(title, for: UIControlState())
                commentActionButton.isHidden = false

                return
            }
        }
        resetActionButton(commentActionButton)
    }

    fileprivate func configureActionStackViewIfNeeded() {
        let actionsHidden = commentActionButton.isHidden && likeActionButton.isHidden && tagButton.isHidden
        actionStackView.isHidden = actionsHidden
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

    func notifyDelegateHeaderWasTapped() {
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

    @IBAction func didTapTagButton(_ sender: UIButton) {
        if contentProvider == nil {
            return
        }
        delegate?.readerCell(self, tagActionForProvider: contentProvider!)
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

    fileprivate enum CardAction: Int
    {
        case comment = 1
        case like
    }
}

extension ReaderPostCardCell : ReaderCardDiscoverAttributionViewDelegate
{
    public func attributionActionSelectedForVisitingSite(_ view: ReaderCardDiscoverAttributionView) {
        delegate?.readerCell(self, attributionActionForProvider: contentProvider!)
    }
}
