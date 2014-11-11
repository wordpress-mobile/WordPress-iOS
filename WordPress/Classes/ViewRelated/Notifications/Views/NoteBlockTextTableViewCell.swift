import Foundation


@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell, RichTextViewDataSource, RichTextViewDelegate
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
    public func textView(textView: UITextView, didPressLink link: NSURL) {
        onUrlClick?(link)
    }
    
    // MARK: - Constants
    private let maxWidth            = WPTableViewFixedWidth
    private let privateLabelPadding = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    
    // MARK: - IBOutlets
    @IBOutlet private weak var textView: RichTextView!
}
