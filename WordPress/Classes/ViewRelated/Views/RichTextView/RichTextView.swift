import Foundation


@objc public protocol RichTextViewDataSource
{
    optional func textView(textView: UITextView, viewForTextAttachment attachment: NSTextAttachment) -> UIView?
}

@objc public protocol RichTextViewDelegate : UITextViewDelegate
{
    optional func textView(textView: UITextView, didPressLink link: NSURL)
}


@objc public class RichTextView : UIView, UITextViewDelegate
{
    public var dataSource:  RichTextViewDataSource?
    public var delegate:    RichTextViewDelegate?
    
    
    // MARK: - Initializers
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSubviews()
    }
    
    
    // MARK: - Properties    
    public var contentInset: UIEdgeInsets {
        set {
            textView.contentInset = newValue
        }
        get {
            return textView.contentInset
        }
    }

    public var textContainerInset: UIEdgeInsets {
        set {
            textView.textContainerInset = newValue
        }
        get {
            return textView.textContainerInset
        }
    }
    
    public var attributedText: NSAttributedString! {
        set {
            textView.attributedText = newValue
            renderAttachments()
        }
        get {
            return textView.attributedText
        }
    }
    
    public var editable: Bool {
        set {
            textView.editable = newValue
        }
        get {
            return textView.editable
        }
    }

    public var selectable: Bool {
        set {
            textView.selectable = newValue
        }
        get {
            return textView.selectable
        }
    }
    
    public var dataDetectorTypes: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue
        }
        get {
            return textView.dataDetectorTypes
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            textView?.backgroundColor = backgroundColor
        }
    }
    
    public var linkTextAttributes: [NSObject : AnyObject]! {
        set {
            textView.linkTextAttributes = newValue as! [String:AnyObject]
        }
        get {
            return textView.linkTextAttributes
        }
    }

    public var scrollsToTop: Bool {
        set {
            textView.scrollsToTop = newValue
        }
        get {
            return textView.scrollsToTop
        }
    }

    // MARK: - TextKit Getters
    public var layoutManager: NSLayoutManager {
        get {
            return textView.layoutManager
        }
    }
    
    public var textStorage: NSTextStorage {
        get {
            return textView.textStorage
        }
    }
    
    public var textContainer: NSTextContainer {
        get {
            return textView.textContainer
        }
    }

    
    // MARK: - Autolayout Helpers
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    public override func intrinsicContentSize() -> CGSize {
        let width: CGFloat = (preferredMaxLayoutWidth != 0) ? preferredMaxLayoutWidth : frame.width
        let size = CGSize(width: width, height: CGFloat.max)
        return sizeThatFits(size)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        // Fix: Let's add 1pt extra size. There are few scenarios in which text gets clipped by 1 point
        let bottomPadding   = CGFloat(1)
        let maxWidth        = (preferredMaxLayoutWidth != 0) ? min(preferredMaxLayoutWidth, size.width) : size.width
        let maxSize         = CGSize(width: maxWidth, height: CGFloat.max)
        let requiredSize    = textView!.sizeThatFits(maxSize)
        let roundedSize     = CGSize(width: ceil(requiredSize.width), height: ceil(requiredSize.height) + bottomPadding)

        return roundedSize
    }
    
    // MARK: - Private Methods
    private func setupSubviews() {
        gesturesRecognizer                                  = UITapGestureRecognizer()
        gesturesRecognizer.addTarget(self, action: #selector(RichTextView.handleTextViewTap(_:)))
        
        textView                                            = UITextView(frame: bounds)
        textView.backgroundColor                            = backgroundColor
        textView.contentInset                               = UIEdgeInsetsZero
        textView.textContainerInset                         = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding          = 0
        textView.layoutManager.allowsNonContiguousLayout    = false
        textView.editable                                   = editable
        textView.dataDetectorTypes                          = dataDetectorTypes
        textView.delegate                                   = self
        textView.gestureRecognizers                         = [gesturesRecognizer]
        addSubview(textView)
        
        // Setup Layout
        textView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(textView)
    }

    private func renderAttachments() {
        // Nuke old attachments
        _ = attachmentViews.map { $0.removeFromSuperview() }
        attachmentViews.removeAll(keepCapacity: false)
        
        // Proceed only if needed
        if attributedText == nil {
            return
        }
        
        // Load new attachments
        attributedText.enumerateAttachments {
            (attachment: NSTextAttachment, range: NSRange) -> () in
            
            let attachmentView = self.dataSource?.textView?(self.textView, viewForTextAttachment: attachment)
            if attachmentView == nil {
                return
            }
            
            let unwrappedView           = attachmentView!
            unwrappedView.frame.origin  = self.textView.frameForTextInRange(range).integral.origin
            self.textView.addSubview(unwrappedView)
            self.attachmentViews.append(unwrappedView)
        }
    }

    
    // MARK: - UITapGestureRecognizer Helpers
    public func handleTextViewTap(recognizer: UITapGestureRecognizer) {
        
        // NOTE: Why do we need this?
        // Because this mechanism allows us to disable DataDetectors, and yet, detect taps on links.
        //
        let textStorage         = textView.textStorage
        let layoutManager       = textView.layoutManager
        let textContainer       = textView.textContainer
        
        let locationInTextView  = recognizer.locationInView(textView)
        let characterIndex      = layoutManager.characterIndexForPoint(locationInTextView,
                                                                        inTextContainer: textContainer,
                                                                        fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex >= textStorage.length {
            return
        }
        
        // Load the NSURL instance, if any
        let rawURL = textStorage.attribute(NSLinkAttributeName, atIndex: characterIndex, effectiveRange: nil) as? NSURL
        if let unwrappedURL = rawURL {
            delegate?.textView?(textView, didPressLink: unwrappedURL)
        }
    }
    
    
    // MARK: - UITextViewDelegate Wrapped Methods
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        return delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
    }
    
    public func textViewDidChange(textView: UITextView) {
        delegate?.textViewDidChange?(textView)
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }
    
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    public func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange) ?? true
    }
    
    
    // MARK: - Private Properites
    private var textView:           UITextView!
    private var gesturesRecognizer: UITapGestureRecognizer!
    private var attachmentViews:    [UIView] = []
}
