import UIKit
import WordPressUI

protocol CommentPlainTextEditorViewControllerDelegate: AnyObject {
    func commentPlainTextEditorViewController(_ viewController: CommentPlainTextEditorViewController, didChangeText text: String)
}

final class CommentPlainTextEditorViewController: UIViewController {
    var suggestionsViewModel: SuggestionsListViewModel?

    weak var delegate: CommentPlainTextEditorViewControllerDelegate?

    var text: String {
        set { textView.text = newValue }
        get { textView.text }
    }

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private var suggestionsView: SuggestionsTableView?

    // Static margin between the suggestions view and the text cursor position
    private let suggestionViewMargin: CGFloat = 5
    private var initialSuggestionsPosition: SuggestionsPosition = .hidden
    private var suggestionsTopAnchorConstraint: NSLayoutConstraint?
    private var didChangeText: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
        setupSuggestionsTableViewIfNeeded()

    }

    private func setupView() {
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(horizontal: 11, vertical: 16)
        textView.delegate = self
        textView.accessibilityIdentifier = "edit_comment_text_view"

        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.isHidden = !textView.text.isEmpty

        textView.addSubview(placeholderLabel)
        placeholderLabel.pinEdges([.leading, .top], insets: UIEdgeInsets(.all, 16))

        view.addSubview(textView)
        textView.pinEdges()
    }

    // MARK: - Suggestions

    private func setupSuggestionsTableViewIfNeeded() {
        guard let viewModel = suggestionsViewModel else {
            return
        }
        let suggestionsView = SuggestionsTableView(viewModel: viewModel, delegate: self)
        suggestionsView.useTransparentHeader = true
        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        self.suggestionsView = suggestionsView

        attachSuggestionsViewIfNeeded()
    }
}

extension CommentPlainTextEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.commentPlainTextEditorViewController(self, didChangeText: textView.text)
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

extension CommentPlainTextEditorViewController: SuggestionsTableViewDelegate {
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

private extension CommentPlainTextEditorViewController {

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

private enum SuggestionsPosition: Int {
    case hidden
    case top
    case bottom
}
