import Foundation
import WordPressShared

@objc public protocol ReaderPostCellDelegate: NSObjectProtocol
{
    func readerCell(cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, tagActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
    func readerCell(cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider)
    func readerCellImageRequestAuthToken(cell: ReaderPostCardCell) -> String?
}

@objc public class ReaderPostCardCell: UITableViewCell
{
    // MARK: - Properties

    // Wrapper views
    @IBOutlet private weak var contentStackView: UIStackView!

    // Header realated Views
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var headerBlogButton: UIButton!
    @IBOutlet private weak var blogNameLabel: UILabel!
    @IBOutlet private weak var bylineLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    // Card views
    @IBOutlet private weak var featuredImageView: UIImageView!
    @IBOutlet private weak var titleLabel: ReaderPostCardContentLabel!
    @IBOutlet private weak var summaryLabel: ReaderPostCardContentLabel!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet private weak var actionStackView: UIStackView!

    // Helper Views
    @IBOutlet private weak var borderedView: UIView!
    @IBOutlet private weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons
    @IBOutlet private weak var likeActionButton: UIButton!
    @IBOutlet private weak var commentActionButton: UIButton!

    // Layout Constraints
    @IBOutlet private weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private let featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(196.0)
    private var featuredImageDesiredWidth = CGFloat()

    private let summaryMaxNumberOfLines = 3
    private let avgWordsPerMinuteRead = 250
    private let minimumMinutesToRead = 2
    private var currentLoadedCardImageURL: String?

    // MARK: - Accessors

    public var enableLoggedInFeatures = true


    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = self.highlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted == highlighted {
            return
        }
        applyHighlightedEffect(highlighted, animated: animated)
    }

    public var headerBlogButtonIsEnabled: Bool {
        get {
            return headerBlogButton.enabled
        }
        set {
            if headerBlogButton.enabled != newValue {
                headerBlogButton.enabled = newValue
                if newValue {
                    blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelTextColor()
                } else {
                    blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelDisabledTextColor()
                }
            }
        }
    }

    private lazy var readerCardTitleAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()

    private lazy var readerCardSummaryAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()

    private lazy var readerCardReadingTimeAttributes: [String: AnyObject] = {
        return WPStyleGuide.readerCardReadingTimeAttributes()
    }()

    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        // This view only exists to help IB with filling in the bottom space of
        // the cell that is later autosized according to the content's intrinsicContentSize.
        // Otherwise, IB will make incorrect size adjustments and/or complain along the way.
        // This is because most of our subviews actually need to match the exact height of
        // their instrinsicContentSize.
        // Set the helper to hidden on awake so that it is not included or calculated in the layout.
        // Note: Ideally IB would let us have a "Remove at build time" option for views, BUT IT DONT.
        // Brent C. Aug/25/2016
        interfaceVerticalSizingHelperView.hidden = true

        applyStyles()
        applyOpaqueBackgroundColors()
        setupFeaturedImageView()
        setupSummaryLabel()
        setupAttributionView()
        setupCommentActionButton()
        setupLikeActionButton()
    }

    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureFeaturedImageIfNeeded()
    }


    // MARK: - Configuration

    private func setupAttributionView() {
        attributionView.delegate = self
    }

    private func setupFeaturedImageView() {
        featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant
    }

    private func setupSummaryLabel() {
        summaryLabel.numberOfLines = summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .ByTruncatingTail
    }

    private func setupCommentActionButton() {
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        commentActionButton.setImage(image, forState: .Normal)
        commentActionButton.setImage(highlightImage, forState: .Highlighted)
    }

    private func setupLikeActionButton() {
        let image = UIImage(named: "icon-reader-like")
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selectedImage = UIImage(named: "icon-reader-liked")
        likeActionButton.setImage(image, forState: .Normal)
        likeActionButton.setImage(highlightImage, forState: .Highlighted)
        likeActionButton.setImage(selectedImage, forState: .Selected)
    }

    /**
        Applies the default styles to the cell's subviews
    */
    private func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().CGColor
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
    private func applyOpaqueBackgroundColors() {
        blogNameLabel.backgroundColor = UIColor.whiteColor()
        bylineLabel.backgroundColor = UIColor.whiteColor()
        titleLabel.backgroundColor = UIColor.whiteColor()
        summaryLabel.backgroundColor = UIColor.whiteColor()
        tagButton.titleLabel?.backgroundColor = UIColor.whiteColor()
        commentActionButton.titleLabel?.backgroundColor = UIColor.whiteColor()
        likeActionButton.titleLabel?.backgroundColor = UIColor.whiteColor()
    }

    public func configureCell(contentProvider:ReaderPostContentProvider) {
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

    private func configureHeader() {
        // Always reset
        avatarImageView.image = UIImage(named: "post-blavatar-placeholder")

        let size = avatarImageView.frame.size.width * UIScreen.mainScreen().scale
        if let url = contentProvider?.siteIconForDisplayOfSize(Int(size)) {
            avatarImageView.setImageWithURL(url)
        }

        blogNameLabel.text = contentProvider?.blogNameForDisplay()

        var byline = contentProvider?.dateForDisplay()?.shortString() ?? ""
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline)
        }

        bylineLabel.text = byline
    }

    private func configureFeaturedImageIfNeeded() {
        guard let content = contentProvider else {
            return
        }
        guard let featuredImageURL = content.featuredImageURLForDisplay?() else {
            featuredImageView.image = nil
            currentLoadedCardImageURL = nil
            featuredImageView.hidden = true
            return
        }

        featuredImageView.layoutIfNeeded()
        if featuredImageView.image == nil || featuredImageDesiredWidth != featuredImageView.frame.size.width || featuredImageURL.absoluteString != currentLoadedCardImageURL {
            configureFeaturedImage(featuredImageURL)
        }
    }

    private func configureFeaturedImage(featuredImageURL: NSURL) {
        featuredImageView.hidden = false

        // Always clear the previous image so there is no stale or unexpected image
        // momentarily visible.
        featuredImageView.image = nil
        var url = featuredImageURL
        featuredImageDesiredWidth = featuredImageView.frame.width
        let size = CGSize(width:featuredImageDesiredWidth, height:featuredMediaHeightConstraintConstant)
        if !(contentProvider!.isPrivate()) {
            url = PhotonImageURLHelper.photonURLWithSize(size, forImageURL: url)
            featuredImageView.setImageWithURL(url, placeholderImage:nil)

        } else if (url.host != nil) && url.host!.hasSuffix("wordpress.com") {
            // private wpcom image needs special handling.
            let scale = UIScreen.mainScreen().scale
            let scaledSize = CGSize(width:size.width * scale, height: size.height * scale)
            url = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
            let request = requestForURL(url)
            featuredImageView.setImageWithURLRequest(request, placeholderImage: nil, success: nil, failure: nil)

        } else {
            // private but not a wpcom hosted image
            featuredImageView.setImageWithURL(url, placeholderImage:nil)
        }
        currentLoadedCardImageURL = featuredImageURL.absoluteString
    }

    private func requestForURL(url:NSURL) -> NSURLRequest {

        var requestURL = url

        let absoluteString = requestURL.absoluteString ?? ""
        if !absoluteString.hasPrefix("https") {
            let sslURL = absoluteString.stringByReplacingOccurrencesOfString("http", withString: "https")
            requestURL = NSURL(string: sslURL)!
        }

        let request = NSMutableURLRequest(URL: requestURL)
        guard let token = delegate?.readerCellImageRequestAuthToken(self) else {
            return request
        }
        let headerValue = String(format: "Bearer %@", token)
        request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        return request
    }

    private func configureTitle() {
        if let title = contentProvider?.titleForDisplay() where !title.isEmpty() {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: readerCardTitleAttributes)
            titleLabel.hidden = false
        } else {
            titleLabel.attributedText = nil
            titleLabel.hidden = true
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() where !summary.isEmpty() {
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: readerCardSummaryAttributes)
            summaryLabel.hidden = false
        } else {
            summaryLabel.attributedText = nil
            summaryLabel.hidden = true
        }
    }

    private func configureAttribution() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.None {
            attributionView.configureView(nil)
            attributionView.hidden = true
        } else {
            attributionView.configureView(contentProvider)
            attributionView.hidden = false
        }
    }

    private func configureTag() {
        var tag = ""
        if let rawTag = contentProvider?.primaryTag() {
            if (rawTag.characters.count > 0) {
                tag = "#\(rawTag)"
            }
        }
        let hidden = tag.characters.count == 0
        tagButton.hidden = hidden
        tagButton.setTitle(tag, forState: .Normal)
        tagButton.setTitle(tag, forState: .Highlighted)
    }

    private func configureActionButtons() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() != SourceAttributionStyle.None {
            resetActionButton(commentActionButton)
            resetActionButton(likeActionButton)
            return
        }

        configureCommentActionButton()
        configureLikeActionButton()
    }

    private func resetActionButton(button:UIButton) {
        button.setTitle(nil, forState: .Normal)
        button.selected = false
        button.hidden = true
    }

    private func configureLikeActionButton() {
        // Show likes if logged in, or if likes exist, but not if external
        guard (enableLoggedInFeatures || contentProvider!.likeCount().integerValue > 0) && !contentProvider!.isExternal() else {
            resetActionButton(likeActionButton)
            return
        }

        likeActionButton.tag = CardAction.Like.rawValue
        likeActionButton.enabled = enableLoggedInFeatures

        let title = contentProvider!.likeCountForDisplay()
        likeActionButton.setTitle(title, forState: .Normal)
        likeActionButton.selected = contentProvider!.isLiked()
        likeActionButton.hidden = false
    }

    private func configureCommentActionButton() {

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if contentProvider!.isWPCom() {
            if (enableLoggedInFeatures && contentProvider!.commentsOpen()) || contentProvider!.commentCount().integerValue > 0 {

                commentActionButton.tag = CardAction.Comment.rawValue

                let title = contentProvider?.commentCount().stringValue
                commentActionButton.setTitle(title, forState: .Normal)
                commentActionButton.hidden = false

                return
            }
        }
        resetActionButton(commentActionButton)
    }

    private func configureActionStackViewIfNeeded() {
        let actionsHidden = commentActionButton.hidden && likeActionButton.hidden && tagButton.hidden
        actionStackView.hidden = actionsHidden
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        func updateBorder() {
            self.borderedView.layer.borderColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor().CGColor : WPStyleGuide.readerCardCellBorderColor().CGColor
        }
        guard animated else {
            updateBorder()
            return
        }
        UIView.animateWithDuration(0.25,
            delay: 0,
            options: .CurveEaseInOut,
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

    @IBAction func didTapHeaderBlogButton(sender: UIButton) {
        notifyDelegateHeaderWasTapped()
    }

    @IBAction func didTapMenuButton(sender: UIButton) {
        delegate?.readerCell(self, menuActionForProvider: contentProvider!, fromView: sender)
    }

    @IBAction func didTapTagButton(sender: UIButton) {
        if contentProvider == nil {
            return
        }
        delegate?.readerCell(self, tagActionForProvider: contentProvider!)
    }

    @IBAction func didTapActionButton(sender: UIButton) {
        if contentProvider == nil {
            return
        }

        let tag = CardAction(rawValue: sender.tag)!
        switch tag {
        case .Comment :
            delegate?.readerCell(self, commentActionForProvider: contentProvider!)
        case .Like :
            delegate?.readerCell(self, likeActionForProvider: contentProvider!)
        }
    }


    // MARK: - Custom UI Actions

    @IBAction func blogButtonTouchesDidHighlight(sender: UIButton) {
        blogNameLabel.highlighted = true
    }

    @IBAction func blogButtonTouchesDidEnd(sender: UIButton) {
        blogNameLabel.highlighted = false
    }


    // MARK: - Private Types

    private enum CardAction: Int
    {
        case Comment = 1
        case Like
    }
}

extension ReaderPostCardCell : ReaderCardDiscoverAttributionViewDelegate
{
    public func attributionActionSelectedForVisitingSite(view: ReaderCardDiscoverAttributionView) {
        delegate?.readerCell(self, attributionActionForProvider: contentProvider!)
    }
}
