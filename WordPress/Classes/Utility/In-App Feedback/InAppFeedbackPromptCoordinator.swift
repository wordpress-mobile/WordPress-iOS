import Foundation
import StoreKit

protocol InAppFeedbackPromptPresenting {
    func showPromptIfNeeded(in controller: UIViewController) -> Bool
}

struct InAppFeedbackPromptCoordinator: InAppFeedbackPromptPresenting {

    // MARK: - Properties

    private let appRatingUtility: AppRatingUtility
    private let userDefaults: UserDefaults

    // MARK: - Init

    init(utility: AppRatingUtility = .shared, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.appRatingUtility = utility
    }

    // MARK: - Showing the Prompt

    func shouldShowPromptForAppReview() -> Bool {
        return appRatingUtility.shouldPromptForAppReview()
    }

    func showPromptIfNeeded(in controller: UIViewController) -> Bool {
        guard shouldShowPromptForAppReview() else {
            return false
        }
        let alert = self.feedbackAlert(in: controller)
        controller.present(alert, animated: true)
        appRatingUtility.userWasPromptedToReview()
        WPAnalytics.track(.appReviewsSawPrompt)
        return true
    }

    private func feedbackAlert(in controller: UIViewController) -> UIAlertController {
        let alert = UIAlertController(
            title: Strings.FeedbackAlert.title,
            message: Strings.FeedbackAlert.message,
            preferredStyle: .alert
        )
        let yes = UIAlertAction(title: Strings.FeedbackAlert.yes, style: .default) { _ in
            self.handlePositiveFeedback(in: controller)
        }
        let no = UIAlertAction(title: Strings.FeedbackAlert.no, style: .default) { _ in
            self.handleNegativeFeedback(in: controller)
        }
        alert.addAction(no)
        alert.addAction(yes)
        return alert
    }

    // MARK: - Positive Feedback Flow

    private func handlePositiveFeedback(in controller: UIViewController) {
        guard let windowScene = controller.view.window?.windowScene else {
            return
        }
        self.appRatingUtility.likedCurrentVersion()

        // Show the app store ratings alert
        SKStoreReviewController.requestReview(in: windowScene)

        // Note: Optimistically assuming our prompting succeeds since we try to stay
        // in line and not prompt more than two times a year
        self.appRatingUtility.ratedCurrentVersion()

        WPAnalytics.track(.appReviewsLikedApp)
    }

    // MARK: - Negative Feedback Flow

    private func handleNegativeFeedback(in controller: UIViewController) {
        let alert = UIAlertController(
            title: Strings.NegativeFeedbackAlert.title,
            message: Strings.NegativeFeedbackAlert.message,
            preferredStyle: .alert
        )
        let yes = UIAlertAction(title: Strings.NegativeFeedbackAlert.yes, style: .default) { _ in
            let destination = UINavigationController(rootViewController: submitFeedbackViewController(in: controller))
            controller.present(destination, animated: true)
        }
        let no = UIAlertAction(title: Strings.NegativeFeedbackAlert.no, style: .default) { _ in
            WPAnalytics.track(.appReviewsDeclinedToRateApp)
            self.appRatingUtility.declinedToRateCurrentVersion()
        }
        alert.addAction(no)
        alert.addAction(yes)
        controller.present(alert, animated: true)
        WPAnalytics.track(.appReviewsDidntLikeApp)
        appRatingUtility.dislikedCurrentVersion()
    }

    private func submitFeedbackViewController(in controller: UIViewController) -> SubmitFeedbackViewController {
        let destination = SubmitFeedbackViewController()
        destination.onFeedbackSubmitted = { [weak controller] _, _ in
            controller?.displayNotice(
                title: Strings.ConfirmationNotice.title,
                message: Strings.ConfirmationNotice.message
            )
        }
        return destination
    }

}

// MARK: - Strings

extension InAppFeedbackPromptCoordinator {

    private enum Strings {
        enum FeedbackAlert {
            static let title = NSLocalizedString(
                "in-app.feedback.alert.title",
                value: "Your feedback matters",
                comment: "The title for the first feedback alert"
            )
            static let message = NSLocalizedString(
                "in-app.feedback.alert.message",
                value: "Are you enjoying the Jetpack mobile app?",
                comment: "The message for the first feedback alert"
            )
            static let yes = NSLocalizedString(
                "in-app.feedback.alert.yes",
                value: "It's great",
                comment: "The 'yes' button title for the first feedback alert"
            )
            static let no = NSLocalizedString(
                "in-app.feedback.alert.no",
                value: "Not really",
                comment: "The 'no' button title for the first feedback alert"
            )
        }
        enum NegativeFeedbackAlert {
            static let title = NSLocalizedString(
                "in-app.feedback.negative.alert.title",
                value: "Help us improve",
                comment: "The title for the negative feedback alert"
            )
            static let message = NSLocalizedString(
                "in-app.feedback.negative.alert.message",
                value: "Would you like to share more details with us?",
                comment: "The message for the negative feedback alert"
            )
            static let yes = NSLocalizedString(
                "in-app.feedback.negative.alert.yes",
                value: "Sure",
                comment: "The 'yes' button for the negative feedback alert"
            )
            static let no = NSLocalizedString(
                "in-app.feedback.negative.alert.no",
                value: "Not now",
                comment: "The 'no' button for the negative feedback alert"
            )
        }
        enum ConfirmationNotice {
            static let title = NSLocalizedString(
                "in-app.feedback.confirmation.notice.title",
                value: "Feedback sent",
                comment: ""
            )
            static let message = NSLocalizedString(
                "in-app.feedback.confirmation.notice.message",
                value: "Thanks for helping us improve the app.",
                comment: ""
            )
        }
    }
}
