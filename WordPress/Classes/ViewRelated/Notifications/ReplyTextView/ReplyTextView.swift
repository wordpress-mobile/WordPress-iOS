import Foundation
import WordPressShared.WPStyleGuide
import Gridicons


// MARK: - ReplyTextViewDelegate
//
@objc public protocol ReplyTextViewDelegate: UITextViewDelegate {
    @objc optional func textView(_ textView: UITextView, didTypeWord word: String)
    @objc func updateUIForExpandedReply()
    @objc func updateUIForCollapsedReply()
}


// MARK: - ReplyTextView
//
@objc open class ReplyTextView: UIView, UITextViewDelegate {
    // MARK: - Initializers
    @objc public convenience init(width: CGFloat) {
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
    @objc open weak var delegate: ReplyTextViewDelegate?

    @objc open var onReply: ((String) -> ())?

    @objc open var text: String! {
        set {
            textView.text = newValue ?? String()
            refreshInterface()
        }
        get {
            return textView.text
        }
    }
    @objc open var placeholder: String! {
        set {
            placeholderLabel.text = newValue ?? String()
            textView.accessibilityLabel = placeholderLabel.text
        }
        get {
            return placeholderLabel.text
        }
    }

    open var maximumNumberOfVisibleLines = Settings.maximumNumberOfVisibleLines {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    @objc open var autocorrectionType: UITextAutocorrectionType {
        set {
            textView.autocorrectionType = newValue
        }
        get {
            return textView.autocorrectionType
        }
    }

    @objc open var keyboardType: UIKeyboardType {
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

    @objc open var animationDuration: Double = 0.5


    // MARK: - Public Methods
    @objc open func replaceTextAtCaret(_ text: NSString?, withText replacement: String?) {
        guard let replacementText = replacement,
              let textToReplace = text,
              let selectedRange = textView.selectedTextRange,
              let newPosition = textView.position(from: selectedRange.start, offset: -textToReplace.length),
              let newRange = textView.textRange(from: newPosition, to: selectedRange.start) else {
            return
        }

        textView.replace(newRange, withText: replacementText)
    }

    @objc open func collapseReplyTextView() {
        isExpanded = false
        self.headerView.isHidden = true
        expandButtonExpandedYConstraint.isActive = false
        replyButtonExpandedYConstraint.isActive = false
        textViewLeadingConstraint.constant += expandButton.frame.width + viewSpacing
        textViewTrailingConstraint.constant += replyButton.frame.width + viewSpacing
        UIView.animate(withDuration: animationDuration,
                         animations: {
                            self.refreshInterface()
                         },
                         completion: { _ in
                            self.expandButton.setImage(Gridicon.iconOfType(.chevronUp),
                                                       for: .normal)
                            expandButton.accessibilityLabel = NSLocalizedString("Expand text area", comment: "Describing button to expand the reply text editable area.")
                         })
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

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }


    // MARK: - IBActions
    @IBAction fileprivate func btnReplyPressed() {
        guard let handler = onReply else {
            return
        }

        // We can't reply without an internet connection
        let appDelegate = WordPressAppDelegate.shared
        guard appDelegate!.connectionAvailable else {
            let title = NSLocalizedString("No Connection", comment: "Title of error prompt when no internet connection is available.")
            let message = NSLocalizedString("The Internet connection appears to be offline.",
                                            comment: "Message of error prompt shown when a user tries to perform an action without an internet connection.")
            WPError.showAlert(withTitle: title, message: message)
            textView.resignFirstResponder()
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

    @IBAction func toggleTextViewDisplay(_ sender: UIButton) {
        if isExpanded {
            collapseTextView()
        } else {
            expandTextView()
        }
    }

    fileprivate func expandTextView() {
        isExpanded = true
        delegate?.updateUIForExpandedReply()
        headerViewLabel.text = NSLocalizedString("Comment", comment: "Title for full screen comment display.")
        updateHeaderHeight()
        expandButtonExpandedYConstraint.isActive = true
        replyButtonExpandedYConstraint.isActive = true
        textViewLeadingConstraint.constant -= expandButton.frame.width + viewSpacing
        textViewTrailingConstraint.constant -= replyButton.frame.width + viewSpacing
        UIView.animate(withDuration: animationDuration,
                         animations: {
                            self.headerView.isHidden = false
                            self.layoutIfNeeded()
                         },
                         completion: { _ in
                            self.expandButton.setImage(Gridicon.iconOfType(.chevronDown), for: .normal)
                            expandButton.accessibilityLabel = NSLocalizedString("Reduce text area", comment: "Describing button to reduce the reply text editable area.")
                         })
    }

    fileprivate func collapseTextView() {
        isExpanded = false
        delegate?.updateUIForCollapsedReply()
        collapseReplyTextView()
    }

    // MARK: - Gestures Recognizers
    @objc open func backgroundWasTapped() {
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

    @objc open func updateHeaderHeight() {
        headerHeightConstraint.constant = safeAreaHeight + replyButton.frame.height + viewSpacing
    }

    // MARK: - Autolayout Helpers
    open override var intrinsicContentSize: CGSize {
        if isExpanded {
            let newHeight = frame.maxY
            return CGSize(width: frame.width, height: newHeight)
        }
        // Make sure contentSize returns... the real content size
        textView.layoutIfNeeded()

        // Calculate the entire control's size
        let newHeight = min(max(contentHeight, minimumHeight), maximumHeight)
        let intrinsicSize = CGSize(width: frame.width, height: newHeight)

        return intrinsicSize
    }


    // MARK: - Setup Helpers
    fileprivate func setupView() {
        // Load the nib + add its container view
        bundle = Bundle.main.loadNibNamed("ReplyTextView", owner: self, options: nil) as NSArray?
        addSubview(contentView)

        // Setup Layout
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(contentView)

        // Setup the TextView
        textView.delegate = self
        textView.scrollsToTop = false
        textView.backgroundColor = WPStyleGuide.Reply.textViewBackground
        textView.font = WPStyleGuide.Reply.textFont
        textView.textColor = WPStyleGuide.Reply.textColor
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.accessibilityIdentifier = "ReplyText"

        // TextView Initial Constraint Settings
        textViewLeadingConstraint.constant += expandButton.frame.width + viewSpacing
        textViewTrailingConstraint.constant += replyButton.frame.width + viewSpacing

        // Enable QuickType
        textView.autocorrectionType = .yes

        // Placeholder
        placeholderLabel.font = WPStyleGuide.Reply.textFont
        placeholderLabel.textColor = WPStyleGuide.Reply.placeholderColor

        // Reply Button
        replyButton.isEnabled = false
        replyButton.tintColor = .listSmallIcon
        replyButton.imageView?.contentMode = .scaleAspectFit
        replyButton.accessibilityLabel = NSLocalizedString("Send Reply", comment: "Describing the action of the send button for comments.")

        // Expand Button
        expandButton.setImage(Gridicon.iconOfType(.chevronUp), for: .normal)
        expandButton.accessibilityLabel = NSLocalizedString("Expand text area", comment: "Describing button to expand the reply text editable area.")

        // Header View
        headerView.isHidden = true

        // Background
        contentView.backgroundColor = .basicBackground

        // Separators
        separatorsView.topColor = WPStyleGuide.Reply.separatorColor
        separatorsView.topVisible = true

        // Expand Collapse Button
        expandButton.tintColor = UIColor.listIcon
        expandButton.imageView?.contentMode = .scaleAspectFit

        // Constraints
        expandButtonExpandedYConstraint = expandButton.centerYAnchor.constraint(equalTo: headerViewLabel.centerYAnchor, constant: 0.0)
        replyButtonExpandedYConstraint = replyButton.centerYAnchor.constraint(equalTo: headerViewLabel.centerYAnchor, constant: 0.0)

        /// Initial Sizing: Final step, since this depends on other control(s) initialization
        ///
        frame.size.height = minimumHeight
    }


    // MARK: - Refresh Helpers
    fileprivate func refreshInterface() {
        refreshPlaceholder()
        refreshReplyButton()
        refreshSizeIfNeeded()
        refreshScrollPosition()
    }

    fileprivate func refreshSizeIfNeeded() {
        let newSize = intrinsicContentSize
        let oldSize = frame.size

        if newSize.height == oldSize.height {
            return
        }

        invalidateIntrinsicContentSize()
    }

    fileprivate func refreshPlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    fileprivate func refreshReplyButton() {
        let whitespaceCharSet = CharacterSet.whitespacesAndNewlines
        replyButton.isEnabled = textView.text.trimmingCharacters(in: whitespaceCharSet).isEmpty == false
        replyButton.tintColor = replyButton.isEnabled ? .accent : .listSmallIcon
    }

    fileprivate func refreshScrollPosition() {
        let selectedRangeStart = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect = textView.caretRect(for: selectedRangeStart)
        caretRect = caretRect.integral
        textView.scrollRectToVisible(caretRect, animated: false)
    }


    // MARK: - Private Properties
    fileprivate var bundle: NSArray?
    fileprivate var isExpanded: Bool = false
    fileprivate var viewSpacing: CGFloat = 8.0
    fileprivate var expandButtonExpandedYConstraint: NSLayoutConstraint!
    fileprivate var replyButtonExpandedYConstraint: NSLayoutConstraint!
    fileprivate var safeAreaHeight: CGFloat {
        if #available(iOS 11.0, *), let window = UIApplication.shared.keyWindow {
            return window.safeAreaInsets.top
        }
        return 0
    }

    // MARK: - IBOutlets
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton: UIButton!
    @IBOutlet private var separatorsView: SeparatorsView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var expandButton: UIButton!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var headerViewLabel: UILabel!
    // Constraints
    @IBOutlet private var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
}


// MARK: - Layout Calculated Properties
//
private extension ReplyTextView {

    /// Padding: TextView Margins (Top / Bottom) + TextView Constraints (Top / Bottom)
    ///
    var contentPadding: CGFloat {
        return textView.layoutMargins.top + textView.layoutMargins.bottom
    }

    /// Returns the Content Height (non capped).
    ///
    var contentHeight: CGFloat {
        return ceil(textView.contentSize.height) + contentPadding
    }

    /// Returns the current Font's LineHeight.
    ///
    var lineHeight: CGFloat {
        let lineHeight = textView.font?.lineHeight ?? Settings.defaultLineHeight
        return ceil(lineHeight)
    }

    /// Returns the Minimum component Height.
    ///
    var minimumHeight: CGFloat {
        return lineHeight + contentPadding
    }

    /// Returns the Maximum component Height.
    ///
    var maximumHeight: CGFloat {
        return lineHeight * CGFloat(maximumNumberOfVisibleLines) + contentPadding
    }
}


// MARK: - Settings
//
private extension ReplyTextView {

    enum Settings {

        /// Maximum number of *visible* lines
        ///
        static let maximumNumberOfVisibleLines = 5

        /// Default Line Height. Used as a safety measure, in case the actual font is not yet loaded.
        ///
        static let defaultLineHeight = CGFloat(21)
    }
}
