import Foundation


@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate
{
    // MARK: - Public Properties
    public var onUrlClick: ((NSURL) -> Void)?
    public var attributedText: NSAttributedString? {
        set {
            textView.attributedText = newValue
            setNeedsLayout()
        }
        get {
            return textView.attributedText
        }
    }
    
    public override var isBadge: Bool {
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
    
    public var dataDetectors: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue ?? .None
        }
        get {
            return textView.dataDetectorTypes
        }
    }
    
    public var labelPadding: UIEdgeInsets {
        return privateLabelPadding
    }
    
    public var isTextViewSelectable: Bool {
        set {
            textView.selectable = newValue
        }
        get {
            return textView.selectable
        }
    }

    public var isTextViewClickable: Bool {
        set {
            textView.userInteractionEnabled = newValue
        }
        get {
            return textView.userInteractionEnabled
        }
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
                
        backgroundColor             = WPStyleGuide.Notifications.blockBackgroundColor
        selectionStyle              = .None
        
        assert(textView != nil)
        textView.contentInset       = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero
        textView.backgroundColor    = UIColor.clearColor()
        textView.editable           = false
        textView.selectable         = true
        textView.dataDetectorTypes  = .None
        textView.dataSource         = self
        textView.delegate           = self
        
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    public override func layoutSubviews() {
        // Calculate the TextView's width, before hitting layoutSubviews!
        textView.preferredMaxLayoutWidth = min(bounds.width, maxWidth) - labelPadding.left - labelPadding.right
        super.layoutSubviews()
    }
        
    // MARK: - RichTextView Data Source
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        onUrlClick?(URL)
        return false
    }
    
    public func textView(textView: UITextView, didPressLink link: NSURL) {
        onUrlClick?(link)
    }
    
    // MARK: - Constants
    private let maxWidth            = WPTableViewFixedWidth
    private let privateLabelPadding = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    
    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
}
