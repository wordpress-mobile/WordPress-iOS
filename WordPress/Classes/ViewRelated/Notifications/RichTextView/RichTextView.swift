import Foundation


@objc public protocol RichTextViewDataSource
{
    func viewForTextAttachment(attachment: NSTextAttachment) -> UIView?
}

@objc public protocol RichTextViewDelegate : UITextViewDelegate
{

}


@objc public class RichTextView : UIView, UITextViewDelegate
{
    public var dataSource:  RichTextViewDataSource?
    public var delegate:    RichTextViewDelegate?
    
    
    // MARK: - Initializers
    public override init() {
        super.init()
        setupSubviews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    public override func layoutSubviews() {
        assert(textView != nil)
        super.layoutSubviews()
        textView.frame = bounds
    }

    
    // MARK: - Properties
    public override var frame: CGRect {
        didSet {
            setNeedsLayout()
        }
    }

    public override var bounds: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var editable: Bool = false {
        didSet {
            textView?.editable = editable
        }
    }
    
    public var dataDetectorTypes: UIDataDetectorTypes = .None {
        didSet {
            textView?.dataDetectorTypes = dataDetectorTypes
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            textView?.backgroundColor = backgroundColor
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        // Fix: Let's add 1pt extra size. There are few scenarios in which text gets clipped by 1 point
        let bottomPadding   = CGFloat(1)
        let maxSize         = CGSize(width: frame.width, height: CGFloat.max)
        let requiredSize    = textView!.sizeThatFits(maxSize)
        let roundedSize     = CGSize(width: ceil(requiredSize.width), height: ceil(requiredSize.height) + bottomPadding)
        
        return roundedSize
    }
    
    public var attributedText: NSAttributedString! {
        didSet {
            assert(textView != nil)
            textView.attributedText = attributedText
            renderAttachments()
        }
    }
    
    
    // MARK: - Private Methods
    private func setupSubviews() {
        textView                                            = UITextView(frame: bounds)
        textView.backgroundColor                            = backgroundColor
        textView.contentInset                               = UIEdgeInsetsZero
        textView.textContainerInset                         = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding          = 0
        textView.layoutManager.allowsNonContiguousLayout    = false
        textView.editable                                   = editable
        textView.dataDetectorTypes                          = dataDetectorTypes
        textView.delegate                                   = self
        addSubview(textView)
    }

    private func renderAttachments() {
        // Nuke old attachments
        attachmentViews.map { $0.removeFromSuperview() }
        attachmentViews.removeAll(keepCapacity: false)
        
        // Proceed only if needed
        if attributedText == nil {
            return
        }
        
        // Load new attachments
        attributedText.enumerateAttachments {
            (attachment: NSTextAttachment, range: NSRange) -> () in
            
            let attachmentView = self.dataSource?.viewForTextAttachment(attachment)
            if attachmentView == nil {
                return
            }
            
            let unwrappedView           = attachmentView!
            unwrappedView.frame.origin  = self.textView.frameForTextInRange(range).integerRect.origin
            self.textView.addSubview(unwrappedView)
            self.attachmentViews.append(unwrappedView)
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
    private var attachmentViews:    [UIView] = []
}
