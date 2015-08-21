import Foundation

@objc public protocol ReaderPostCellDelegate: NSObjectProtocol
{
    func readerCell(cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider)
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
    @IBOutlet private weak var actionButtonCenter: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!
    @IBOutlet private weak var actionButtonFlushLeft: UIButton!

    // Layout Constraints
    @IBOutlet private weak var featuredMediaHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var featuredMediaBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var summaryLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var attributionHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var attributionBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tagButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tagButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var wordCountBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardContentBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var maxIPadWidthConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private var featuredMediaHeightConstraintConstant = CGFloat(0.0)
    private var featuredMediaBottomConstraintConstant = CGFloat(0.0)
    private var titleLabelBottomConstraintConstant = CGFloat(0.0)
    private var summaryLabelBottomConstraintConstant = CGFloat(0.0)
    private var attributionBottomConstraintConstant = CGFloat(0.0)
    private var tagButtonHeightConstraintConstant = CGFloat(0.0)
    private var tagButtonBottomConstraintConstant = CGFloat(0.0)
    private var wordCountBottomConstraintConstant = CGFloat(0.0)

    private var didPreserveStartingConstraintConstants = false
    private var loadMediaWhenConfigured = true

    private let summaryMaxNumberOfLines = 3
    private let maxAttributionViewHeight: CGFloat = 200.0 // 200 is an arbitrary height, but should be a sufficiently high number.


    // MARK: - Accessors

    public override var backgroundColor: UIColor? {
        didSet{
            contentView.backgroundColor = backgroundColor
            innerContentView.backgroundColor = backgroundColor
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
        }
        height += attributionBottomConstraint.constant

        // On the iPad, the tag and word count views are horizontal,
        // aligned with the action buttons. Only add their heights
        // for the iPhone.
        if !UIDevice.isPad() {
            height += tagButtonHeightConstraint.constant
            height += tagButtonBottomConstraint.constant

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
            width = maxIPadWidthConstraint.constant
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
        featuredMediaHeightConstraintConstant = featuredMediaHeightConstraint.constant
        featuredMediaBottomConstraintConstant = featuredMediaBottomConstraint.constant
        titleLabelBottomConstraintConstant = titleLabelBottomConstraint.constant
        summaryLabelBottomConstraintConstant = summaryLabelBottomConstraint.constant
        attributionBottomConstraintConstant = attributionBottomConstraint.constant
        tagButtonHeightConstraintConstant = tagButtonHeightConstraint.constant
        tagButtonBottomConstraintConstant = tagButtonBottomConstraint.constant
        wordCountBottomConstraintConstant = wordCountBottomConstraint.constant

        didPreserveStartingConstraintConstants = true
    }

    private func createAvatarTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: Selector("didTapHeaderAvatar:"))
        avatarImageView.addGestureRecognizer(tgr)
    }


    /**
        Applies the default styles to the cell's subviews
    */
    private func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        cardBorderView.backgroundColor = WPStyleGuide.readerCardCellBorderColor()

        WPStyleGuide.applyReaderCardSiteButtonActiveStyle(blogNameButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)
        WPStyleGuide.applyReaderCardTagButtonStyle(tagButton)

        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonCenter)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonFlushLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonRight)
    }

    public func configureCell(contentProvider:ReaderPostContentProvider) {
        configureCell(contentProvider, loadingMedia: true)
    }

    public func configureCell(contentProvider:ReaderPostContentProvider, loadingMedia:Bool) {
        loadMediaWhenConfigured = loadingMedia
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

        setNeedsUpdateConstraints()
    }

    private func configureHeader() {
        // Always reset
        avatarImageView.image = nil

        var placeholder = UIImage(named: "post-blavatar-placeholder")

        if loadMediaWhenConfigured && contentProvider?.avatarURLForDisplay() != nil {
            var url = contentProvider?.avatarURLForDisplay()
            avatarImageView.setImageWithURL(url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }

        var blogName = contentProvider?.blogNameForDisplay()
        blogNameButton.setTitle(blogName, forState: .Normal)
        blogNameButton.setTitle(blogName, forState: .Highlighted)

        var byline = contentProvider?.dateForDisplay().shortString()
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@, %@", byline!, author)
        }

        bylineLabel.text = byline
    }

    private func configureCardImage() {
        // Always clear the previous image so there is no stale or unexpected image 
        // momentarily visible.
        featuredImageView.image = nil
        if let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() {
            featuredMediaHeightConstraint.constant = featuredMediaHeightConstraintConstant
            featuredMediaBottomConstraint.constant = featuredMediaBottomConstraintConstant

            if loadMediaWhenConfigured {
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
            }

        } else {
            featuredMediaHeightConstraint.constant = 0.0
            featuredMediaBottomConstraint.constant = 0.0
        }

        featuredMediaView.setNeedsUpdateConstraints()
    }

    private func requestForURL(url:NSURL) -> NSURLRequest {
        var requestURL = url
        if let absoluteString = requestURL.absoluteString {
            if !(absoluteString.hasPrefix("https")) {
                var sslURL = absoluteString.stringByReplacingOccurrencesOfString("http", withString: "https")
                requestURL = NSURL(string: sslURL)!
            }
        }

        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let token = acctServ.defaultWordPressComAccount().authToken
        var request = NSMutableURLRequest(URL: requestURL)
        var headerValue = String(format: "Bearer %@", token)
        request.addValue(headerValue, forHTTPHeaderField: "Authorization")

        return request
    }

    private func configureTitle() {
        if let title = contentProvider?.titleForDisplay() {
            let attributes = WPStyleGuide.readerCardTitleAttributes()
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
            titleLabelBottomConstraint.constant = titleLabelBottomConstraintConstant

        } else {
            titleLabel.attributedText = nil
            titleLabelBottomConstraint.constant = 0.0
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() {
            let attributes = WPStyleGuide.readerCardSummaryAttributes()
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
        // NOTE: stubbed implementation until we start storing the tag in core data.
        // var title = "#ReaderTag"
        // tagButton.setTitle(title, forState: .Normal)
        // tagButton.setTitle(title, forState: .Highlighted)
        if !UIDevice.isPad() {
            // For layout purposes, we always want the default height on the iPad.
            tagButtonHeightConstraint.constant = 0.0
        }
        tagButtonBottomConstraint.constant = 0.0
    }

    private func configureWordCount() {
        // NOTE: stubbed implementation until we start storing the word count and reading time in core data
        // wordCountLabel.attributedText = attributedTextForWordCount(100, readingTime: "(~2 min)")
        wordCountLabel.attributedText = nil;
        if wordCountLabel.attributedText == nil {
            wordCountBottomConstraint.constant = 0.0
        } else {
            wordCountBottomConstraint.constant = wordCountBottomConstraintConstant
        }
    }

    private func attributedTextForWordCount(wordCount:Int?, readingTime:String?) -> NSAttributedString? {
        if wordCount == nil && readingTime == nil {
            return nil
        }

        var attrStr = NSMutableAttributedString()

        if let theWordCount = wordCount {
            var wordsStr = NSLocalizedString("words",
                                            comment: "Part of a label letting the user know how any words are in a post. For example: '300 words'")

            var countStr = String(format: "%d %@ ", theWordCount, wordsStr)
            var attributes = WPStyleGuide.readerCardWordCountAttributes()
            var attrWordCount = NSAttributedString(string: countStr, attributes: attributes)
            attrStr.appendAttributedString(attrWordCount)
        }

        if let theReadingTime = readingTime {
            var attributes = WPStyleGuide.readerCardReadingTimeAttributes()
            var attrReadingTime = NSAttributedString(string: theReadingTime, attributes: attributes)
            attrStr.appendAttributedString(attrReadingTime)
        }

        return attrStr
    }

    private func configureActionButtons() {
        resetActionButtons()
        if contentProvider == nil {
            return
        }

        var buttons = [
            actionButtonLeft,
            actionButtonCenter,
            actionButtonRight
        ]

        // Show Likes
        if contentProvider!.isLikesEnabled() {
            let button = buttons.removeLast() as UIButton
            configureLikeActionButton(button)
        }

        // Show comments
        if contentProvider!.commentsOpen() || contentProvider!.commentCount().integerValue > 0 {
            let button = buttons.removeLast() as UIButton
            configureCommentActionButton(button)
        }

        // Show visit
        if UIDevice.isPad() {
            let button = buttons.removeLast() as UIButton
            configureVisitActionButton(button)
        } else {
            configureVisitActionButton(actionButtonFlushLeft)
        }
    }

    private func resetActionButtons() {
        resetActionButton(actionButtonCenter)
        resetActionButton(actionButtonFlushLeft)
        resetActionButton(actionButtonLeft)
        resetActionButton(actionButtonRight)
    }

    private func resetActionButton(button:UIButton) {
        button.setTitle(nil, forState: .Normal)
        button.setImage(nil, forState: .Normal)
        button.setImage(nil, forState: .Highlighted)
        button.selected = false
        button.hidden = true
    }

    private func configureActionButton(button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?) {
        button.setTitle(title, forState: .Normal)
        button.setImage(image, forState: .Normal)
        button.setImage(highlightedImage, forState: .Highlighted)
        button.selected = false
        button.hidden = false
    }

    private func configureLikeActionButton(button: UIButton) {
        button.tag = CardAction.Like.rawValue
        let likeStr = NSLocalizedString("Like", comment: "Text for the 'like' button. Tapping marks a post in the reader as 'liked'.")
        let likedStr = NSLocalizedString("Liked", comment: "Text for the 'like' button. Tapping removes the 'liked' status from a post.")
        let title = contentProvider!.isLiked() ? likedStr : likeStr

        let imageName = contentProvider!.isLiked() ? "icon-reader-liked" : "icon-reader-like"
        var image = UIImage(named: imageName)
        var highlightImage = UIImage(named: "icon-reader-like-highlight")

        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
    }

    private func configureCommentActionButton(button: UIButton) {
        button.tag = CardAction.Comment.rawValue
        let title = contentProvider?.commentCount().stringValue
        var image = UIImage(named: "icon-reader-comment")
        var highlightImage = UIImage(named: "icon-reader-comment-highlight")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
    }

    private func configureVisitActionButton(button: UIButton) {
        button.tag = CardAction.Visit.rawValue
        let title = NSLocalizedString("Visit", comment: "Text for the 'visit' button. Tapping takes the user to the web page for a post being viewed in the reader.")
        var image = UIImage(named: "icon-reader-visit")
        var highlightImage = UIImage(named: "icon-reader-visit-highlight")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
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
        delegate?.readerCell(self, headerActionForProvider: contentProvider!)
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

        var tag = CardAction(rawValue: sender.tag)!
        switch tag {
        case .Comment :
            delegate?.readerCell(self, commentActionForProvider: contentProvider!)
        case .Like :
            delegate?.readerCell(self, likeActionForProvider: contentProvider!)
        case .Visit :
            delegate?.readerCell(self, visitActionForProvider: contentProvider!)
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
        case Visit
    }
}
