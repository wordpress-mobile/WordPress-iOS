import Foundation
import WordPressShared

public class ReaderDetailView : UIView, WPRichTextViewDelegate
{
    // Wrapper views
    @IBOutlet private weak var innerContentView: UIStackView!

    // Header realated Views
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var blogNameButton: UIButton!
    @IBOutlet private weak var bylineLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    // Content views
    @IBOutlet private weak var featuredImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var richTextView: WPRichTextView!
    @IBOutlet private weak var attributionView: ReaderCardDiscoverAttributionView!


    // Layout Constraints
    @IBOutlet private weak var featuredMediaAspectRatioConstraint: NSLayoutConstraint!
    

    public weak var contentProvider: ReaderPostContentProvider?

    public var enableLoggedInFeatures: Bool = true
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
        setupAvatarTapGestureRecognizer()
        setupRichText()
    }



    public override func intrinsicContentSize() -> CGSize {
        return innerContentView.intrinsicContentSize()
    }


//    public override func sizeThatFits(size: CGSize) -> CGSize {
//        let innerWidth = innerWidthForSize(size)
//        let innerSize = CGSize(width: innerWidth, height: CGFloat.max)
//
//        var height = innerContentView.frame.minY // TODO: Which view?
//
//        height += featuredMediaView.frame.minY
//        height += featuredMediaHeightConstraint.constant
//        height += featuredMediaBottomConstraint.constant
//
//        height += titleLabel.sizeThatFits(innerSize).height
//        height += titleLabelBottomConstraint.constant
//
//        height += richTextView.sizeThatFits(innerSize).height
//        height += richTextBottomConstraint.constant
//
//        // The attribution view's height constraint is to be less than or equal
//        // to the constant. Skip the math when the constant is zero, but use
//        // the height returned from sizeThatFits otherwise.
//        if attributionHeightConstraint.constant > 0 {
//            height += attributionView.sizeThatFits(innerSize).height
//        }
//
//        height += contentBottomConstraint.constant
//
//        return CGSize(width: size.width, height: height)
//    }
//
//
//    private func innerWidthForSize(size: CGSize) -> CGFloat {
//        var width = CGFloat(0.0)
//        var horizontalMargin = headerView.frame.minX
//
//        if UIDevice.isPad() {
//            width = min(size.width, maxIPadWidthConstraint.constant)
//        } else {
//            width = size.width
//            horizontalMargin += innerContentView.frame.minX // TODO: Which view?
//        }
//        width -= (horizontalMargin * 2)
//        return width
//    }


    private func setupAvatarTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: Selector("didTapHeaderAvatar:"))
        avatarImageView.addGestureRecognizer(tgr)
    }


    private func setupRichText() {
        self.richTextView.delegate = self
    }


    /**
     Applies the default styles to the cell's subviews
     */
    private func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()

        WPStyleGuide.applyReaderCardSiteButtonStyle(blogNameButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)

    }


    public func configureView(contentProvider:ReaderPostContentProvider) {

        self.contentProvider = contentProvider

        configureHeader()
        configureFeaturedImage()
        configureTitle()
        configureRichText()

    }


    private func configureHeader() {
        // Always reset
        avatarImageView.image = nil

        let placeholder = UIImage(named: "post-blavatar-placeholder")

        let size = avatarImageView.frame.size.width * UIScreen.mainScreen().scale
        let url = contentProvider?.siteIconForDisplayOfSize(Int(size))
        avatarImageView.setImageWithURL(url!, placeholderImage: placeholder)


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


    private func configureFeaturedImage() {
        featuredImageView.hidden = true

        if let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() {
            var url = featuredImageURL
            // TODO: We need a completion handler for when the image is loaded.
            // In the completion handler, we need to update the aspect ratio constraint
            // and make the imageView visible.

            featuredImageView.image = nil

            if !(contentProvider!.isPrivate()) {
                let size = CGSize(width:featuredImageView.frame.width, height:100) //TODO: Height
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


    private func configureRichText() {
        richTextView.content = contentProvider!.contentForDisplay()
        richTextView.privateContent = contentProvider!.isPrivate()
    }


    // MARK: -

    func notifyDelegateHeaderWasTapped() {
        if blogNameButtonIsEnabled {
//            delegate?.readerCell(self, headerActionForProvider: contentProvider!)
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
//        delegate?.readerCell(self, menuActionForProvider: contentProvider!, fromView: sender)
    }
    

    // MARK: - WPRichTextView Delegate Methods

    public func richTextView(richTextView: WPRichTextView!, didReceiveImageLinkAction imageControl: WPRichTextImage!) {
//        delegate?.readerCell(self, didReceiveImageLinkAction: imageControl)
    }


    public func richTextView(richTextView: WPRichTextView!, didReceiveLinkAction linkURL: NSURL!) {
//        delegate?.readerCell(self, didReceiveLinkAction: linkURL)
    }


    public func richTextViewDidLoadMediaBatch(richTextView: WPRichTextView!) {
//        delegate?.richTextViewDidLoadMediaBatch(richTextView)
        invalidateIntrinsicContentSize()
    }

}
