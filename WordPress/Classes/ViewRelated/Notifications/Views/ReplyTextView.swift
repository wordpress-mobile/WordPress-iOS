import Foundation


@objc public class ReplyTextView : UIView, UITextViewDelegate
{
    // MARK: - Initializers
    public convenience init(width: Int) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        
        textView.font                   = WPStyleGuide.Notifications.Fonts.blockRegular
        placeholderLabel.font           = WPStyleGuide.Notifications.Fonts.blockRegular
        backgroundColor                 = WPStyleGuide.Notifications.Colors.replyBackground
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // We want this view to stick at the bottom
        contentMode                     = .BottomLeft
        autoresizingMask                = .FlexibleWidth | .FlexibleTopMargin
        containerView.autoresizingMask  = .FlexibleWidth | .FlexibleHeight
        
        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsetsZero
    }
    
    
    // MARK: - Public Properties
    public var font: UIFont! {
        didSet {
            textView.font               = font
            placeholderLabel.font       = font
        }
    }
    
    public var placeholder: String! {
        didSet {
            placeholderLabel.text       = placeholder
        }
    }

    public var replyText: String! {
        didSet {
            replyButton.setTitle(replyText, forState: .Normal)
        }
    }
    
    
    // MARK: - Public Helpers
    public func alignAtBottomOfSuperview() {
        if let theSuperview = superview {
            frame.origin.y = CGRectGetMaxY(theSuperview.bounds) - bounds.height
        }
    }
    
    
    // MARK: - UITextViewDelegate
    public func textViewDidChange(textView: UITextView!) {
        placeholderLabel.hidden = !textView.text.isEmpty
        updateTextViewSize()
        scrollToCaretInTextView()
    }
    
    
    // MARK: - View Methods
    public override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        endEditing(true)
        return textView.resignFirstResponder()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame.size.width = self.bounds.width
    }
    
    
    // MARK: - Private Helpers
    private func updateTextViewSize() {
        let textSize        = textView.contentSize
        
        let oldHeight       = frame.height
        let textHeight      = ceil(textSize.height) + textViewPadding.bottom + textViewPadding.top
        let newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        
        if oldHeight == newHeight {
            return
        }

        frame.size.height   = newHeight
        frame.origin.y      += oldHeight - newHeight
    }
    
    private func scrollToCaretInTextView() {
        textView.layoutIfNeeded()
        
        var caretRect           = textView.caretRectForPosition(textView.selectedTextRange.start)
        caretRect.size.height   += textView.textContainerInset.bottom + textViewPadding.bottom
        
        caretRect               = CGRectIntegral(caretRect)
        
        textView.scrollRectToVisible(caretRect, animated: false)
    }
    
    
    // MARK: - Constants
    private let textViewPadding:            UIEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
    private let textViewMaxHeight:          CGFloat     = 84
    private let textViewMinHeight:          CGFloat     = 44
    private let bundle:                     NSArray?
    
    // MARK: - IBOutlets
    @IBOutlet private var textView:         UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton:      UIButton!
    @IBOutlet private var containerView:    UIView!
}
