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
    
    
    // MARK: - Public Properties
    public weak var delegate: UITextViewDelegate?
    
    public var onReply: ((String) -> ())?
    
    public var text: String! {
        didSet {
            textView.text = text
            refreshInterface()
        }
    }
    public var placeholder: String! {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    public var replyText: String! {
        didSet {
            replyButton.setTitle(replyText, forState: .Normal)
        }
    }
    
    
    // MARK: - UITextViewDelegate Methods
    public func textViewShouldBeginEditing(textView: UITextView!) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    public func textViewDidBeginEditing(textView: UITextView!) {
        delegate?.textViewDidBeginEditing?(textView)
    }
    
    public func textViewShouldEndEditing(textView: UITextView!) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidEndEditing(textView: UITextView!) {
        delegate?.textViewDidEndEditing?(textView)
    }
    
    public func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        return delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
    }

    public func textViewDidChange(textView: UITextView!) {
        refreshInterface()
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
        return textView.resignFirstResponder()
    }

    public override func layoutSubviews() {
        // Force invalidate constraints
        invalidateIntrinsicContentSize()
        super.layoutSubviews()
    }
    
    
    // MARK: - Autolayout Helpers
    public override func intrinsicContentSize() -> CGSize {
        let topPadding      = textView.constraintForAttribute(.Top)     ?? textViewDefaultPadding
        let bottomPadding   = textView.constraintForAttribute(.Bottom)  ?? textViewDefaultPadding
        
        let screenWidth     = UIScreen.mainScreen().screenWidthAtCurrentOrientation()
        let textHeight      = floor(textView.contentSize.height + topPadding + bottomPadding)

        var newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        let intrinsicSize   = CGSize(width: screenWidth, height: newHeight)

        return intrinsicSize
    }
    
    
    // MARK: - Setup Helpers
    private func setupView() {
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // Setup Layout
        setTranslatesAutoresizingMaskIntoConstraints(false)
        containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        pinSubviewToAllEdges(containerView)

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
        replyButton.titleLabel?.font    = WPStyleGuide.Reply.buttonFont
        replyButton.setTitleColor(WPStyleGuide.Reply.disabledColor, forState: .Disabled)
        replyButton.setTitleColor(WPStyleGuide.Reply.enabledColor,  forState: .Normal)
        
        // Background
        layoutView.backgroundColor      = WPStyleGuide.Reply.backgroundColor

        // Recognizers
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

        updateConstraint(.Height, constant: newSize.height)
        setNeedsLayout()
        layoutIfNeeded()
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
            let selectedRangeStart      = textView.selectedTextRange?.start ?? UITextPosition()
            var caretRect               = textView.caretRectForPosition(selectedRangeStart)
            caretRect                   = CGRectIntegral(caretRect)
            textView.scrollRectToVisible(caretRect, animated: false)
        }
    }
    
    
    // MARK: - Constants
    private let textViewDefaultPadding:     CGFloat         = 12
    private let textViewMaxHeight:          CGFloat         = 82   // Fits 3 lines onscreen
    private let textViewMinHeight:          CGFloat         = 44
    
    // MARK: - Private Properties
    private var bundle:                     NSArray?
    
    // MARK: - IBOutlets
    @IBOutlet private var textView:         UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton:      UIButton!
    @IBOutlet private var layoutView:       UIView!
    @IBOutlet private var containerView:    UIView!
}
