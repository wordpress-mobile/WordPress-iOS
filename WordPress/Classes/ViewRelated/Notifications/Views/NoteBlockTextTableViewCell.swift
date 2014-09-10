import Foundation


@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var onUrlClick: ((NSURL) -> Void)?
    public var attributedText: NSAttributedString? {
        didSet {
            textView.attributedText = attributedText ??  NSAttributedString()
            setNeedsLayout()
        }
    }
    public var isBadge: Bool = false {
        didSet {
            if isBadge {
                backgroundColor = WPStyleGuide.Notifications.badgeBackgroundColor
                alignment       = .Center
            } else {
                backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor
                alignment       = .Left
            }
        }
    }
    public var linkColor: UIColor? {
        didSet {
            if let unwrappedLinkColor = linkColor {
                textView.linkTextAttributes = [NSForegroundColorAttributeName : unwrappedLinkColor]
            }
        }
    }
    public var labelPadding: UIEdgeInsets {
        return privateLabelPadding
    }
    
    
    //  TODO:
    //  Once NotificationDetailsViewController has been migrated to Swift, please, nuke this property, and make sure this class is fed
    //  with an string already aligned. 
    //  This is temporary workaround since WPStyleGuide+Notifications is swift only.
    //
    private var alignment : NSTextAlignment = .Left {
        didSet {
            if attributedText == nil {
                return
            }
            
            let unwrappedMutableString  = attributedText!.mutableCopy() as NSMutableAttributedString
            let range                   = NSRange(location: 0, length: unwrappedMutableString.length)
            let paragraph               = WPStyleGuide.Notifications.blockParagraphStyleWithAlignment(.Center)
            unwrappedMutableString.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
            
            attributedText = unwrappedMutableString
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
        textView.selectable         = false
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
    @IBOutlet private weak var textView: WPDynamicHeightTextView!
}
