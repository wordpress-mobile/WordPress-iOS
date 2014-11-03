import Foundation


@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var onUrlClick: ((NSURL) -> Void)?
    public var attributedText: NSAttributedString? {
        didSet {
            textView.attributedText = attributedText
            setNeedsLayout()
        }
    }
    
    public var isBadge: Bool = false {
        didSet {
            backgroundColor = WPStyleGuide.Notifications.blockBackgroundColorForRichText(isBadge)
        }
    }
    
    public var linkColor: UIColor? {
        didSet {
            if let unwrappedLinkColor = linkColor {
                textView.linkTextAttributes = [NSForegroundColorAttributeName : unwrappedLinkColor]
            }
        }
    }
    
    public var dataDetectors: UIDataDetectorTypes? {
        didSet {
            if let unwrappedDataDetectors = dataDetectors {
                textView.dataDetectorTypes = unwrappedDataDetectors
            }
        }
    }
    
    public var labelPadding: UIEdgeInsets {
        return privateLabelPadding
    }
    
    public var isTextViewSelectable: Bool = true {
        didSet {
            textView.selectable = isTextViewSelectable
        }
    }
    
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
                
        backgroundColor             = WPStyleGuide.Notifications.blockBackgroundColor
        selectionStyle              = .None
        textView.contentInset       = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero
        textView.backgroundColor    = UIColor.clearColor()
        textView.editable           = false
        textView.selectable         = true
        textView.dataDetectorTypes  = .None
        
        // Setup a Gestures Recognizer: This way we'll handle links!
        gesturesRecognizer          = UITapGestureRecognizer()
        gesturesRecognizer.addTarget(self, action: "handleTap:")
        textView.gestureRecognizers  = [gesturesRecognizer]
    }
    
    public override func layoutSubviews() {
        // Calculate the TextView's width, before hitting layoutSubviews!
        textView.preferredMaxLayoutWidth = min(bounds.width, maxWidth) - labelPadding.left - labelPadding.right
        
        super.layoutSubviews()
    }
    
    
    // MARK: - UITapGestureRecognizer Helpers
    public func handleTap(recognizer: UITapGestureRecognizer) {

        // Detect the location tapped
        let textStorage = textView.textStorage
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        let locationInTextView = recognizer.locationInView(textView)
        let characterIndex = layoutManager.characterIndexForPoint(locationInTextView, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex >= textStorage.length {
            return
        }
        
        // Load the NSURL instance, if any
        let rawURL: AnyObject? = textView.textStorage.attribute(NSLinkAttributeName, atIndex: characterIndex, effectiveRange: nil)
        if let unwrappedURL = rawURL as? NSURL {
            onUrlClick?(unwrappedURL)
        }
    }
    
    
    // MARK: - Constants
    private let maxWidth            = WPTableViewFixedWidth
    private let privateLabelPadding = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    
    // MARK: - Private
    private var gesturesRecognizer: UITapGestureRecognizer!
    
    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
}
