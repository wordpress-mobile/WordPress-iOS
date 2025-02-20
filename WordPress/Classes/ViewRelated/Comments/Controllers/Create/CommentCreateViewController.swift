import UIKit
import WordPressUI

final class CommentCreateViewController: UIViewController {
    private let buttonSend = UIButton(configuration: {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = Strings.send
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = UIColor.label
        configuration.baseForegroundColor = UIColor.systemBackground
        return configuration
    }())

    private let contentView = UIStackView(axis: .vertical, [])
    private let editorVC = CommentEditorViewController()
    private let viewModel: CommentCreateViewModel

    init(viewModel: CommentCreateViewModel) {
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
        setupAccessibility()

        didChangeText(editorVC.initialContent ?? "")
    }

    private func setupView() {
        view.addSubview(contentView)
        contentView.pinEdges([.top, .horizontal], to: view.safeAreaLayoutGuide)
        contentView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        if let comment = viewModel.replyToComment {
            let preview = CommentComposerReplyCommentView(comment: comment)
            contentView.addArrangedSubview(preview)

            let separator = SeparatorView.horizontal()
            contentView.addArrangedSubview(separator)
        }

        editorVC.initialContent = viewModel.restoreDraft()
        editorVC.placeholder = viewModel.placeholder
        editorVC.isGutenbergEnabled = viewModel.isGutenbergEnabled
        editorVC.suggestionsViewModel = viewModel.suggestionsViewModel
        editorVC.delegate = self

        addChild(editorVC)
        view.addSubview(editorVC.view)
        contentView.addArrangedSubview(editorVC.view)
        editorVC.didMove(toParent: self)
    }

    private func setupAccessibility() {
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "button_send_comment"
    }

    // MARK: - Actions

    @objc private func buttonSendTapped() {
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
                Notice(error: error, title: Strings.failedToSend).post()
            }
        }
    }

    private func setLoading(_ isLoading: Bool) {
        navigationItem.rightBarButtonItem = isLoading ? .activityIndicator : UIBarButtonItem(customView: buttonSend)
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        editorVC.isEnabled = !isLoading
    }

    @objc private func buttonCancelTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        Task { @MainActor in
            let text = await editorVC.text
            navigationItem.leftBarButtonItem?.isEnabled = true
            if text.isEmpty {
                presentingViewController?.dismiss(animated: true)
            } else {
                showCloseConfirmationAlert(content: text)
            }
        }
    }

    private func showCloseConfirmationAlert(content: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addCancelActionWithTitle(Strings.closeConfirmationAlertCancel)
        alert.addDestructiveActionWithTitle(Strings.closeConfirmationAlertDelete) { [weak self] _ in
            self?.viewModel.deleteDraft()
            self?.presentingViewController?.dismiss(animated: true)
        }
        if viewModel.canSaveDraft {
            alert.addActionWithTitle(Strings.closeConfirmationAlertSaveDraft, style: .default) { [weak self] _ in
                self?.viewModel.saveDraft(content)
                self?.presentingViewController?.dismiss(animated: true) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alert, animated: true, completion: nil)
    }

    private func setupNavigationBar() {
        title = viewModel.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.cancel, style: .plain, target: self, action: #selector(buttonCancelTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonSend)
        buttonSend.addTarget(self, action: #selector(buttonSendTapped), for: .primaryActionTriggered)
    }

    private func didChangeText(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEnabled = !text.isEmpty
        buttonSend.isEnabled = isEnabled
        isModalInPresentation = isEnabled
    }
}

extension CommentCreateViewController: CommentEditorViewControllerDelegate {
    func commentEditor(_ viewController: CommentEditorViewController, didChangeText text: String) {
        didChangeText(text)
    }
}

private enum Strings {
    static let send = NSLocalizedString("commentCreate.send", value: "Send", comment: "Navigation bar button title")
    static let failedToSend = NSLocalizedString("commentCreate.failedToSentComment", value: "Failed to send comment", comment: "Error title")
    static let closeConfirmationAlertCancel = NSLocalizedString("commentCreate.closeConfirmationAlert.keepEditing", value: "Keep Editing", comment: "Button to keep the changes in an alert confirming discaring changes")
    static let closeConfirmationAlertDelete = NSLocalizedString("commentCreate.closeConfirmationAlert.deleteDraft", value: "Delete Draft", comment: "Button in an alert confirming discaring a new draft")
    static let closeConfirmationAlertSaveDraft = NSLocalizedString("commentCreate.closeConfirmationAlert.saveDraft", value: "Save Draft", comment: "Button in an alert confirming saving a new draft")
}
