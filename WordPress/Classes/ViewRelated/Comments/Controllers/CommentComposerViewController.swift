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
        configuration.baseBackgroundColor = UIColor.label
        configuration.baseForegroundColor = UIColor.systemBackground
        return configuration
    }())

    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private var suggestionsView: SuggestionsTableView?

    private let viewModel: CommentComposerViewModel

    // Static margin between the suggestions view and the text cursor position
    private let suggestionViewMargin: CGFloat = 5
    private var initialSuggestionsPosition: SuggestionsPosition = .hidden
    private var suggestionsTopAnchorConstraint: NSLayoutConstraint?
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
        setupAccessibility()

        updateInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
        setupSuggestionsTableViewIfNeeded()

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
        textView.pinEdges([.top, .horizontal], to: view.safeAreaLayoutGuide)
        textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
    }

    private func setupAccessibility() {
        textView.accessibilityIdentifier = "edit_comment_text_view"
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "button_send_comment"
    }

    // MARK: - Suggestions

    private func setupSuggestionsTableViewIfNeeded() {
        guard let viewModel = viewModel.suggestionsViewModel else {
            return
        }
        let suggestionsView = SuggestionsTableView(viewModel: viewModel, delegate: self)
        suggestionsView.useTransparentHeader = true
        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        self.suggestionsView = suggestionsView

        attachSuggestionsViewIfNeeded()
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
            try await viewModel.save(textView.text ?? "")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            presentingViewController?.dismiss(animated: true)
        } catch {
            setLoading(false)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            Notice(title: Strings.failedToSend, message: error.localizedDescription.stringByDecodingXMLCharacters()).post()
        }
    }

    private func setLoading(_ isLoading: Bool) {
        navigationItem.rightBarButtonItem = isLoading ? .activityIndicator : UIBarButtonItem(customView: buttonSend)
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
        // TODO: (kean) implement draft saving
//        alert.addActionWithTitle(Strings.closeConfirmationAlertSaveDraft, style: .default) { _ in
//
//        }
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Private

    private func setupNavigationBar() {
        title = viewModel.navigationTitle

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.cancel, style: .plain, target: self, action: #selector(buttonCancelTapped))

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
            didChangeText = false
            return
        }
        suggestionsView?.hideSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard suggestionsView != nil else {
            return true
        }
        let textViewText: NSString = textView.text as NSString
        let prerange = NSMakeRange(0, range.location)
        let pretext = textViewText.substring(with: prerange) + text
        let words = pretext.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let lastWord: NSString = words.last! as NSString

        suggestionsView?.showSuggestions(forWord: lastWord as String)
        didChangeText = true

        return true
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
        guard let suggestions = suggestionsView else {
            return
        }

        let caretRect = absoluteTextCursorRect
        let margin = suggestionViewMargin
        let suggestionsHeight = suggestions.frame.height

        // Calculates the height of the view minus the keyboard if its visible
        let calculatedViewHeight = textView.bounds.height

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

        suggestionsTopAnchorConstraint?.constant = constant
    }

    func attachSuggestionsViewIfNeeded() {
        guard let suggestionsView else {
            return
        }
        // We're adding directly to the navigation controller view to allow the suggestions to appear
        // above the nav bar, this only happens on smaller screens when the keyboard is open
        navigationController?.view.addSubview(suggestionsView)

        suggestionsTopAnchorConstraint = suggestionsView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)

        NSLayoutConstraint.activate([
            suggestionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTopAnchorConstraint!,
        ])
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
