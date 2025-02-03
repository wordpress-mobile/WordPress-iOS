import UIKit
import WordPressUI

fileprivate enum SuggestionsPosition: Int {
    case hidden
    case top
    case bottom
}

final class CommentComposerViewController: UIViewController {
    private let buttonSend = UIButton(configuration: {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = Strings.send
        configuration.cornerStyle = .capsule
        return configuration
    }())

    private let textView = UITextView()
    private let placeholderLabel = UILabel()

    // Suggestions
    private var siteID: NSNumber?
    private var prominentSuggestionsIds: [NSNumber]?
    private var suggestionsTableView: SuggestionsTableView?
    private var searchText: String?

    private let viewModel: CommentComposerViewModel

    // Static margin between the suggestions view and the text cursor position
    private let suggestionViewMargin: CGFloat = 5
    private var initialSuggestionsPosition: SuggestionsPosition = .hidden
    private var suggestionsTop: NSLayoutConstraint!
    private var didChangeText: Bool = false

    init(viewModel: CommentComposerViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupTextView()
        setupNavigationBar()

        updateInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
        setupSuggestionsTableViewIfNeeded()
        showSuggestionsViewIfNeeded()

        WPAnalytics.track(.commentFullScreenEntered)
    }

    private func setupTextView() {
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(horizontal: 11, vertical: 16)
        textView.delegate = self

        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        placeholderLabel.text = viewModel.placeholder
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.isHidden = !textView.text.isEmpty

        textView.addSubview(placeholderLabel)
        placeholderLabel.pinEdges([.leading, .top], insets: UIEdgeInsets(.all, 16))

        view.addSubview(textView)
        textView.pinEdges([.top, .horizontal])
        textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
    }

    // MARK: - Suggestions

    /// Enables the @ mention suggestions while editing
    /// - Parameter siteID: The ID of the site to determine if suggestions are enabled or not
    /// - Parameter prominentSuggestionsIds: The suggestions ids to display at the top of the suggestions list.
    /// - Parameter searchText: The last search text used to show the suggestions list.
    @objc func enableSuggestions(with siteID: NSNumber, prominentSuggestionsIds: [NSNumber]?, searchText: String?) {
        self.siteID = siteID
        self.prominentSuggestionsIds = prominentSuggestionsIds
        self.searchText = searchText
    }

    private func setupSuggestionsTableViewIfNeeded() {
        guard let siteID, shouldShowSuggestions else {
            return
        }
        suggestionsTableView = viewModel.suggestionsTableView(
            with: siteID,
            useTransparentHeader: true,
            prominentSuggestionsIds: prominentSuggestionsIds,
            delegate: self
        )
        attachSuggestionsViewIfNeeded()
    }

    private func showSuggestionsViewIfNeeded() {
        guard let searchText, !searchText.isEmpty else {
            return
        }
        suggestionsTableView?.showSuggestions(forWord: searchText)
    }

    // MARK: - Actions

    @objc private func buttonSendTapped() {
        Task {
            await sendComment()
        }
    }

    @MainActor
    private func sendComment() async {
        do {
            setLoading(true)
            try await viewModel.send(comment: textView.text ?? "")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            presentingViewController?.dismiss(animated: true)
        } catch {
            setLoading(false)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            Notice(title: Strings.failedToSend, message: error.localizedDescription.stringByDecodingXMLCharacters()).post()
        }
    }

    private func setLoading(_ isLoading: Bool) {
        buttonSend.configuration?.showsActivityIndicator = isLoading
        buttonSend.configuration?.title = isLoading ? nil : Strings.send
        buttonSend.isEnabled = isLoading
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonSend) // Update layout
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        textView.resignFirstResponder()
        textView.alpha = isLoading ? 0.5 : 1.0
        textView.isUserInteractionEnabled = !isLoading
    }

    @objc private func buttonCancelTapped() {
        if text.isEmpty {
            presentingViewController?.dismiss(animated: true)
        } else {
            showCloseDraftConfirmationAlert()
        }
    }

    private func showCloseDraftConfirmationAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addCancelActionWithTitle(Strings.closeConfirmationAlertCancel)
        alert.addDestructiveActionWithTitle(Strings.closeConfirmationAlertDelete) { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }
        alert.addActionWithTitle(Strings.closeConfirmationAlertSaveDraft, style: .default) { _ in
            // TODO: (kean) implement draft saving
        }
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Private

    private func setupNavigationBar() {
        title = viewModel.navigationTitle

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.cancel, style: .plain, target: self, action: #selector(buttonCancelTapped))

        buttonSend.heightAnchor.constraint(equalToConstant: 36).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonSend)
        buttonSend.addTarget(self, action: #selector(buttonSendTapped), for: .primaryActionTriggered)
    }

    /// Changes the `refreshButton` enabled state
    private func updateInterface() {
        let isEmpty = text.isEmpty
        buttonSend.isEnabled = !isEmpty
        isModalInPresentation = !isEmpty
    }

    private var text: String {
        textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension CommentComposerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty

        updateInterface()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if didChangeText {
            //If the didChangeText flag is true, reset it here
            didChangeText = false
            return
        }

        //If the user just changes the selection, then hide the suggestions
        suggestionsTableView?.hideSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
}

extension CommentComposerViewController: SuggestionsTableViewDelegate {
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
}

// MARK: - Suggestions View Helpers
//
private extension CommentComposerViewController {

    /// Calculates a CGRect for the text caret and converts its value to the view's coordindate system
    var absoluteTextCursorRect: CGRect {
        let selectedRangeStart = textView.selectedTextRange?.start ?? UITextPosition()
        var caretRect = textView.caretRect(for: selectedRangeStart)
        caretRect = textView.convert(caretRect, to: view)

        return caretRect.integral
    }

    func repositionSuggestions() {
        // TODO: (kean) reimplement
//        guard let suggestions = suggestionsTableView else {
//            return
//        }
//
//        let caretRect = absoluteTextCursorRect
//        let margin = suggestionViewMargin
//        let suggestionsHeight = suggestions.frame.height
//
//        // Calculates the height of the view minus the keyboard if its visible
//        let calculatedViewHeight = (view.frame.height - keyboardFrame.height)
//
//        var position: SuggestionsPosition = .bottom
//
//        // Calculates the direction the suggestions view should appear
//        // And the global position
//
//        // If the estimated position of the suggestion will appear below the bottom of the view
//        // then display it in the top position
//        if (caretRect.maxY + suggestionsHeight) > calculatedViewHeight {
//            position = .top
//        }
//
//        // If the user is typing we don't want to change the position of the suggestions view
//        if position == initialSuggestionsPosition || initialSuggestionsPosition == .hidden {
//            initialSuggestionsPosition = position
//        }
//
//        var constant: CGFloat = 0
//
//        switch initialSuggestionsPosition {
//        case .top:
//            constant = (caretRect.minY - suggestionsHeight - margin)
//
//        case .bottom:
//            constant = caretRect.maxY + margin
//
//        case .hidden:
//            constant = 0
//        }
//
//        suggestionsTop.constant = constant
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
        return viewModel.shouldShowSuggestions(with: siteID)
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

private enum Strings {
    static let send = NSLocalizedString("commentComposer.send", value: "Send", comment: "Navigation bar button title")
    static let failedToSend = NSLocalizedString("commentComposer.failedToSentComment", value: "Failed to send comment", comment: "Error title")
    static let closeConfirmationAlertCancel = NSLocalizedString("commentComposer.closeConfirmationAlert.keepEditing", value: "Keep Editing", comment: "Button to keep the changes in an alert confirming discaring changes")
    static let closeConfirmationAlertDelete = NSLocalizedString("commentComposer.closeConfirmationAlert.deleteDraft", value: "Delete Draft", comment: "Button in an alert confirming discaring a new draft")
    static let closeConfirmationAlertSaveDraft = NSLocalizedString("commentComposer.closeConfirmationAlert.saveDraft", value: "Save Draft", comment: "Button in an alert confirming saving a new draft")
}
