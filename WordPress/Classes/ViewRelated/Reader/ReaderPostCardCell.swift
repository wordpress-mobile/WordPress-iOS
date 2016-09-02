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

@objc public class ReaderPostCardCell: UITableViewCell, ReaderCardDiscoverAttributionViewDelegate
{
    // MARK: - Properties

    // Wrapper views
    @IBOutlet private weak var cardContentView: UIView!
    @IBOutlet private weak var cardBorderView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    // Header realated Views
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var headerBlogButton: UIButton!
    @IBOutlet private weak var blogNameLabel: UILabel!
    @IBOutlet private weak var bylineLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    // Card views
    @IBOutlet private weak var featuredMediaView: UIView!
    @IBOutlet private weak var featuredImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var wordCountLabel: UILabel!
    @IBOutlet private weak var attributionView: ReaderCardDiscoverAttributionView!
    @IBOutlet private weak var actionView: UIView!

    // Helper Views
    @IBOutlet private weak var interfaceVerticalSizingHelperView: UIView!

    // Action buttons
    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!

    // Layout Constraints
    @IBOutlet private weak var featuredMediaHeightConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private var featuredMediaHeightConstraintConstant = WPDeviceIdentification.isiPad() ? CGFloat(226.0) : CGFloat(196.0)

    private let summaryMaxNumberOfLines = 3
    private let avgWordsPerMinuteRead = 250
    private let minimumMinutesToRead = 2
    private var currentLoadedCardImageURL: String?

    // MARK: - Accessors

    public var enableLoggedInFeatures: Bool = true

    public override var backgroundColor: UIColor? {
        didSet{
            contentView.backgroundColor = backgroundColor
        }
    }

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
            headerBlogButton.enabled = newValue
            if newValue {
                blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelTextColor()
            } else {
                blogNameLabel.textColor = WPStyleGuide.readerCardBlogNameLabelDisabledTextColor()
            }
        }
    }


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
        createAvatarTapGestureRecognizer()
        setupAttributionView()

        // Layout the stackView if needed since layout may be a bit different than
        // what was expected from the nib layout.
        stackView.layoutIfNeeded()
    }

    /**
        Ignore taps in the card margins
    */
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if (!CGRectContainsPoint(cardContentView.frame, point)) {
            return nil
        }
        return super.hitTest(point, withEvent: event)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        applyHighlightedEffect(false, animated: false)
    }


    // MARK: - Configuration

    private func setupAttributionView() {
        attributionView.delegate = self
    }

    private func createAvatarTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: #selector(ReaderPostCardCell.didTapHeaderAvatar(_:)))
        avatarImageView.addGestureRecognizer(tgr)
    }


    /**
        Applies the default styles to the cell's subviews
    */
    private func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        cardBorderView.backgroundColor = WPStyleGuide.readerCardCellBorderColor()

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
        avatarImageView.backgroundColor = UIColor.whiteColor()
        blogNameLabel.backgroundColor = UIColor.whiteColor()
        bylineLabel.backgroundColor = UIColor.whiteColor()
        titleLabel.backgroundColor = UIColor.whiteColor()
        summaryLabel.backgroundColor = UIColor.whiteColor()
        tagButton.titleLabel?.backgroundColor = UIColor.whiteColor()
        wordCountLabel.backgroundColor = UIColor.whiteColor()
        actionButtonLeft.titleLabel?.backgroundColor = UIColor.whiteColor()
        actionButtonRight.titleLabel?.backgroundColor = UIColor.whiteColor()
    }

    public func configureCell(contentProvider:ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureHeader()
        configureCardImage()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureTag()
        configureWordCount()
        configureActionButtons()
        configureActionViewHeightIfNeeded()
    }

    private func configureHeader() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: "post-blavatar-placeholder")

        let size = avatarImageView.frame.size.width * UIScreen.mainScreen().scale
        let url = contentProvider?.siteIconForDisplayOfSize(Int(size))
        if url != nil {
            avatarImageView.setImageWithURL(url!, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }

        let blogName = contentProvider?.blogNameForDisplay()
        blogNameLabel.text = blogName

        var byline = contentProvider?.dateForDisplay()?.shortString() ?? ""
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline)
        }

        bylineLabel.text = byline
    }

    private func configureCardImage() {
        if let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() {

            featuredMediaView.hidden = false
            featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant

            if featuredImageURL.absoluteString == currentLoadedCardImageURL && featuredImageView.image != nil {
                return // Don't reload an image already being displayed.
            }

            // Always clear the previous image so there is no stale or unexpected image
            // momentarily visible.
            featuredImageView.image = nil
            var url = featuredImageURL
            let desiredWidth = UIApplication.sharedApplication().keyWindow?.frame.size.width ?? self.featuredMediaView.frame.width
            let size = CGSize(width:desiredWidth, height:featuredMediaHeightConstraintConstant)
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

        } else {
            featuredImageView.image = nil
            currentLoadedCardImageURL = nil
            featuredMediaView.hidden = true
        }
    }

    private func requestForURL(url:NSURL) -> NSURLRequest {
        var requestURL = url

        let absoluteString = requestURL.absoluteString
        if !(absoluteString.hasPrefix("https")) {
            let sslURL = absoluteString.stringByReplacingOccurrencesOfString("http", withString: "https")
            requestURL = NSURL(string: sslURL)!
        }

        let request = NSMutableURLRequest(URL: requestURL)

        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = acctServ.defaultWordPressComAccount() {
            let token = account.authToken
            let headerValue = String(format: "Bearer %@", token)
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func configureTitle() {
        if let title = contentProvider?.titleForDisplay() {
            let attributes = WPStyleGuide.readerCardTitleAttributes() as! [String: AnyObject]
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
            titleLabel.hidden = false
        } else {
            titleLabel.attributedText = nil
            titleLabel.hidden = true
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() {
            let attributes = WPStyleGuide.readerCardSummaryAttributes() as! [String: AnyObject]
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: attributes)
            summaryLabel.hidden = false
        } else {
            summaryLabel.attributedText = nil
            summaryLabel.hidden = true
        }

        summaryLabel.numberOfLines = summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .ByTruncatingTail
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
        tagButton.hidden = tag.characters.count == 0
        tagButton.setTitle(tag, forState: .Normal)
        tagButton.setTitle(tag, forState: .Highlighted)
    }

    private func configureWordCount() {
        // Always reset the attributed string.
        wordCountLabel.attributedText = nil

        // For now, if showing the attribution view do not show the word count label
        if !attributionView.hidden {
            wordCountLabel.hidden = true
            return
        }

        if contentProvider!.wordCount() != nil {
            let wordCount = contentProvider!.wordCount().integerValue
            let readingTime = contentProvider!.readingTime().integerValue
            wordCountLabel.attributedText = attributedTextForWordCount(wordCount, readingTime:readingTime)
        }

        if wordCountLabel.attributedText == nil {
            wordCountLabel.hidden = true
        } else {
            wordCountLabel.hidden = false
        }
    }

    private func attributedTextForWordCount(wordCount:Int, readingTime:Int) -> NSAttributedString? {
        let attrStr = NSMutableAttributedString()

        // Compose the word count.
        let wordsStr = NSLocalizedString("words",
                                        comment: "Part of a label letting the user know how any words are in a post. For example: '300 words'")

        let countStr = String(format: "%d %@ ", wordCount, wordsStr)
        var attributes = WPStyleGuide.readerCardWordCountAttributes() as! [String: AnyObject]
        let attrWordCount = NSAttributedString(string: countStr, attributes: attributes)
        attrStr.appendAttributedString(attrWordCount)

        // Append the reading time if needed.
        if readingTime == 0 {
            return attrStr
        }

        let format = NSLocalizedString("(~ %d min)",
                                        comment:"A short label that tells the user the estimated reading time of an article. '%d' is a placeholder for the number of minutes. '~' denotes an estimation.")
        let str = String(format: format, readingTime)
        attributes = WPStyleGuide.readerCardReadingTimeAttributes() as! [String: AnyObject]
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

    private func configureActionViewHeightIfNeeded() {
        if actionButtonLeft.hidden && actionButtonRight.hidden && tagButton.hidden {
            actionView.hidden = true
        } else {
            actionView.hidden = false
        }
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        let duration:NSTimeInterval = animated ? 0.25 : 0

        UIView.animateWithDuration(duration,
            delay: 0,
            options: .CurveEaseInOut,
            animations: {
                self.cardBorderView.backgroundColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor() : WPStyleGuide.readerCardCellBorderColor()
        }, completion: nil)
    }


    // MARK: -

    func notifyDelegateHeaderWasTapped() {
        if headerBlogButtonIsEnabled {
            delegate?.readerCell(self, headerActionForProvider: contentProvider!)
        }
    }


    // MARK: - Actions

    func didTapHeaderAvatar(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            notifyDelegateHeaderWasTapped()
        }
    }

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


    // MARK: - ReaderCardDiscoverAttributionView Delegate Methods

    public func attributionActionSelectedForVisitingSite(view: ReaderCardDiscoverAttributionView) {
        delegate?.readerCell(self, attributionActionForProvider: contentProvider!)
    }


    // MARK: - Private Types

    private enum CardAction: Int
    {
        case Comment = 1
        case Like
    }
}
