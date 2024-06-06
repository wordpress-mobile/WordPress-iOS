import UIKit
import DesignSystem

// MARK: - ReplyTextViewDelegate
//
 @objc public protocol NewReplyTextViewDelegate: UITextViewDelegate {
     @objc optional func textView(_ textView: UITextView, didTypeWord word: String)
}

// MARK: - ReplyTextView
//
 open class NewReplyTextView: UIView, UITextViewDelegate {

    // MARK: - Views

    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    // MARK: - Initializers

     public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
     
     required public init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
    // MARK: - Public Properties

     open weak var delegate: NewReplyTextViewDelegate?

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
            textView.accessibilityLabel = placeholderLabel.text
        }
        get {
            return placeholderLabel.text
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

    open override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }

    // MARK: - Public Methods

     open func replaceTextAtCaret(_ text: NSString?, withText replacement: String?) {
        guard let replacementText = replacement,
              let textToReplace = text,
              let selectedRange = textView.selectedTextRange,
              let newPosition = textView.position(from: selectedRange.start, offset: -textToReplace.length),
              let newRange = textView.textRange(from: newPosition, to: selectedRange.start) else {
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
        let respondsToDidType = delegate?.responds(to: #selector(NewReplyTextViewDelegate.textView(_:didTypeWord:))) ?? false

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

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }

    // MARK: - View Methods

    @discardableResult open override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    @discardableResult open override func resignFirstResponder() -> Bool {
        endEditing(true)
        return textView.resignFirstResponder()
    }

    open override func layoutSubviews() {
        self.sizeToFit()
        super.layoutSubviews()
        self.textView.frame = bounds
        self.placeholderLabel.preferredMaxLayoutWidth = bounds.width - (textView.textContainerInset.left + textView.textContainerInset.right)
        self.placeholderLabel.sizeToFit()
        self.placeholderLabel.frame.origin = .init(x: textView.textContainerInset.left, y: textView.textContainerInset.top)
    }

    open override func sizeToFit() {
        self.textView.sizeToFit()
        self.invalidateIntrinsicContentSize()
    }

    // MARK: - Autolayout Helpers

    open override var intrinsicContentSize: CGSize {
        return .init(width: UIView.noIntrinsicMetric, height: textView.contentSize.height)
    }

    // MARK: - Setup Helpers

    fileprivate func setupView() {
        // Setup Layout
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = UIColor.darkGray.cgColor
        layer.borderWidth = 2.0

        // TextView
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.delegate = self
        textView.scrollsToTop = false
        textView.contentInset = .zero
        textView.textContainerInset = .init(top: 8, left: 16, bottom: 8, right: 16)
        textView.autocorrectionType = .yes
        textView.textColor = Style.textColor
        textView.font = Style.font
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.accessibilityIdentifier = "reply-text-view"
        self.addSubview(textView)

        // Placeholder
        placeholderLabel.textColor = Style.placeholderTextColor
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = true
        placeholderLabel.font = textView.font
        placeholderLabel.isUserInteractionEnabled = false
        self.addSubview(placeholderLabel)

        //
        refreshInterface()
    }

    // MARK: - Refresh Helpers

    fileprivate func refreshInterface() {
        refreshPlaceholder()
        refreshSizeIfNeeded()
        refreshScrollPosition()
    }

    fileprivate func refreshSizeIfNeeded() {
        sizeToFit()
    }

    fileprivate func refreshPlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    fileprivate func refreshScrollPosition() {
        let selectedRangeStart = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect = textView.caretRect(for: selectedRangeStart)
        caretRect = caretRect.integral
        textView.scrollRectToVisible(caretRect, animated: false)
    }

    // MARK: - Types

    private struct Style {
        static let font = UIFont.DS.font(.bodyMedium(.regular))
        static let textColor = UIColor.DS.Foreground.primary
        static let placeholderTextColor = UIColor.DS.Foreground.secondary
    }
}
