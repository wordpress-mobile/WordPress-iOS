import Foundation


@objc public protocol RichTextViewDataSource {
    @objc optional func textView(_ textView: UITextView, viewForTextAttachment attachment: NSTextAttachment) -> UIView?
}

@objc public protocol RichTextViewDelegate: UITextViewDelegate {
    @objc optional func textView(_ textView: UITextView, didPressLink link: URL)
}


@objc open class RichTextView: UIView, UITextViewDelegate {
    @objc open var dataSource: RichTextViewDataSource?
    @objc open var delegate: RichTextViewDelegate?


    // MARK: - Initializers
    convenience init() {
        self.init(frame: CGRect.zero)
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
    @objc open var contentInset: UIEdgeInsets {
        set {
            textView.contentInset = newValue
        }
        get {
            return textView.contentInset
        }
    }

    @objc open var textContainerInset: UIEdgeInsets {
        set {
            textView.textContainerInset = newValue
        }
        get {
            return textView.textContainerInset
        }
    }

    @objc open var attributedText: NSAttributedString! {
        set {
            textView.attributedText = newValue
            invalidateIntrinsicContentSize()
            renderAttachments()
        }
        get {
            return textView.attributedText
        }
    }

    @objc open var editable: Bool {
        set {
            textView.isEditable = newValue
        }
        get {
            return textView.isEditable
        }
    }

    @objc open var selectable: Bool {
        set {
            textView.isSelectable = newValue
        }
        get {
            return textView.isSelectable
        }
    }

    @objc open var dataDetectorTypes: UIDataDetectorTypes {
        set {
            textView.dataDetectorTypes = newValue
        }
        get {
            return textView.dataDetectorTypes
        }
    }

    open override var backgroundColor: UIColor? {
        didSet {
            textView?.backgroundColor = backgroundColor
        }
    }

    @objc open var linkTextAttributes: [NSAttributedString.Key: Any]! {
        set {
            textView.linkTextAttributes = newValue
        }
        get {
            return textView.linkTextAttributes
        }
    }

    @objc open var scrollsToTop: Bool {
        set {
            textView.scrollsToTop = newValue
        }
        get {
            return textView.scrollsToTop
        }
    }

    open var preferredMaxLayoutWidth: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }


    // MARK: - TextKit Getters
    @objc open var layoutManager: NSLayoutManager {
        get {
            return textView.layoutManager
        }
    }

    @objc open var textStorage: NSTextStorage {
        get {
            return textView.textStorage
        }
    }

    @objc open var textContainer: NSTextContainer {
        get {
            return textView.textContainer
        }
    }


    // MARK: - Private Methods
    fileprivate func setupSubviews() {
        gesturesRecognizer                                  = UITapGestureRecognizer()
        gesturesRecognizer.addTarget(self, action: #selector(RichTextView.handleTextViewTap(_:)))

        textView                                            = UITextView(frame: bounds)
        textView.backgroundColor                            = backgroundColor
        textView.contentInset                               = UIEdgeInsets.zero
        textView.textContainerInset                         = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding          = 0
        textView.layoutManager.allowsNonContiguousLayout    = false
        textView.isEditable                                   = editable
        textView.isScrollEnabled                              = false
        textView.dataDetectorTypes                          = dataDetectorTypes
        textView.delegate                                   = self
        textView.gestureRecognizers                         = [gesturesRecognizer]
        addSubview(textView)

        // Setup Layout
        textView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(textView)
    }

    fileprivate func renderAttachments() {
        // Nuke old attachments
        for view in attachmentViews {
            view.removeFromSuperview()
        }

        attachmentViews.removeAll(keepingCapacity: false)

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

    // MARK: - Overriden Methods
    open override var intrinsicContentSize: CGSize {
        guard let maxWidth = preferredMaxLayoutWidth else {
            return super.intrinsicContentSize
        }

        let maxSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let requiredSize = textView.sizeThatFits(maxSize)

        return requiredSize
    }


    // MARK: - UITapGestureRecognizer Helpers
    @objc open func handleTextViewTap(_ recognizer: UITapGestureRecognizer) {

        // NOTE: Why do we need this?
        // Because this mechanism allows us to disable DataDetectors, and yet, detect taps on links.
        //
        let textStorage         = textView.textStorage
        let layoutManager       = textView.layoutManager
        let textContainer       = textView.textContainer

        let locationInTextView  = recognizer.location(in: textView)
        let characterIndex      = layoutManager.characterIndex(for: locationInTextView,
                                                                        in: textContainer,
                                                                        fractionOfDistanceBetweenInsertionPoints: nil)

        if characterIndex >= textStorage.length {
            return
        }

        // Load the NSURL instance, if any
        let rawURL = textStorage.attribute(.link, at: characterIndex, effectiveRange: nil) as? URL
        if let unwrappedURL = rawURL {
            delegate?.textView?(textView, didPressLink: unwrappedURL)
        }
    }


    // MARK: - UITextViewDelegate Wrapped Methods
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    open func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }

    open func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }

    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    open func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewDidChange?(textView)
    }

    open func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }

    open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
    }


    // MARK: - Private Properites
    fileprivate var textView: UITextView!
    fileprivate var gesturesRecognizer: UITapGestureRecognizer!
    fileprivate var attachmentViews: [UIView] = []
}
