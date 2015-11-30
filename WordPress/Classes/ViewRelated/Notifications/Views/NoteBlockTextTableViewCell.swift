import Foundation
import WordPressShared

@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate
{
    // MARK: - Public Properties
    public var onUrlClick: ((NSURL) -> Void)?
    public var onAttachmentClick: ((NSTextAttachment) -> Void)?
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
        return self.dynamicType.defaultLabelPadding
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
        
        textView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public override func layoutSubviews() {
        // Calculate the TextView's width, before hitting layoutSubviews!
        textView.preferredMaxLayoutWidth = min(bounds.width, self.dynamicType.maxWidth) - labelPadding.left - labelPadding.right
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
    
    public func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        onAttachmentClick?(textAttachment)
        return false
    }
    
    // MARK: - Constants
    public static let maxWidth            = WPTableViewFixedWidth
    public static let defaultLabelPadding = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
    
    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
}
