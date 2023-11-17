import Foundation

final class SubmitFeedbackViewController: UIViewController {

    // MARK: - Views

    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = WPStyleGuide.fontForTextStyle(.body)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .init(allEdges: Length.Padding.double)
        return textView
    }()

    // MARK: - Properties

    private(set) var feedbackWasSubmitted = false

    var onFeedbackSubmitted: ((SubmitFeedbackViewController, String) -> Void)?

    // MARK: - View Lifecycle

    deinit {
        guard !feedbackWasSubmitted else {
            return
        }
        WPAnalytics.track(.appReviewsCanceledFeedbackScreen)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.setupSubviews()
        WPAnalytics.track(.appReviewsOpenedFeedbackScreen)
    }

    private func setupSubviews() {
        self.setupNavigationItems()
        self.setupTextView()
    }

    private func setupNavigationItems() {
        let navBarAppearance = self.navigationController?.navigationBar.standardAppearance
        let submit = UIAction { [weak self] _ in
            self?.didTapSubmit()
        }
        let cancel = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        self.navigationItem.rightBarButtonItem = .init(title: Strings.submit, primaryAction: submit)
        self.navigationItem.leftBarButtonItem = .init(systemItem: .cancel, primaryAction: cancel)
        self.navigationItem.title = Strings.title
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
        self.navigationItem.compactScrollEdgeAppearance = navBarAppearance
    }

    private func setupTextView() {
        self.view.addSubview(textView)
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: view.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    // MARK: - User Interaction

    private func didTapSubmit() {
        let text = textView.text ?? ""
        self.onFeedbackSubmitted?(self, text)
        self.feedbackWasSubmitted = true
        WPAnalytics.track(.appReviewsSentFeedback, withProperties: ["feedback": text])
        self.dismiss(animated: true)
    }
}

// MARK: - Strings

private extension SubmitFeedbackViewController {

    enum Strings {
        static let submit = NSLocalizedString(
            "submit.feedback.submit.button",
            value: "Submit",
            comment: ""
        )
        static let title = NSLocalizedString(
            "submit.feedback.title",
            value: "Feedback",
            comment: ""
        )
    }
}
