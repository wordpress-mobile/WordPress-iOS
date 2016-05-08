import Foundation
import WordPressShared.WPStyleGuide

@objc public protocol ReplyTextViewDelegate : UITextViewDelegate
{
    optional func textView(textView: UITextView, didTypeWord word: String)
}


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
        super.init(coder: coder)!
        setupView()
    }
    
    
    // MARK: - Public Properties
    public weak var delegate: ReplyTextViewDelegate?
    
    public var onReply: ((String) -> ())?
    
    public var text: String! {
        set {
            textView.text = newValue ?? String()
            refreshInterface()
        }
        get {
            return textView.text
        }
    }
    public var placeholder: String! {
        set {
            placeholderLabel.text = newValue ?? String()
        }
        get {
            return placeholderLabel.text
        }
    }

    public var replyText: String! {
        set {
            replyButton.setTitle(newValue, forState: .Normal)
        }
        get {
            return replyButton.titleForState(.Normal)
        }
    }
    
    public var autocorrectionType: UITextAutocorrectionType {
        set {
            textView.autocorrectionType = newValue
        }
        get {
            return textView.autocorrectionType
        }
    }
    
    public var keyboardType: UIKeyboardType {
        set {
            textView.keyboardType = newValue
        }
        get {
            return textView.keyboardType
        }
    }
    
    public override func isFirstResponder() -> Bool {
        return textView.isFirstResponder()
    }
    
    
    // MARK: - Public Methods
    public func replaceTextAtCaret(text: String!, withText replacement: String!) {
        let textToReplace: NSString = text ?? NSString();
        let selectedRange: UITextRange = textView.selectedTextRange!
        let newPosition: UITextPosition = textView.positionFromPosition(selectedRange.start, offset: -textToReplace.length)!
        let newRange: UITextRange = textView.textRangeFromPosition(newPosition, toPosition: selectedRange.start)!
        textView.replaceRange(newRange, withText: replacement)
    }
    
    
    // MARK: - UITextViewDelegate Methods
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidEndEditing(textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let shouldChange = delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
        let respondsToDidType = delegate?.respondsToSelector(#selector(ReplyTextViewDelegate.textView(_:didTypeWord:))) ?? false

        if shouldChange && respondsToDidType {
            let textViewText: NSString = textView.text
            let prerange = NSMakeRange(0, range.location)
            let pretext: NSString = textViewText.substringWithRange(prerange) + text
            let words = pretext.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let lastWord: NSString = words.last! as NSString
            
            delegate?.textView?(textView, didTypeWord: lastWord as String)
        }
        
        return shouldChange
    }

    public func textViewDidChange(textView: UITextView) {
        refreshInterface()
        delegate?.textViewDidChange?(textView)
    }
    
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    
    // MARK: - IBActions
    @IBAction private func btnReplyPressed() {
        if let handler = onReply {
            // Load the new text
            let newText = textView.text
            textView.resignFirstResponder()
            
            // Cleanup + Shrink
            text = String()
            
            // Hit the handler
            handler(newText)
        }
    }
    
    
    // MARK: - Gestures Recognizers
    public func backgroundWasTapped() {
        becomeFirstResponder()
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
        // Make sure contentSize returns... the real content size
        textView.layoutIfNeeded()
        
        // Calculate the entire control's size
        let topPadding      = textView.constraintForAttribute(.Top)    ?? textViewDefaultPadding
        let bottomPadding   = textView.constraintForAttribute(.Bottom) ?? textViewDefaultPadding
        
        let contentHeight   = textView.contentSize.height
        let fullWidth       = frame.width
        let textHeight      = floor(contentHeight + topPadding + bottomPadding)

        let newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        let intrinsicSize   = CGSize(width: fullWidth, height: newHeight)

        return intrinsicSize
    }
    
    
    // MARK: - Setup Helpers
    private func setupView() {
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // Setup Layout
        self.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(containerView)

        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsetsZero
        textView.textContainerInset     = UIEdgeInsetsZero
        textView.font                   = WPStyleGuide.Reply.textFont
        textView.textColor              = WPStyleGuide.Reply.textColor
        textView.textContainer.lineFragmentPadding  = 0
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.accessibilityIdentifier = "ReplyText"
        
        // Enable QuickType
        textView.autocorrectionType     = .Yes
        
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
        bezierView.outerColor           = WPStyleGuide.Reply.backgroundColor
        
        // Bezier
        bezierView.bezierColor          = WPStyleGuide.Reply.separatorColor
        
        // Separators
        separatorsView.topColor         = WPStyleGuide.Reply.separatorColor
        separatorsView.topVisible       = true
        
        // Recognizers
        let recognizer                  = UITapGestureRecognizer(target: self, action: #selector(ReplyTextView.backgroundWasTapped))
        gestureRecognizers              = [recognizer]
    }
    
    
    // MARK: - Refresh Helpers
    private func refreshInterface() {
        refreshPlaceholder()
        refreshReplyButton()
        refreshSizeIfNeeded()
        refreshScrollPosition()
    }
    
    private func refreshSizeIfNeeded() {
        let newSize         = intrinsicContentSize()
        let oldSize         = frame.size

        if newSize.height == oldSize.height {
            return
        }

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
            // FIX: Force layout right away. This prevents the TextView from "Jumping"
            textView.layoutIfNeeded()
            textView.scrollRangeToVisible(textView.selectedRange)
        } else {
            let selectedRangeStart      = textView.selectedTextRange?.start ?? UITextPosition()
            var caretRect               = textView.caretRectForPosition(selectedRangeStart)
            caretRect                   = CGRectIntegral(caretRect)
            textView.scrollRectToVisible(caretRect, animated: false)
        }
    }
    
    
    // MARK: - Constants
    private let textViewDefaultPadding  = CGFloat(12)
    private let textViewMaxHeight       = CGFloat(82)   // Fits 3 lines onscreen
    private let textViewMinHeight       = CGFloat(44)
    
    // MARK: - Private Properties
    private var bundle:                         NSArray?

    // MARK: - IBOutlets
    @IBOutlet private var textView:             UITextView!
    @IBOutlet private var placeholderLabel:     UILabel!
    @IBOutlet private var replyButton:          UIButton!
    @IBOutlet private var bezierView:           ReplyBezierView!
    @IBOutlet private var separatorsView:       SeparatorsView!
    @IBOutlet private var layoutView:           UIView!
    @IBOutlet private var containerView:        UIView!
}
