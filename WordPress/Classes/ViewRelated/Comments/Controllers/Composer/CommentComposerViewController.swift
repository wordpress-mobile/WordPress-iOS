import UIKit
import WordPressUI

final class CommentComposerViewController: UIViewController {
    private let buttonSend = UIButton(configuration: {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = Strings.send
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = UIColor.label
        configuration.baseForegroundColor = UIColor.systemBackground
        return configuration
    }())

    private let contentView = UIStackView(axis: .vertical, [])
    private var editor: CommentEditor?
    private let viewModel: CommentComposerViewModel

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

        setupView()
        setupNavigationBar()
        setupAccessibility()

        updateInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.commentFullScreenEntered)
    }

    private func setupView() {
        view.addSubview(contentView)
        contentView.pinEdges([.top, .horizontal], to: view.safeAreaLayoutGuide)
        contentView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        if let comment = viewModel.comment {
            let preview = CommentComposerReplyCommentView(comment: comment)
            contentView.addArrangedSubview(preview)

            let separator = SeparatorView.horizontal()
            contentView.addArrangedSubview(separator)
        }

        setupEditor()
    }

    private func setupEditor() {
        if viewModel.isGutenbergEnabled {
            setupGutenbergEditor()
        } else {
            setupPlainTextEditor()
        }
    }

    private func setupPlainTextEditor() {
        let editorVC = CommentPlainTextEditorViewController()
        editorVC.suggestionsViewModel = viewModel.suggestionsViewModel
        editorVC.placeholder = viewModel.placeholder
        editorVC.delegate = self

        addChild(editorVC)
        contentView.addArrangedSubview(editorVC.view)
        editorVC.didMove(toParent: self)

        self.editor = editorVC
    }

    private func setupGutenbergEditor() {
        let editorVC = CommentGutenbergEditorViewController()
        editorVC.delegate = self

        addChild(editorVC)
        contentView.addArrangedSubview(editorVC.view)
        editorVC.didMove(toParent: self)

        self.editor = editorVC
    }

    private func setupAccessibility() {
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "button_send_comment"
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
            try await viewModel.save(text)
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
        editor?.isEnabled = !isLoading
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
        editor?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

extension CommentComposerViewController: CommentEditorDelegate {
    func commentEditor(_ viewController: UIViewController, didUpateText text: String) {
        updateInterface()
    }
}

private enum Strings {
    static let send = NSLocalizedString("commentComposer.send", value: "Send", comment: "Navigation bar button title")
    static let failedToSend = NSLocalizedString("commentComposer.failedToSentComment", value: "Failed to send comment", comment: "Error title")
    static let closeConfirmationAlertCancel = NSLocalizedString("commentComposer.closeConfirmationAlert.keepEditing", value: "Keep Editing", comment: "Button to keep the changes in an alert confirming discaring changes")
    static let closeConfirmationAlertDelete = NSLocalizedString("commentComposer.closeConfirmationAlert.deleteDraft", value: "Delete Draft", comment: "Button in an alert confirming discaring a new draft")
    static let closeConfirmationAlertSaveDraft = NSLocalizedString("commentComposer.closeConfirmationAlert.saveDraft", value: "Save Draft", comment: "Button in an alert confirming saving a new draft")
}
