import Foundation


@objc public class ReplyTextView : UIView, UITextViewDelegate
{
    // MARK: - Initializers
    public convenience init(width: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.init(frame: frame)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private init(frame: CGRect, isProxy: Bool) {
        super.init(frame: frame)
        isProxyTextView = isProxy
        setupView()
    }
    
    
    // MARK: - Public Properties
    public weak var delegate: UITextViewDelegate?
    
    public var onReply: ((String) -> ())? {
        didSet {
            refreshProxyTextView()
        }
    }
    
    public override var inputAccessoryView: UIView! {
        get {
            return proxyTextView
        }
    }
    
    public var text: String! {
        didSet {
            textView.text = text
            refreshInterface()
            refreshProxyTextView()
        }
    }
    public var placeholder: String! {
        didSet {
            placeholderLabel.text = placeholder
            refreshProxyTextView()
        }
    }

    public var replyText: String! {
        didSet {
            replyButton.setTitle(replyText, forState: .Normal)
            refreshProxyTextView()
        }
    }
    
    
    // MARK: - Public Helpers
    public func alignAtBottomOfSuperview() {
        if let theSuperview = superview {
            frame.origin.y = CGRectGetMaxY(theSuperview.bounds) - bounds.height
        }
    }
    
    
    // MARK: - UITextViewDelegate Methods
    public func textViewShouldBeginEditing(textView: UITextView!) -> Bool {
        if isProxyDismissing {
            return false
        }
        
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    public func textViewDidBeginEditing(textView: UITextView!) {
        
        if proxyTextView != nil {
            let delay = dispatch_time_t(0.1)
            dispatch_after(delay, dispatch_get_main_queue()) {
                // FIX: Xcode beta 6 fails if the only sentence returns a value
                let result = self.proxyTextView?.becomeFirstResponder()
            }

        } else {
            delegate?.textViewDidBeginEditing?(textView)
        }
    }
    
    public func textViewShouldEndEditing(textView: UITextView!) -> Bool {
        isProxyDismissing = self.textView != textView
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidEndEditing(textView: UITextView!) {
        isProxyDismissing = false
        delegate?.textViewDidEndEditing?(textView)
    }
    
    public func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        return delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
    }

    public func textViewDidChange(textView: UITextView!) {
        // Don't overwork if this is the proxyTextView
        if (textView == self.textView) {
            refreshInterface()
        }
        
        delegate?.textViewDidChange?(textView)
    }
    
    public func textView(textView: UITextView!, shouldInteractWithURL URL: NSURL!, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    
    // MARK: - IBActions
    @IBAction private func btnReplyPressed() {
        if let handler = onReply {
            handler(textView.text)
        }
    }
    
    
    // MARK: - View Methods
    public override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        endEditing(true)
        return super.resignFirstResponder()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame.size.width  = self.bounds.width
    }
    
    
    // MARK: - Autolayout Helpers
    public override func intrinsicContentSize() -> CGSize {
        let topPadding      = textView.constraintForAttribute(.Top)     ?? textViewDefaultPadding
        let bottomPadding   = textView.constraintForAttribute(.Bottom)  ?? textViewDefaultPadding
        
        // Calculate the new height
        let textHeight      = floor(textView.contentSize.height + topPadding + bottomPadding)
        
        var newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        let intrinsicSize   = CGSize(width: frame.width, height: newHeight)
        
        return intrinsicSize
    }
    
    
    // MARK: - Setup Helpers
    private func setupView() {
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsetsZero
        textView.textContainerInset     = UIEdgeInsetsZero
        textView.font                   = WPStyleGuide.Reply.textFont
        textView.textColor              = WPStyleGuide.Reply.textColor
        textView.textContainer.lineFragmentPadding  = 0
        
        // Placeholder
        placeholderLabel.font           = WPStyleGuide.Reply.textFont
        placeholderLabel.textColor      = WPStyleGuide.Reply.placeholderColor
        
        // Reply
        replyButton.enabled             = false
        replyButton.titleLabel.font     = WPStyleGuide.Reply.buttonFont
        replyButton.setTitleColor(WPStyleGuide.Reply.disabledColor, forState: .Disabled)
        replyButton.setTitleColor(WPStyleGuide.Reply.enabledColor,  forState: .Normal)
        
        // Background
        layoutView.backgroundColor      = WPStyleGuide.Reply.backgroundColor
        
        // We want this view to stick at the bottom
        contentMode                     = .BottomLeft
        autoresizingMask                = .FlexibleWidth | .FlexibleHeight | .FlexibleTopMargin
        containerView.autoresizingMask  = .FlexibleWidth | .FlexibleHeight
        
        // Setup the ProxyTextView: Prevent Recursion
        if isProxyTextView {
            return
        }
        
        let proxyTextView               = ReplyTextView(frame: bounds, isProxy: true)
        proxyTextView.delegate          = self
        textView.inputAccessoryView     = proxyTextView
        self.proxyTextView              = proxyTextView
        
        let recognizer                  = UITapGestureRecognizer(target: self, action: "backgroundWasTapped")
        gestureRecognizers              = [recognizer]
    }
    
    public func backgroundWasTapped() {
        becomeFirstResponder()
    }
    
    // MARK: - Refresh Helpers
    private func refreshInterface() {
        refreshPlaceholder()
        refreshReplyButton()
        refreshSizeIfNeeded()
        refreshScrollPosition()
    }
    
    private func refreshSizeIfNeeded() {
        var newSize         = intrinsicContentSize()
        let oldSize         = frame.size
        
        if newSize.height == oldSize.height {
            return
        }
        
        frame.size.height   = newSize.height
        invalidateIntrinsicContentSize()
    }
    
    private func refreshPlaceholder() {
        placeholderLabel.hidden         = !textView.text.isEmpty
    }
    
    private func refreshReplyButton() {
        let whitespaceCharSet           = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        replyButton.enabled             = textView.text.stringByTrimmingCharactersInSet(whitespaceCharSet).isEmpty == false
    }
    
    private func refreshScrollPosition() {
        // FIX: In iOS 8, scrollRectToVisible causes a weird flicker
        if UIDevice.isOS8() {
            textView.scrollRangeToVisible(textView.selectedRange)
        } else {
            var caretRect               = textView.caretRectForPosition(textView.selectedTextRange.start)
            caretRect                   = CGRectIntegral(caretRect)
            textView.scrollRectToVisible(caretRect, animated: false)
        }
    }
    
    private func refreshProxyTextView() {
        // Swift is not allowing us to do this in didSet. Not cool.
        proxyTextView?.placeholder  = placeholder
        proxyTextView?.replyText    = replyText
        proxyTextView?.text         = text
        proxyTextView?.onReply      = onReply
    }

    
    // MARK: - Constants
    private let textViewDefaultPadding:     CGFloat         = 12
    private let textViewMaxHeight:          CGFloat         = 82   // Fits 3 lines onscreen
    private let textViewMinHeight:          CGFloat         = 44
    
    // MARK: - Private Properties
    private var bundle:                     NSArray?
    private var proxyTextView:              ReplyTextView?
    private var isProxyTextView:            Bool            = false
    private var isProxyDismissing:          Bool            = false
    
    // MARK: - IBOutlets
    @IBOutlet private var textView:          UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton:      UIButton!
    @IBOutlet private var layoutView:       UIView!
    @IBOutlet private var containerView:    UIView!
}
