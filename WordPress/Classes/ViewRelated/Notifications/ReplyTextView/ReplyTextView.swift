import Foundation
import WordPressShared.WPStyleGuide



// MARK: - ReplyTextViewDelegate
//
@objc public protocol ReplyTextViewDelegate: UITextViewDelegate
{
    @objc optional func textView(_ textView: UITextView, didTypeWord word: String)
}


// MARK: - ReplyTextView
//
@objc open class ReplyTextView: UIView, UITextViewDelegate
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
    open weak var delegate: ReplyTextViewDelegate?

    open var onReply: ((String) -> ())?

    open var text: String! {
        set {
            textView.text = newValue ?? String()
            refreshInterface()
        }
        get {
            return textView.text
        }
    }
    open var placeholder: String! {
        set {
            placeholderLabel.text = newValue ?? String()
        }
        get {
            return placeholderLabel.text
        }
    }

    open var replyText: String! {
        set {
            replyButton.setTitle(newValue, for: UIControlState())
        }
        get {
            return replyButton.title(for: UIControlState())
        }
    }

    open var autocorrectionType: UITextAutocorrectionType {
        set {
            textView.autocorrectionType = newValue
        }
        get {
            return textView.autocorrectionType
        }
    }

    open var keyboardType: UIKeyboardType {
        set {
            textView.keyboardType = newValue
        }
        get {
            return textView.keyboardType
        }
    }

    open override var isFirstResponder : Bool {
        return textView.isFirstResponder
    }


    // MARK: - Public Methods
    open func replaceTextAtCaret(_ text: NSString?, withText replacement: String?) {
        guard let replacementText = replacement,
              let textToReplace = text,
              let selectedRange = textView.selectedTextRange,
              let newPosition = textView.position(from: selectedRange.start, offset: -textToReplace.length),
              let newRange = textView.textRange(from: newPosition, to: selectedRange.start) else
        {
            return
        }

        textView.replace(newRange, withText: replacementText)
    }


    // MARK: - UITextViewDelegate Methods
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    open func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }

    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    open func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }

    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let shouldChange = delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
        let respondsToDidType = delegate?.responds(to: #selector(ReplyTextViewDelegate.textView(_:didTypeWord:))) ?? false

        if shouldChange && respondsToDidType {
            let textViewText: NSString = textView.text as NSString
            let prerange = NSMakeRange(0, range.location)
            let pretext = textViewText.substring(with: prerange) + text
            let words = pretext.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            let lastWord: NSString = words.last! as NSString

            delegate?.textView?(textView, didTypeWord: lastWord as String)
        }

        return shouldChange
    }

    open func textViewDidChange(_ textView: UITextView) {
        refreshInterface()
        delegate?.textViewDidChange?(textView)
    }

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange) ?? true
    }


    // MARK: - IBActions
    @IBAction fileprivate func btnReplyPressed() {
        guard let handler = onReply else {
            return
        }

        // Load the new text
        let newText = textView.text
        textView.resignFirstResponder()

        // Cleanup + Shrink
        text = String()

        // Hit the handler
        handler(newText!)
    }


    // MARK: - Gestures Recognizers
    open func backgroundWasTapped() {
        _ = becomeFirstResponder()
    }


    // MARK: - View Methods
    open override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    open override func resignFirstResponder() -> Bool {
        endEditing(true)
        return textView.resignFirstResponder()
    }

    open override func layoutSubviews() {
        // Force invalidate constraints
        invalidateIntrinsicContentSize()
        super.layoutSubviews()
    }


    // MARK: - Autolayout Helpers
    open override var intrinsicContentSize : CGSize {
        // Make sure contentSize returns... the real content size
        textView.layoutIfNeeded()

        // Calculate the entire control's size
        let topPadding      = textView.constraintForAttribute(.top)    ?? textViewDefaultPadding
        let bottomPadding   = textView.constraintForAttribute(.bottom) ?? textViewDefaultPadding

        let contentHeight   = textView.contentSize.height
        let fullWidth       = frame.width
        let textHeight      = floor(contentHeight + topPadding + bottomPadding)

        let newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        let intrinsicSize   = CGSize(width: fullWidth, height: newHeight)

        return intrinsicSize
    }


    // MARK: - Setup Helpers
    fileprivate func setupView() {
        self.frame.size.height          = textViewMinHeight

        // Load the nib + add its container view
        bundle = Bundle.main.loadNibNamed("ReplyTextView", owner: self, options: nil) as NSArray?
        addSubview(containerView)

        // Setup Layout
        self.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(containerView)

        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsets.zero
        textView.textContainerInset     = UIEdgeInsets.zero
        textView.font                   = WPStyleGuide.Reply.textFont
        textView.textColor              = WPStyleGuide.Reply.textColor
        textView.textContainer.lineFragmentPadding  = 0
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.accessibilityIdentifier = "ReplyText"

        // Enable QuickType
        textView.autocorrectionType     = .yes

        // Placeholder
        placeholderLabel.font           = WPStyleGuide.Reply.textFont
        placeholderLabel.textColor      = WPStyleGuide.Reply.placeholderColor

        // Reply
        replyButton.isEnabled             = false
        replyButton.titleLabel?.font    = WPStyleGuide.Reply.buttonFont
        replyButton.setTitleColor(WPStyleGuide.Reply.disabledColor, for: .disabled)
        replyButton.setTitleColor(WPStyleGuide.Reply.enabledColor,  for: UIControlState())

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
    fileprivate func refreshInterface() {
        refreshPlaceholder()
        refreshReplyButton()
        refreshSizeIfNeeded()
        refreshScrollPosition()
    }

    fileprivate func refreshSizeIfNeeded() {
        let newSize         = intrinsicContentSize
        let oldSize         = frame.size

        if newSize.height == oldSize.height {
            return
        }

        invalidateIntrinsicContentSize()
    }

    fileprivate func refreshPlaceholder() {
        placeholderLabel.isHidden         = !textView.text.isEmpty
    }

    fileprivate func refreshReplyButton() {
        let whitespaceCharSet           = CharacterSet.whitespacesAndNewlines
        replyButton.isEnabled             = textView.text.trimmingCharacters(in: whitespaceCharSet).isEmpty == false
    }

    fileprivate func refreshScrollPosition() {
        let selectedRangeStart      = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect               = textView.caretRect(for: selectedRangeStart)
        caretRect                   = caretRect.integral
        textView.scrollRectToVisible(caretRect, animated: false)
    }


    // MARK: - Constants
    fileprivate let textViewDefaultPadding  = CGFloat(12)
    fileprivate let textViewMaxHeight       = CGFloat(82)   // Fits 3 lines onscreen
    fileprivate let textViewMinHeight       = CGFloat(44)

    // MARK: - Private Properties
    fileprivate var bundle:                         NSArray?

    // MARK: - IBOutlets
    @IBOutlet fileprivate var textView:             UITextView!
    @IBOutlet fileprivate var placeholderLabel:     UILabel!
    @IBOutlet fileprivate var replyButton:          UIButton!
    @IBOutlet fileprivate var bezierView:           ReplyBezierView!
    @IBOutlet fileprivate var separatorsView:       SeparatorsView!
    @IBOutlet fileprivate var layoutView:           UIView!
    @IBOutlet fileprivate var containerView:        UIView!
}
