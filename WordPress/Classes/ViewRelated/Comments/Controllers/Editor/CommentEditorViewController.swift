import UIKit
import WordPressUI

protocol CommentEditorViewControllerDelegate: AnyObject {
    func commentEditor(_ viewController: CommentEditorViewController, didChangeText text: String)
}

/// Manages the editor area of the comment create/edit screens. Supports both
/// plain text and Gutenberg.
final class CommentEditorViewController: UIViewController {
    // Configuration
    var initialContent: String?
    var isGutenbergEnabled = false
    var placeholder: String?
    var suggestionsViewModel: SuggestionsListViewModel?
    weak var delegate: CommentEditorViewControllerDelegate?

    let contentView = UIStackView(axis: .vertical, [])

    private(set) var editorVC: UIViewController?

    var isEnabled = true {
        didSet {
            view.alpha = isEnabled ? 1.0 : 0.5
            view.isUserInteractionEnabled = isEnabled
        }
    }

    /// - note: The method is asynchronous because Gutenberg requires a relatively
    /// expensive deserialization that doesn't happen interactively.
    var text: String {
        get async {
            if let editorVC = editorVC as? CommentPlainTextEditorViewController {
                return editorVC.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let editorVC = editorVC as? CommentGutenbergEditorViewController {
                return await editorVC.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(contentView)
        contentView.pinEdges([.top, .horizontal], to: view.safeAreaLayoutGuide)
        contentView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        setupEditor()

        WPAnalytics.track(.commentFullScreenEntered)
    }

    private func setupEditor() {
        if isGutenbergEnabled {
            setupGutenbergEditor()
        } else {
            setupPlainTextEditor()
        }
    }

    private func setupPlainTextEditor() {
        let editorVC = CommentPlainTextEditorViewController()
        editorVC.suggestionsViewModel = suggestionsViewModel
        editorVC.placeholder = placeholder
        editorVC.text = initialContent ?? ""
        editorVC.delegate = self

        addChild(editorVC)
        contentView.addArrangedSubview(editorVC.view)
        editorVC.didMove(toParent: self)

        self.editorVC = editorVC
    }

    private func setupGutenbergEditor() {
        let editorVC = CommentGutenbergEditorViewController()
        editorVC.delegate = self
        editorVC.initialContent = initialContent ?? ""

        addChild(editorVC)
        contentView.addArrangedSubview(editorVC.view)
        editorVC.didMove(toParent: self)

        self.editorVC = editorVC
    }
}

extension CommentEditorViewController: CommentPlainTextEditorViewControllerDelegate {
    func commentPlainTextEditorViewController(_ viewController: CommentPlainTextEditorViewController, didChangeText text: String) {
        delegate?.commentEditor(self, didChangeText: text)
    }
}

extension CommentEditorViewController: CommentGutenbergEditorViewControllerDelegate {
    func commentGutenbergEditorViewController(_ viewController: CommentGutenbergEditorViewController, didChangeText text: String) {
        delegate?.commentEditor(self, didChangeText: text)
    }
}
