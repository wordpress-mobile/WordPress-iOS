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
    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!

    // Layout Constraints
    @IBOutlet private weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private var featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(196.0)
    private var featuredImageDesiredWidth = CGFloat()

    private let summaryMaxNumberOfLines = 3
    private let avgWordsPerMinuteRead = 250
    private let minimumMinutesToRead = 2
    private var currentLoadedCardImageURL: String?

    // Image Loading
    private var imageHeaderAuthorization: String?

    // MARK: - Accessors

    public var enableLoggedInFeatures: Bool = true


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

    private lazy var readerCardTitleAttributes: [NSObject: AnyObject] = {
        return WPStyleGuide.readerCardTitleAttributes()
    }()

    private lazy var readerCardSummaryAttributes: [NSObject: AnyObject] = {
        return WPStyleGuide.readerCardSummaryAttributes()
    }()

    private lazy var readerCardWordCountAttributes: [NSObject: AnyObject] = {
        return WPStyleGuide.readerCardWordCountAttributes()
    }()

    private lazy var readerCardReadingTimeAttributes: [NSObject: AnyObject] = {
        return WPStyleGuide.readerCardReadingTimeAttributes()
    }()

    // MARK: - Lifecycle Methods

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(defaultAccountDidChange(_:)), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)

        refreshImageHeaderAuthorization()

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
        setupAttributionView()

        // Layout the contentStackView if needed since layout may be a bit different than
        // what was expected from the nib layout.
        contentStackView.layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        configureFeaturedImageIfNeeded()
    }


    // MARK: - Configuration

    private func setupAttributionView() {
        attributionView.delegate = self
    }

    private func setupSummaryLabel() {
        summaryLabel.numberOfLines = summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .ByTruncatingTail
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
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonRight)
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
        actionButtonLeft.titleLabel?.backgroundColor = UIColor.whiteColor()
        actionButtonRight.titleLabel?.backgroundColor = UIColor.whiteColor()
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
        let placeholder = UIImage(named: "post-blavatar-placeholder")
        avatarImageView.image = placeholder

        let size = avatarImageView.frame.size.width * UIScreen.mainScreen().scale
        if let url = contentProvider?.siteIconForDisplayOfSize(Int(size)) {
            avatarImageView.setImageWithURL(url)
        }

        let blogName = contentProvider?.blogNameForDisplay()
        blogNameLabel.text = blogName

        var byline = contentProvider?.dateForDisplay()?.shortString() ?? ""
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline)
        }

        bylineLabel.text = byline
    }

    private func configureFeaturedImageIfNeeded() {

        guard let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() else {
            featuredImageView.image = nil
            currentLoadedCardImageURL = nil
            if !featuredImageView.hidden {
                featuredImageView.hidden = true
            }
            return
        }
        if featuredImageView.image == nil || featuredImageDesiredWidth != featuredImageView.frame.size.width || featuredImageURL.absoluteString != currentLoadedCardImageURL {

            configureFeaturedImage(featuredImageURL)
        }
    }

    private func configureFeaturedImage(featuredImageURL: NSURL) {
        if featuredImageView.hidden {
            featuredImageView.hidden = false
        }
        if featuredMediaHeightConstraint.constant != featuredMediaHeightConstraintConstant {
            featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant
        }

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

    private func refreshImageHeaderAuthorization() {
        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = acctServ.defaultWordPressComAccount() {
            let token = account.authToken
            let headerValue = String(format: "Bearer %@", token)
            imageHeaderAuthorization = headerValue
        } else {
            imageHeaderAuthorization = nil
        }
    }

    private func requestForURL(url:NSURL) -> NSURLRequest {

        var requestURL = url

        let absoluteString = requestURL.absoluteString ?? ""
        if !absoluteString.hasPrefix("https") {
            let sslURL = absoluteString.stringByReplacingOccurrencesOfString("http", withString: "https")
            requestURL = NSURL(string: sslURL)!
        }

        let request = NSMutableURLRequest(URL: requestURL)
        guard let headerAuth = imageHeaderAuthorization else {
            return request
        }
        request.addValue(headerAuth, forHTTPHeaderField: "Authorization")
        return request
    }

    private func configureTitle() {
        if let title = contentProvider?.titleForDisplay() {
            let attributes = readerCardTitleAttributes as! [String: AnyObject]
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
            if titleLabel.hidden {
                titleLabel.hidden = false
            }
        } else {
            titleLabel.attributedText = nil
            if !titleLabel.hidden {
                titleLabel.hidden = true
            }
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() {
            let attributes = readerCardSummaryAttributes as! [String: AnyObject]
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: attributes)
            if summaryLabel.hidden {
                summaryLabel.hidden = false
            }
        } else {
            summaryLabel.attributedText = nil
            if !summaryLabel.hidden {
                summaryLabel.hidden = true
            }
        }
    }

    private func configureAttribution() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.None {
            attributionView.configureView(nil)
            if !attributionView.hidden {
                attributionView.hidden = true
            }
        } else {
            attributionView.configureView(contentProvider)
            if attributionView.hidden {
                attributionView.hidden = false
            }
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
        if tagButton.hidden != hidden {
            tagButton.hidden = hidden
        }
        tagButton.setTitle(tag, forState: .Normal)
        tagButton.setTitle(tag, forState: .Highlighted)
    }

    private func attributedTextForWordCount(wordCount:Int, readingTime:Int) -> NSAttributedString? {
        let attrStr = NSMutableAttributedString()

        // Compose the word count.
        let wordsStr = NSLocalizedString("words",
                                        comment: "Part of a label letting the user know how any words are in a post. For example: '300 words'")

        let countStr = String(format: "%d %@ ", wordCount, wordsStr)
        var attributes = readerCardWordCountAttributes as! [String: AnyObject]
        let attrWordCount = NSAttributedString(string: countStr, attributes: attributes)
        attrStr.appendAttributedString(attrWordCount)

        // Append the reading time if needed.
        if readingTime == 0 {
            return attrStr
        }

        let format = NSLocalizedString("(~ %d min)",
                                        comment:"A short label that tells the user the estimated reading time of an article. '%d' is a placeholder for the number of minutes. '~' denotes an estimation.")
        let str = String(format: format, readingTime)
        attributes = readerCardReadingTimeAttributes as! [String: AnyObject]
        let attrReadingTime = NSAttributedString(string: str, attributes: attributes)
        attrStr.appendAttributedString(attrReadingTime)

        return attrStr
    }

    private func configureActionButtons() {
        var buttons = [
            actionButtonLeft,
            actionButtonRight
        ]

        if contentProvider == nil || contentProvider?.sourceAttributionStyle() != SourceAttributionStyle.None {
            resetActionButtons(buttons)
            return
        }

        // Show likes if logged in, or if likes exist, but not if external
        if (enableLoggedInFeatures || contentProvider!.likeCount().integerValue > 0) && !contentProvider!.isExternal() {
            let button = buttons.removeLast() as UIButton
            configureLikeActionButton(button)
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if contentProvider!.isWPCom() {
            if (enableLoggedInFeatures && contentProvider!.commentsOpen()) || contentProvider!.commentCount().integerValue > 0 {
                let button = buttons.removeLast() as UIButton
                configureCommentActionButton(button)
            }
        }

        resetActionButtons(buttons)
    }

    private func resetActionButtons(buttons:[UIButton!]) {
        for button in buttons {
            resetActionButton(button)
        }
    }

    private func resetActionButton(button:UIButton) {
        button.setTitle(nil, forState: .Normal)
        button.setTitle(nil, forState: .Highlighted)
        button.setTitle(nil, forState: .Disabled)
        button.setImage(nil, forState: .Normal)
        button.setImage(nil, forState: .Highlighted)
        button.setImage(nil, forState: .Disabled)
        button.selected = false
        button.hidden = true
        button.enabled = true
    }

    private func configureActionButton(button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?, selected:Bool) {
        button.setTitle(title, forState: .Normal)
        button.setTitle(title, forState: .Highlighted)
        button.setTitle(title, forState: .Disabled)
        button.setImage(image, forState: .Normal)
        button.setImage(highlightedImage, forState: .Highlighted)
        button.setImage(image, forState: .Disabled)
        button.selected = selected
        button.hidden = false
    }

    private func configureLikeActionButton(button: UIButton) {
        button.tag = CardAction.Like.rawValue
        button.enabled = enableLoggedInFeatures

        let title = contentProvider!.likeCountForDisplay()
        let imageName = contentProvider!.isLiked() ? "icon-reader-liked" : "icon-reader-like"
        let image = UIImage(named: imageName)
        let highlightImage = UIImage(named: "icon-reader-like-highlight")
        let selected = contentProvider!.isLiked()
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage, selected:selected)
    }

    private func configureCommentActionButton(button: UIButton) {
        button.tag = CardAction.Comment.rawValue
        let title = contentProvider?.commentCount().stringValue
        let image = UIImage(named: "icon-reader-comment")
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage, selected:false)
    }

    private func configureActionStackViewIfNeeded() {
        let actionsHidden = actionButtonLeft.hidden && actionButtonRight.hidden && tagButton.hidden
        if actionStackView.hidden != actionsHidden {
            actionStackView.hidden = actionsHidden
        }
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        func updateBorder() {
            self.borderedView.layer.borderColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor().CGColor : WPStyleGuide.readerCardCellBorderColor().CGColor
        }
        guard animated else {
            updateBorder()
            return
        }
        let duration:NSTimeInterval = animated ? 0.25 : 0
        UIView.animateWithDuration(duration,
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


    // MARK: - Notifications

    @objc private func defaultAccountDidChange(notification: NSNotification) {
        refreshImageHeaderAuthorization()
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
