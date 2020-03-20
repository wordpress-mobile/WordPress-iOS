import UIKit
import Gridicons

/// FullscreenCommentReplyViewController is used when full screen commenting
/// After instantiating using `newEdit()` the class expects the `content` and `onExitFullscreen`
/// properties to be set.


/// Keeps track of the position of the suggestions view
fileprivate enum SuggestionsPosition: Int {
    case hidden
    case top
    case bottom
}

public class FullScreenCommentReplyViewController: EditCommentViewController, SuggestionsTableViewDelegate {
    private struct Parameters {
        /// Determines the size of the replyButton
        static let replyButtonIconSize = CGSize(width: 21, height: 18)

        // Static margin between the suggestions view and the text cursor position
        static let suggestionViewMargin: CGFloat = 5
    }

    /// The completion block that is called when the view is exiting fullscreen
    /// - Parameter: Bool, whether or not the calling view should trigger a save
    /// - Parameter: String, the updated comment content
    public var onExitFullscreen: ((Bool, String) -> ())?

    /// The save/reply button that is displayed in the rightBarButtonItem position
    private(set) var replyButton: UIButton!

    /// Reply Suggestions
    ///
    private var siteID: NSNumber?
    private var suggestionsTableView: SuggestionsTableView?

    // MARK: - View Methods
    public override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Comment", comment: "User facing, navigation bar title")

        setupReplyButton()
        setupNavigationItems()
        configureAppearance()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        enableRefreshButtonIfNeeded(animated: false)

        setupSuggestionsTableViewIfNeeded()
    }

    // MARK: - Public Methods

    /// Enables the @ mention suggestions while editing
    /// - Parameter siteID: The ID of the site to determine if suggestions are enabled or not
    @objc func enableSuggestions(with siteID: NSNumber) {
        self.siteID = siteID
    }

    /// Description
    private func setupSuggestionsTableViewIfNeeded() {
        guard shouldShowSuggestions else {
            return
        }

        let tableView = SuggestionsTableView()
        tableView.siteID = siteID
        tableView.suggestionsDelegate = self
        tableView.useTransparentHeader = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        suggestionsTableView = tableView

        attachSuggestionsViewIfNeeded()
    }

    // MARK: - UITextViewDelegate
    public override func textViewDidBeginEditing(_ textView: UITextView) { }
    public override func textViewDidEndEditing(_ textView: UITextView) { }

    public override func contentDidChange() {
        enableRefreshButtonIfNeeded()
    }

    public override func textViewDidChangeSelection(_ textView: UITextView) {
        if didChangeText {
            //If the didChangeText flag is true, reset it here
            didChangeText = false
            return
        }

        //If the user just changes the selection, then hide the suggestions
        suggestionsTableView?.hideSuggestions()
    }


    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard shouldShowSuggestions else {
            return true
        }

        let textViewText: NSString = textView.text as NSString
        let prerange = NSMakeRange(0, range.location)
        let pretext = textViewText.substring(with: prerange) + text
        let words = pretext.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let lastWord: NSString = words.last! as NSString

        didTypeWord(lastWord as String)

        didChangeText = true
        return true
    }

    private func didTypeWord(_ word: String) {
        guard let tableView = suggestionsTableView else {
            return
        }

        tableView.showSuggestions(forWord: word)
    }

    // MARK: - Actions
    @objc func btnSavePressed() {
        exitFullscreen(shouldSave: true)
    }

    @objc func btnExitFullscreenPressed() {
        exitFullscreen(shouldSave: false)
    }

    // MARK: - Private: Helpers

    /// Updates the iOS 13 title color
    private func configureAppearance() {
        if #available(iOS 13.0, *) {
            guard let navigationBar = navigationController?.navigationBar else {
                return
            }

            navigationBar.standardAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.text
            ]
        }
    }

    /// Creates the `replyButton` to be used as the `rightBarButtonItem`
    private func setupReplyButton() {
        replyButton = {
            let iconSize = Parameters.replyButtonIconSize
            let replyIcon = UIImage(named: "icon-comment-reply")

            let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: iconSize))
            button.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.enabledColor), for: .normal)
            button.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.disabledColor), for: .disabled)
            button.accessibilityLabel = NSLocalizedString("Reply", comment: "Accessibility label for the reply button")
            button.isEnabled = false
            button.addTarget(self, action: #selector(btnSavePressed), for: .touchUpInside)

            return button
        }()
    }

    /// Creates the `leftBarButtonItem` and the `rightBarButtonItem`
    private func setupNavigationItems() {
        navigationItem.leftBarButtonItem = ({
            let image = UIImage.gridicon(.chevronDown).imageWithTintColor(.listIcon)
            let leftItem = UIBarButtonItem(image: image,
                                           style: .plain,
                                           target: self,
                                           action: #selector(btnExitFullscreenPressed))

            leftItem.accessibilityLabel = NSLocalizedString("Exit Full Screen",
                                                            comment: "Accessibility Label for the exit full screen button on the full screen comment reply mode")
            return leftItem
        })()

        navigationItem.rightBarButtonItem = ({
            let rightItem = UIBarButtonItem(customView: replyButton)

            if let customView = rightItem.customView {
                let iconSize = Parameters.replyButtonIconSize

                customView.widthAnchor.constraint(equalToConstant: iconSize.width).isActive = true
                customView.heightAnchor.constraint(equalToConstant: iconSize.height).isActive = true
            }

            return rightItem
        })()
    }

    /// Changes the `refreshButton` enabled state
    /// - Parameter animated: Whether or not the state change should be animated
    fileprivate func enableRefreshButtonIfNeeded(animated: Bool = true) {
        let whitespaceCharSet = CharacterSet.whitespacesAndNewlines
        let isEnabled = textView.text.trimmingCharacters(in: whitespaceCharSet).isEmpty == false

        if isEnabled == replyButton.isEnabled {
            return
        }

        let setEnabled = {
            self.replyButton.isEnabled = isEnabled
        }

        if animated == false {
            setEnabled()
            return
        }

        UIView.transition(with: replyButton as UIView,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: {
                            setEnabled()
        })
    }

    /// Triggers the `onExitFullscreen` completion handler
    /// - Parameter shouldSave: Whether or not the updated text should trigger a save
    private func exitFullscreen(shouldSave: Bool) {
        guard let completion = onExitFullscreen else {
            return
        }

        let updatedText = textView.text ?? ""

        completion(shouldSave, updatedText)
    }

    var suggestionsTop: NSLayoutConstraint!
    var suggestionsBottom: NSLayoutConstraint!

    fileprivate var initialSuggestionsPosition: SuggestionsPosition = .hidden
    fileprivate var didChangeText: Bool = false
}

// MARK: - SuggestionsTableViewDelegate
//
public extension FullScreenCommentReplyViewController {
    func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replaceTextAtCaret(text as NSString?, withText: suggestion)
        suggestionsTableView.showSuggestions(forWord: String())
    }

    func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didChangeTableBounds bounds: CGRect) {
        if suggestionsTableView.isHidden {
            self.initialSuggestionsPosition = .hidden
        } else {
            self.repositionSuggestions()
        }
    }

    func suggestionsTableViewMaxDisplayedRows(_ suggestionsTableView: SuggestionsTableView) -> Int {
        return 3
    }

    override func handleKeyboardDidShow(_ notification: Foundation.Notification?) {
        super.handleKeyboardDidShow(notification)

        self.initialSuggestionsPosition = .hidden
        self.repositionSuggestions()
    }

    override func handleKeyboardWillHide(_ notification: Foundation.Notification?) {
        super.handleKeyboardWillHide(notification)

        self.initialSuggestionsPosition = .hidden
        self.repositionSuggestions()
    }
}

// MARK: - Suggestions View Helpers
//
private extension FullScreenCommentReplyViewController {

    /// Calculates a CGRect for the text caret and converts its value to the view's coordindate system
    var absoluteTextCursorRect: CGRect {
        let selectedRangeStart = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect = textView.caretRect(for: selectedRangeStart)
        caretRect = textView.convert(caretRect, to: view)

        return caretRect.integral
    }

    func repositionSuggestions() {
        guard let suggestions = suggestionsTableView else {
            return
        }

        let caretRect = absoluteTextCursorRect
        let margin = Parameters.suggestionViewMargin
        let suggestionsHeight = suggestions.frame.height


        // Calculates the height of the view minus the keyboard if its visible
        let calculatedViewHeight = (view.frame.height - keyboardFrame.height)

        var position: SuggestionsPosition = .bottom

        // Calculates the direction the suggestions view should appear
        // And the global position

        // If the estimated position of the suggestion will appear below the bottom of the view
        // then display it in the top position
        if (caretRect.maxY + suggestionsHeight) > calculatedViewHeight {
            position = .top
        }

        // If the user is typing we don't want to change the position of the suggestions view
        if position == initialSuggestionsPosition || initialSuggestionsPosition == .hidden {
            initialSuggestionsPosition = position
        }

        var constant: CGFloat = 0

        switch initialSuggestionsPosition {
        case .top:
            constant = (caretRect.minY - suggestionsHeight - margin)

        case .bottom:
            constant = caretRect.maxY + margin

        case .hidden:
            constant = 0
        }

        suggestionsTop.constant = constant
    }

    func attachSuggestionsViewIfNeeded() {
        guard let tableView = suggestionsTableView else {
            return
        }

        guard shouldShowSuggestions else {
            tableView.removeFromSuperview()
            return
        }

        // We're adding directly to the navigation controller view to allow the suggestions to appear
        // above the nav bar, this only happens on smaller screens when the keyboard is open
        navigationController?.view.addSubview(tableView)

        suggestionsTop = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTop,
        ])
    }


    /// Determine if suggestions are enabled and visible for this site
    var shouldShowSuggestions: Bool {
        guard let siteID = self.siteID else {
            return false
        }

        return SuggestionService.sharedInstance().shouldShowSuggestions(forSiteID: siteID)
    }

    // This should be moved elsewhere
    func replaceTextAtCaret(_ text: NSString?, withText replacement: String?) {
        guard let replacementText = replacement,
              let textToReplace = text,
              let selectedRange = textView.selectedTextRange,
              let newPosition = textView.position(from: selectedRange.start, offset: -textToReplace.length),
              let newRange = textView.textRange(from: newPosition, to: selectedRange.start) else {
            return
        }

        textView.replace(newRange, withText: replacementText)
    }

}
