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

@objc public class ReaderPostCardCell: UITableViewCell, RichTextViewDelegate
{
    // MARK: - Properties

    // Wrapper views
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var cardContentView: UIView!
    @IBOutlet private weak var cardBorderView: UIView!

    // Header realated Views
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var blogNameButton: UIButton!
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

    // Action buttons
    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!

    // Layout Constraints
    @IBOutlet private weak var featuredMediaHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var featuredMediaBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var summaryLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var attributionHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var attributionBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var wordCountBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardContentBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var maxIPadWidthConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private var featuredMediaHeightConstraintConstant = UIDevice.isPad() ? CGFloat(226.0) : CGFloat(196.0)
    private var featuredMediaBottomConstraintConstant = CGFloat(0.0)
    private var titleLabelBottomConstraintConstant = CGFloat(0.0)
    private var summaryLabelBottomConstraintConstant = CGFloat(0.0)
    private var attributionBottomConstraintConstant = CGFloat(0.0)
    private var wordCountBottomConstraintConstant = CGFloat(0.0)
    private var actionButtonViewHeightConstraintConstant = CGFloat(0.0)

    private var didPreserveStartingConstraintConstants = false
    private var configureForLayoutOnly = false

    private let summaryMaxNumberOfLines = 3
    private let maxAttributionViewHeight: CGFloat = 200.0 // 200 is an arbitrary height, but should be a sufficiently high number.
    private let avgWordsPerMinuteRead = 250
    private let minimumMinutesToRead = 2
    private var currentLoadedCardImageURL: String?

    // MARK: - Accessors

    public var enableLoggedInFeatures: Bool = true

    public override var backgroundColor: UIColor? {
        didSet{
            contentView.backgroundColor = backgroundColor
            innerContentView?.backgroundColor = backgroundColor
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

    public var blogNameButtonIsEnabled: Bool {
        get {
            return blogNameButton.enabled
        }
        set {
            blogNameButton.enabled = newValue
        }
    }


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        createAvatarTapGestureRecognizer()
        setupAttributionView()
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if didPreserveStartingConstraintConstants {
            return
        }
        // When awakeFromNib is called, constraint constants have the default values for
        // any w, any h. The constant values for the correct size class are not applied until
        // the view is first moved to its superview. When this happens, it will override any
        // value that has been assigned in the interrum.
        // Preserve starting constraint constants once the view has been added to a window
        // (thus getting a layout pass) and flag that they've been preserved. Then configure
        // the cell if needed.
        preserveStartingConstraintConstants()
        if contentProvider != nil {
            configureCell(contentProvider!)
        }
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

    public override func sizeThatFits(size: CGSize) -> CGSize {
        let innerWidth = innerWidthForSize(size)
        let innerSize = CGSize(width: innerWidth, height: CGFloat.max)

        var height = cardContentView.frame.minY

        height += featuredMediaView.frame.minY
        height += featuredMediaHeightConstraint.constant
        height += featuredMediaBottomConstraint.constant

        height += titleLabel.sizeThatFits(innerSize).height
        height += titleLabelBottomConstraint.constant

        height += summaryLabel.sizeThatFits(innerSize).height
        height += summaryLabelBottomConstraint.constant

        // The attribution view's height constraint is to be less than or equal
        // to the constant. Skip the math when the constant is zero, but use
        // the height returned from sizeThatFits otherwise.
        if attributionHeightConstraint.constant > 0 {
            height += attributionView.sizeThatFits(innerSize).height
            height += attributionBottomConstraint.constant
        }

        // For now, we won't show word counts when showing the attribution view.
        // By convention, check for a zero height for the bottom constraint constant,
        // if its greater than zero we're showing the word count.
        if wordCountBottomConstraint.constant > 0 {
            height += wordCountLabel.sizeThatFits(innerSize).height
            height += wordCountBottomConstraint.constant
        }

        height += actionButtonViewHeightConstraint.constant
        height += actionButtonViewBottomConstraint.constant

        height += cardContentBottomConstraint.constant

        return CGSize(width: size.width, height: height)
    }

    private func innerWidthForSize(size: CGSize) -> CGFloat {
        var width = CGFloat(0.0)
        var horizontalMargin = headerView.frame.minX

        if UIDevice.isPad() {
            width = min(size.width, maxIPadWidthConstraint.constant)
        } else {
            width = size.width
            horizontalMargin += cardContentView.frame.minX
        }
        width -= (horizontalMargin * 2)
        return width
    }


    // MARK: - Configuration

    private func setupAttributionView() {
        attributionView.richTextView.delegate = self
        attributionView.richTextView.userInteractionEnabled = true
        attributionView.richTextView.selectable = true
        attributionView.richTextView.editable = false
    }

    private func preserveStartingConstraintConstants() {
        featuredMediaBottomConstraintConstant = featuredMediaBottomConstraint.constant
        titleLabelBottomConstraintConstant = titleLabelBottomConstraint.constant
        summaryLabelBottomConstraintConstant = summaryLabelBottomConstraint.constant
        attributionBottomConstraintConstant = attributionBottomConstraint.constant
        wordCountBottomConstraintConstant = wordCountBottomConstraint.constant
        actionButtonViewHeightConstraintConstant = actionButtonViewHeightConstraint.constant

        didPreserveStartingConstraintConstants = true
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

        WPStyleGuide.applyReaderCardSiteButtonStyle(blogNameButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)

        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonRight)
    }

    public func configureCell(contentProvider:ReaderPostContentProvider) {
        configureCell(contentProvider, layoutOnly: false)
    }

    public func configureCell(contentProvider:ReaderPostContentProvider, layoutOnly:Bool) {
        configureForLayoutOnly = layoutOnly
        self.contentProvider = contentProvider

        if !didPreserveStartingConstraintConstants {
            return
        }

        configureHeader()
        configureCardImage()
        configureTitle()
        configureSummary()
        configureAttribution()
        configureTag()
        configureWordCount()
        configureActionButtons()
        configureActionViewHeightIfNeeded()

        setNeedsUpdateConstraints()
    }

    private func configureHeader() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: "post-blavatar-placeholder")

        let size = avatarImageView.frame.size.width * UIScreen.mainScreen().scale
        let url = contentProvider?.siteIconForDisplayOfSize(Int(size))
        if !configureForLayoutOnly && url != nil {
            avatarImageView.setImageWithURL(url!, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }

        let blogName = contentProvider?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, forState: .Normal)
        blogNameButton.setTitle(blogName, forState: .Highlighted)
        blogNameButton.setTitle(blogName, forState: .Disabled)

        var byline = contentProvider?.dateForDisplay().shortString()
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@ · %@", author, byline!)
        }

        bylineLabel.text = byline
    }

    private func configureCardImage() {
        if let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() {
            featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant
            featuredMediaBottomConstraint.constant = featuredMediaBottomConstraintConstant

            if !configureForLayoutOnly {
                if featuredImageURL.absoluteString == currentLoadedCardImageURL && featuredImageView.image != nil {
                    return; // Don't reload an image already being displayed.
                }

                // Always clear the previous image so there is no stale or unexpected image
                // momentarily visible.
                featuredImageView.image = nil
                var url = featuredImageURL
                if !(contentProvider!.isPrivate()) {
                    let size = CGSize(width:featuredMediaView.frame.width, height:featuredMediaHeightConstraintConstant)
                    url = PhotonImageURLHelper.photonURLWithSize(size, forImageURL: url)
                    featuredImageView.setImageWithURL(url, placeholderImage:nil)

                } else if (url.host != nil) && url.host!.hasSuffix("wordpress.com") {
                    // private wpcom image needs special handling. 
                    let request = requestForURL(url)
                    featuredImageView.setImageWithURLRequest(request, placeholderImage: nil, success: nil, failure: nil)

                } else {
                    // private but not a wpcom hosted image
                    featuredImageView.setImageWithURL(url, placeholderImage:nil)
                }
                currentLoadedCardImageURL = featuredImageURL.absoluteString
            }

        } else {
            featuredImageView.image = nil
            currentLoadedCardImageURL = nil
            featuredMediaHeightConstraint.constant = 0.0
            featuredMediaBottomConstraint.constant = 0.0
        }

        featuredMediaView.setNeedsUpdateConstraints()
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
            titleLabelBottomConstraint.constant = titleLabelBottomConstraintConstant

        } else {
            titleLabel.attributedText = nil
            titleLabelBottomConstraint.constant = 0.0
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() {
            let attributes = WPStyleGuide.readerCardSummaryAttributes() as! [String: AnyObject]
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: attributes)
            summaryLabelBottomConstraint.constant = summaryLabelBottomConstraintConstant

        } else {
            summaryLabel.attributedText = nil
            summaryLabelBottomConstraint.constant = 0.0
        }

        summaryLabel.numberOfLines = summaryMaxNumberOfLines
        summaryLabel.lineBreakMode = .ByTruncatingTail
    }

    private func configureAttribution() {
        if contentProvider == nil || contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.None {
            attributionHeightConstraint.constant = 0.0
            attributionBottomConstraint.constant = 0.0
            attributionView.configureView(nil)
        } else {
            attributionView.configureView(contentProvider)
            attributionBottomConstraint.constant = attributionBottomConstraintConstant
            attributionHeightConstraint.constant = maxAttributionViewHeight
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
        wordCountLabel.attributedText = nil;

        // For now, if showing the attribution view do not show the word count label
        if attributionHeightConstraint.constant > 0 {
            wordCountBottomConstraint.constant = 0.0
            return
        }

        if contentProvider!.wordCount() != nil {
            let wordCount = contentProvider!.wordCount().integerValue
            let readingTime = contentProvider!.readingTime().integerValue
            wordCountLabel.attributedText = attributedTextForWordCount(wordCount, readingTime:readingTime)
        }

        if wordCountLabel.attributedText == nil {
            wordCountBottomConstraint.constant = 0.0
        } else {
            wordCountBottomConstraint.constant = wordCountBottomConstraintConstant
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
        if configureForLayoutOnly {
            return
        }

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
            actionButtonViewHeightConstraint.constant = 0
        } else {
            actionButtonViewHeightConstraint.constant = actionButtonViewHeightConstraintConstant;
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
        if blogNameButtonIsEnabled {
            delegate?.readerCell(self, headerActionForProvider: contentProvider!)
        }
    }


    // MARK: - Actions

    func didTapHeaderAvatar(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            notifyDelegateHeaderWasTapped()
        }
    }

    @IBAction func didTapBlogNameButton(sender: UIButton) {
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


    // MARK: - RichTextView Delegate Methods

    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        delegate?.readerCell(self, attributionActionForProvider: contentProvider!)
        return false
    }


    // MARK: - Private Types

    private enum CardAction: Int
    {
        case Comment = 1
        case Like
    }
}
