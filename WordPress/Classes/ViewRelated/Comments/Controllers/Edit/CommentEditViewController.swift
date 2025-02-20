import UIKit
import WordPressUI

final class CommentEditViewController: UIViewController {
    private lazy var buttonSave = UIBarButtonItem(title: SharedStrings.Button.save, style: .done, target: self, action: #selector(buttonSaveTapped))
    private let editorVC = CommentEditorViewController()
    private let viewModel: CommentEditViewModel

    init(viewModel: CommentEditViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupView()
        setupNavigationBar()

        buttonSave.isEnabled = false
        isModalInPresentation = false
    }

    private func setupView() {
        editorVC.initialContent = viewModel.originalContent
        editorVC.isGutenbergEnabled = viewModel.isGutenbergEnabled
        editorVC.suggestionsViewModel = viewModel.suggestionsViewModel
        editorVC.delegate = self

        addChild(editorVC)
        view.addSubview(editorVC.view)
        editorVC.view.pinEdges()
        editorVC.didMove(toParent: self)
    }

    // MARK: - Actions

    @objc private func buttonSaveTapped() {
        setLoading(true)
        Task { @MainActor in
            do {
                let text = await editorVC.text
                try await viewModel.save(content: text)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                presentingViewController?.dismiss(animated: true)
            } catch {
                setLoading(false)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                Notice(error: error, title: Strings.failedToSave).post()
            }
        }
    }

    private func setLoading(_ isLoading: Bool) {
        navigationItem.rightBarButtonItem = isLoading ? .activityIndicator : buttonSave
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        editorVC.isEnabled = !isLoading
    }

    @objc private func buttonCancelTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        Task { @MainActor in
            let text = await editorVC.text
            navigationItem.leftBarButtonItem?.isEnabled = true
            if text == viewModel.originalContent {
                presentingViewController?.dismiss(animated: true)
            } else {
                showCloseConfirmationAlert()
            }
        }
    }

    private func showCloseConfirmationAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addCancelActionWithTitle(Strings.closeConfirmationAlertCancel)
        alert.addDestructiveActionWithTitle(Strings.closeConfirmationAlertDiscardChanges) { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Private

    private func setupNavigationBar() {
        title = Strings.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.cancel, style: .plain, target: self, action: #selector(buttonCancelTapped))

        navigationItem.rightBarButtonItem = buttonSave
    }

    private func didChangeText(_ text: String) {
        let hasChanges = text != viewModel.originalContent
        buttonSave.isEnabled = hasChanges
        isModalInPresentation = hasChanges
    }
}

extension CommentEditViewController: CommentEditorViewControllerDelegate {
    func commentEditor(_ viewController: CommentEditorViewController, didChangeText text: String) {
        didChangeText(text)
    }
}

private enum Strings {
    static let title = NSLocalizedString("commentEdit.navigationTitle", value: "Edit Comment", comment: "Navigation bar title when leaving a editing an existing comment")
    static let failedToSave = NSLocalizedString("commentEdit.failedToSaveComment", value: "Failed to save comment", comment: "Error title")
    static let closeConfirmationAlertCancel = NSLocalizedString("commentEdit.closeConfirmationAlert.keepEditing", value: "Keep Editing", comment: "Button to keep the changes in an alert confirming discaring changes")
    static let closeConfirmationAlertDiscardChanges = NSLocalizedString("commentEdit.closeConfirmationAlert.deleteDraft", value: "Discard Changes", comment: "Button in an alert confirming discaring a new draft")
}
