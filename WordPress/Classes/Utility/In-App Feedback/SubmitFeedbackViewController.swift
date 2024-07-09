import Foundation
import SwiftUI
import WordPressShared

final class SubmitFeedbackViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = UIHostingController(rootView: SubmitFeedbackView(presentingViewController: self))
        viewController.configureDefaultNavigationBarAppearance()

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.isTranslucent = true // Reset to default

        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(navigationController.view)
        navigationController.didMove(toParent: self)
    }
}

private struct SubmitFeedbackView: View {
    weak var presentingViewController: UIViewController?

    @State private var subject = ""
    @State private var text = ""
    @State private var isProcessing = false
    @State private var isShowingCancellationConfirmation = false

    @FocusState private var isSubjectFieldFocused: Bool

    private let textLimit = 500

    var isInputEmpty: Bool {
        text.trim().isEmpty && subject.trim().isEmpty
    }

    var body: some View {
        Form {
            Section(header: Spacer(minLength: 0)) {
                TextField(Strings.subject, text: $subject)
                    .focused($isSubjectFieldFocused)
            }
            Section {
                TextEditor(text: $text)
                    .frame(height: 170)
                    .accessibilityLabel(Strings.details)
            } header: {
                Text(Strings.details)
            } footer: {
                HStack {
                    Spacer()
                    Text(max(0, textLimit - text.count).description)
                        .monospacedDigit()
                        .foregroundStyle(text.count >= textLimit ? .red : .secondary)
                }
            }
        }
        .listSectionCompactSpacing()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.cancel) {
                    if isInputEmpty {
                        dismiss()
                    } else {
                        isShowingCancellationConfirmation = true
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                if isProcessing {
                    ProgressView()
                } else {
                    Button(Strings.submit, action: submit)
                        .disabled(isInputEmpty)
                }
            }
        }
        .onAppear {
            WPAnalytics.track(.appReviewsOpenedFeedbackScreen)
            isSubjectFieldFocused = true
        }
        .disabled(isProcessing)
        .confirmationDialog(Strings.cancellationAlertTitle, isPresented: $isShowingCancellationConfirmation) {
            Button(Strings.cancellationAlertContinueEditing, role: .cancel) {}
            Button(Strings.cancellationAlertDiscardFeedbackButton, role: .destructive) {
                dismiss()
            }
        }
        .onChange(of: isInputEmpty) {
            presentingViewController?.isModalInPresentation = !$0
        }
        .onChange(of: text) { text in
            if text.count > textLimit {
                self.text = String(text.prefix(textLimit))
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        wpAssert(!text.isEmpty)

        guard let presentingViewController else {
            return wpAssertionFailure("presentingViewController missing")
        }

        isProcessing = true

        let subject = subject.trim().nonEmptyString()
        let text = text.trim()
        let tags = ["appreview_jetpack", "in_app_feedback"]

        let identityAlertOptions = ZendeskUtils.IdentityAlertOptions(
            optionalIdentity: true,
            includesName: true,
            title: Strings.identityAlertTitle,
            message: Strings.identityAlertDescription,
            submit: Strings.identityAlertSubmit,
            cancel: nil,
            emailPlaceholder: Strings.identityAlertEmptyEmail,
            namePlaceholder: Strings.identityAlertEmptyName
        )

        ZendeskUtils.sharedInstance.createNewRequest(
            in: presentingViewController,
            subject: subject,
            description: text,
            tags: tags,
            alertOptions: identityAlertOptions
        ) { result in
            DispatchQueue.main.async {
                didSubmitFeedback(with: result.map { _ in () })
            }
        }
    }

    private func didSubmitFeedback(with result: Result<Void, ZendeskRequestError>) {
        switch result {
        case .success:
            WPAnalytics.track(.appReviewsSentFeedback, withProperties: ["feedback": text])

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let notice = Notice(title: Strings.successNoticeTitle, message: Strings.successNoticeMessage)
            ActionDispatcherFacade().dispatch(NoticeAction.post(notice))

            dismiss()
        case .failure(let error):
            DDLogError("Submitting feedback failed: \(error)")

            UINotificationFeedbackGenerator().notificationOccurred(.error)
            WPError.showAlert(withTitle: Strings.failureAlertTitle, message: error.localizedDescription)
            isProcessing = false
        }
    }

    private func dismiss() {
        presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
}

private enum Strings {
    static let cancel = NSLocalizedString("submit.feedback.buttonCancel", value: "Cancel", comment: "The button title for the Cancel button in the In-App Feedback screen")
    static let submit = NSLocalizedString("submit.feedback.submit.button", value: "Submit", comment: "The button title for the Submit button in the In-App Feedback screen")
    static let title = NSLocalizedString("submit.feedback.title", value: "Feedback", comment: "The title for the the In-App Feedback screen")
    static let subject = NSLocalizedString("submit.feedback.subjectPlaceholder", value: "Subject", comment: "The section title and or placeholder")
    static let details = NSLocalizedString("submit.feedback.subjectPlaceholder", value: "Details", comment: "The section title and or placeholder")

    static let identityAlertTitle = NSLocalizedString("submit.feedback.alert.title", value: "Thanks for your feedback", comment: "Alert users are shown when submtiting their feedback.")
    static let identityAlertDescription = NSLocalizedString("submit.feedback.alert.description", value: "You can optionally include your email and username to help us understand your experience.", comment: "Alert users are shown when submtiting their feedback.")
    static let identityAlertSubmit = NSLocalizedString("submit.feedback.alert.submit", value: "Done", comment: "Alert submit option for users to accept sharing their email and name when submitting feedback.")
    static let identityAlertEmptyEmail = NSLocalizedString("submit.feedback.alert.empty.email", value: "no email entered", comment: "Label we show on an email input field")
    static let identityAlertEmptyName = NSLocalizedString("submit.feedback.alert.empty.username", value: "no username entered", comment: "Label we show on an name input field")

    static let cancellationAlertTitle = NSLocalizedString("submitFeedback.cancellationAlertTitle", value: "Are you sure you want to discard the feedback", comment: "Submit feedback screen cancellation confirmation alert title")
    static let cancellationAlertContinueEditing = NSLocalizedString("submitFeedback.cancellationAlertContinueEditing", value: "Continue Editing", comment: "Submit feedback screen cancellation confirmation alert action")
    static let cancellationAlertDiscardFeedbackButton = NSLocalizedString("submitFeedback.cancellationAlertDiscardFeedbackButton", value: "Discard Feedback", comment: "Submit feedback screen cancellation confirmation alert action")
    static let failureAlertTitle = NSLocalizedString("submitFeedback.failureAlertTitle", value: "Failed to submit feedback", comment: "Submit feedback screen failure alert title")
    static let successNoticeTitle = NSLocalizedString("submitFeedback.successNoticeTitle", value: "Feedback sent", comment: "Submit feedback screen submit fsuccess notice title")
    static let successNoticeMessage = NSLocalizedString("submitFeedback.successNoticeMessage", value: "Thank you for helping us improve the app", comment: "Submit feedback screen submit success notice messages")
}

#Preview {
    NavigationView {
        SubmitFeedbackView()
    }
}
