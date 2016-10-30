import Foundation
import WordPressShared

@objc public protocol ReaderCardDiscoverAttributionViewDelegate: NSObjectProtocol
{
    func attributionActionSelectedForVisitingSite(view: ReaderCardDiscoverAttributionView)
}

private enum ReaderCardDiscoverAttribution : Int {

    case None // Default, no action
    case VisitSite // Action for verbose attribution to visit a site
}

@objc public class ReaderCardDiscoverAttributionView: UIView
{
    private let gravatarImageName = "gravatar"
    private let blavatarImageName = "post-blavatar-placeholder"

    @IBOutlet private weak var imageView: CircularImageView!
    @IBOutlet private weak var textLabel: UILabel!

    private lazy var originalAttributionParagraphAttributes: [NSObject: AnyObject] = {
        return WPStyleGuide.originalAttributionParagraphAttributes()
    }()

    private var attributionAction: ReaderCardDiscoverAttribution = .None {
        didSet {
            // Enable/disable userInteraction on self if we allow an action.
            self.userInteractionEnabled = attributionAction != .None
        }
    }

    weak var delegate: ReaderCardDiscoverAttributionViewDelegate?


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        // Add a tap gesture for detecting a tap on the label and acting on the current attributionAction.
        //// Ideally this would have independent tappable links but this adds a bit of overrhead for text/link detection
        //// on a UILabel. We might consider migrating to somethnig lik TTTAttributedLabel for more discrete link
        //// detection via UILabel.
        //// Also, rather than detecting a tap on the whole view, we add it to the label and imageView specifically,
        //// to avoid accepting taps outside of the label's text content, on display.
        //// Brent C. Aug/23/2016
        let selector = #selector(ReaderCardDiscoverAttributionView.textLabelTapGesture(_:))
        let labelTap = UITapGestureRecognizer(target: self, action: selector)
        textLabel.addGestureRecognizer(labelTap)

        // Also add a tap recognizer on the imageView.
        let imageTap = UITapGestureRecognizer(target: self, action: selector)
        imageView.addGestureRecognizer(imageTap)

        // Enable userInteraction on the label/imageView by default while userInteraction
        // is toggled on self in attributionAction: didSet for valid actions.
        textLabel.userInteractionEnabled = true
        imageView.userInteractionEnabled = true

        applyOpaqueBackgroundColors()
    }


    // MARK: - Configuration

    /**
     Applies opaque backgroundColors to all subViews to avoid blending, for optimized drawing.
     */
    private func applyOpaqueBackgroundColors() {
        imageView.backgroundColor = UIColor.whiteColor()
        textLabel.backgroundColor = UIColor.whiteColor()
    }

    public func configureView(contentProvider: ReaderPostContentProvider?) {
        if contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.Post {
            configurePostAttribution(contentProvider!)
        } else if contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.Site {
            configureSiteAttribution(contentProvider!, verboseAttribution: false)
        } else {
            reset()
        }
    }


    public func configureViewWithVerboseSiteAttribution(contentProvider: ReaderPostContentProvider?) {
        if let contentProvider = contentProvider {
            configureSiteAttribution(contentProvider, verboseAttribution: true)
        } else {
            reset()
        }
    }


    private func reset() {
        imageView.image = nil
        textLabel.attributedText = nil
        attributionAction = .None
    }


    private func configurePostAttribution(contentProvider: ReaderPostContentProvider) {
        let url = contentProvider.sourceAvatarURLForDisplay()
        let placeholder = UIImage(named: gravatarImageName)
        imageView.setImageWithURL(url, placeholderImage: placeholder)
        imageView.shouldRoundCorners = true

        let str = stringForPostAttribution(contentProvider.sourceAuthorNameForDisplay(),
                                            blogName: contentProvider.sourceBlogNameForDisplay())
        let attributes = originalAttributionParagraphAttributes as! [String: AnyObject]
        textLabel.textColor = WPStyleGuide.grey()
        textLabel.attributedText = NSAttributedString(string: str, attributes: attributes)
        attributionAction = .None
    }


    private func configureSiteAttribution(contentProvider: ReaderPostContentProvider, verboseAttribution verbose:Bool) {
        let url = contentProvider.sourceAvatarURLForDisplay()
        let placeholder = UIImage(named: blavatarImageName)
        imageView.setImageWithURL(url, placeholderImage: placeholder)
        imageView.shouldRoundCorners = false

        let blogName = contentProvider.sourceBlogNameForDisplay()
        let pattern = patternForSiteAttribution(verbose)
        let str = String(format: pattern, blogName)

        let range = (str as NSString).rangeOfString(blogName)
        let font = WPFontManager.systemItalicFontOfSize(WPStyleGuide.originalAttributionFontSize())
        let attributes = originalAttributionParagraphAttributes as! [String: AnyObject]
        let attributedString = NSMutableAttributedString(string: str, attributes: attributes)
        attributedString.addAttribute(NSFontAttributeName, value: font, range: range)
        textLabel.textColor = WPStyleGuide.mediumBlue()
        textLabel.highlightedTextColor = WPStyleGuide.lightBlue()
        textLabel.attributedText = attributedString
        attributionAction = .VisitSite
    }


    private func stringForPostAttribution(authorName: String?, blogName: String?) -> String {
        var str = ""
        if (authorName != nil) && (blogName != nil) {
            let pattern = NSLocalizedString("Originally posted by %@ on %@",
                comment: "Used to attribute a post back to its original author and blog.  The '%@' characters are placholders for the author's name, and the author's blog repsectively.")
            str = String(format: pattern, authorName!, blogName!)

        } else if (authorName != nil) {
            let pattern = NSLocalizedString("Originally posted by %@",
                comment: "Used to attribute a post back to its original author.  The '%@' characters are a placholder for the author's name.")
            str = String(format: pattern, authorName!)

        } else if (blogName != nil) {
            let pattern = NSLocalizedString("Originally posted on %@",
                comment: "Used to attribute a post back to its original blog.  The '%@' characters are a placholder for the blog name.")
            str = String(format: pattern, blogName!)
        }
        return str
    }


    private func patternForSiteAttribution(verbose: Bool) -> String {
        var pattern: String
        if verbose {
            pattern = NSLocalizedString("Visit %@ for more", comment:"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.")
        } else {
            pattern = NSLocalizedString("Visit %@", comment:"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.")
        }
        return pattern
    }


    // MARK: - Touches

    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        // Add highlight if the touch begins inside of the textLabel's frame
        guard let touch: UITouch = event?.allTouches()?.first else {
            return
        }
        if CGRectContainsPoint(textLabel.bounds, touch.locationInView(textLabel)) {
            textLabel.highlighted = true
        }
    }


    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        // Remove highlight if the touch moves outside of the textLabel's frame
        guard textLabel.highlighted else {
            return
        }
        guard let touch: UITouch = event?.allTouches()?.first else {
            return
        }
        if !CGRectContainsPoint(textLabel.bounds, touch.locationInView(textLabel)) {
            textLabel.highlighted = false
        }
    }


    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        guard textLabel.highlighted else {
            return
        }
        textLabel.highlighted = false
    }


    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches!, withEvent: event)
        guard textLabel.highlighted else {
            return
        }
        textLabel.highlighted = false
    }


    // MARK: - Actions

    @objc public func textLabelTapGesture(gesture: UITapGestureRecognizer) {
        switch attributionAction {
        case .VisitSite:
            delegate?.attributionActionSelectedForVisitingSite(self)
        default: break
        }
    }
}
