import Foundation
import WordPressShared.WPStyleGuide
import Gridicons

// MARK: - ReplyTextViewDelegate
//
@objc public protocol ReplyTextViewDelegate: UITextViewDelegate {
    @objc optional func textView(_ textView: UITextView, didTypeWord word: String)

    @objc optional func replyTextView(_ replyTextView: ReplyTextView, willEnterFullScreen controller: FullScreenCommentReplyViewController)
}


// MARK: - ReplyTextView
//
@objc open class ReplyTextView: UIView, UITextViewDelegate {
    private struct AnimationParameters {
        static let focusTransitionTime = TimeInterval(0.3)
        static let stateTransitionTime = TimeInterval(0.2)
    }

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

    // MARK: - UITextViewDelegate Methods
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    open func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
        transitionReplyButton()
    }

    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    open func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
        transitionReplyButton()
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

    @IBAction fileprivate func btnEnterFullscreenPressed(_ sender: Any) {
        guard let editViewController = FullScreenCommentReplyViewController.newEdit() else {
            return
        }

        guard let presenter = WPTabBarController.sharedInstance() else {
            return
        }


        // Inform any listeners
        let respondsToWillEnter = delegate?.responds(to: #selector(ReplyTextViewDelegate.replyTextView(_:willEnterFullScreen:))) ?? false

        if respondsToWillEnter {
            delegate?.replyTextView?(self, willEnterFullScreen: editViewController)
        }

        // Snapshot the first reponder status before presenting so we can restore it later
        let didHaveFirstResponder = textView.isFirstResponder

        editViewController.content = textView.text

        if #available(iOS 13.0, *) {
            editViewController.isModalInPresentation = true
        }

        editViewController.onExitFullscreen = { (shouldSave, updatedContent) in
            self.text = updatedContent

            // If the user was editing before they entered fullscreen, then restore that state
            // when they exit fullscreen but are not going to save
            if didHaveFirstResponder && shouldSave == false {
                // Delay the firstResponder switch for a small amount to bring the keyboard up
                // Slightly quicker and smoother
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    self.becomeFirstResponder()
                }
            }

            if shouldSave {
                self.btnReplyPressed()
            }

            //Dimiss the fullscreen view, once it has fully closed process the saving if needed
            presenter.dismiss(animated: true)
        }

        self.resignFirstResponder()

        let navController = LightNavigationController(rootViewController: editViewController)
        presenter.present(navController, animated: true)
    }

    // MARK: - Gestures Recognizers
    @objc open func backgroundWasTapped() {
        _ = becomeFirstResponder()
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
        // Force invalidate constraints
        invalidateIntrinsicContentSize()

        super.layoutSubviews()
    }

    // MARK: - Autolayout Helpers
    open override var intrinsicContentSize: CGSize {
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
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.backgroundColor = WPStyleGuide.Reply.textViewBackground
        textView.font = WPStyleGuide.Reply.textFont
        textView.textColor = WPStyleGuide.Reply.textColor
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.accessibilityIdentifier = "ReplyText"

        // Enable QuickType
        textView.autocorrectionType = .yes

        // Placeholder
        placeholderLabel.font = WPStyleGuide.Reply.textFont
        placeholderLabel.textColor = WPStyleGuide.Reply.placeholderColor

        // Fullscreen toggle button
        fullscreenToggleButton.setImage(.gridicon(.chevronUp), for: .normal)
        fullscreenToggleButton.tintColor = .listIcon
        fullscreenToggleButton.accessibilityLabel = NSLocalizedString("Enter Full Screen",
                                                                      comment: "Accessibility Label for the enter full screen button on the comment reply text view")


        // Reply
        let replyIcon = UIImage(named: "icon-comment-reply")
        replyButton.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.enabledColor), for: .normal)
        replyButton.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.disabledColor), for: .disabled)

        replyButton.isEnabled = false
        replyButton.accessibilityLabel = NSLocalizedString("Reply", comment: "Accessibility label for the reply button")

        transitionReplyButton(animated: false)

        // Background
        contentView.backgroundColor = WPStyleGuide.Reply.backgroundColor
        bezierContainerView.outerColor = WPStyleGuide.Reply.backgroundColor

        // Bezier
        bezierContainerView.bezierColor = WPStyleGuide.Reply.backgroundColor
        bezierContainerView.bezierFillColor = WPStyleGuide.Reply.textViewBackground
        bezierContainerView.translatesAutoresizingMaskIntoConstraints = false

        // Separators
        separatorsView.topColor = WPStyleGuide.Reply.separatorColor
        separatorsView.topVisible = true

        // Recognizers
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ReplyTextView.backgroundWasTapped))
        gestureRecognizers = [recognizer]

        /// Initial Sizing: Final step, since this depends on other control(s) initialization
        ///
        frame.size.height = minimumHeight
    }

    // MARK: - Refresh Helpers
    fileprivate func refreshInterface() {
        refreshPlaceholder()
        enableRefreshButtonIfNeeded()
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

    private func enableRefreshButtonIfNeeded() {
        let whitespaceCharSet = CharacterSet.whitespacesAndNewlines
        let isEnabled = self.textView.text.trimmingCharacters(in: whitespaceCharSet).isEmpty == false

        if isEnabled == self.replyButton.isEnabled {
            return
        }

        UIView.transition(with: replyButton as UIView,
                          duration: AnimationParameters.stateTransitionTime,
                          options: .transitionCrossDissolve,
                          animations: {
            self.replyButton.isEnabled = isEnabled
        })
    }

    fileprivate func refreshScrollPosition() {
        let selectedRangeStart = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect = textView.caretRect(for: selectedRangeStart)
        caretRect = caretRect.integral
        textView.scrollRectToVisible(caretRect, animated: false)
    }

    fileprivate func transitionReplyButton(animated: Bool = true) {
        replyButtonTrailingConstraint.constant = isFirstResponder ? 0.0 : -(frame.width * 2)

        let updateFrame = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: AnimationParameters.focusTransitionTime) {
                updateFrame()
            }
        }
        else {
            updateFrame()
        }
    }

    // MARK: - Private Properties
    fileprivate var bundle: NSArray?

    // MARK: - IBOutlets
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton: UIButton!
    @IBOutlet private var bezierContainerView: ReplyBezierView!
    @IBOutlet private var separatorsView: SeparatorsView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var bezierTopConstraint: NSLayoutConstraint!
    @IBOutlet private var bezierBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var replyButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fullscreenToggleButton: UIButton!
}


// MARK: - Layout Calculated Properties
//
private extension ReplyTextView {

    /// Padding: Bezier Margins (Top / Bottom) + Bezier Constraints (Top / Bottom)
    ///
    var contentPadding: CGFloat {
        return bezierContainerView.layoutMargins.top + bezierContainerView.layoutMargins.bottom
                + bezierTopConstraint.constant + bezierBottomConstraint.constant
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
        static let maximumNumberOfVisibleLines = 4

        /// Default Line Height. Used as a safety measure, in case the actual font is not yet loaded.
        ///
        static let defaultLineHeight = CGFloat(21)
    }
}
