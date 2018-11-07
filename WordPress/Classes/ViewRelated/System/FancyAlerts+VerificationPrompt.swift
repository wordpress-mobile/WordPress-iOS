import UIKit
import WordPressAuthenticator


extension FancyAlertViewController {

    private enum VerificationFailureError: Error {
        case alreadyVerified
        case unknown
    }

    @objc public static func verificationPromptController(completion: (() -> Void)?) -> FancyAlertViewController {
        let resendEmailButton = FancyAlertViewController.Config.ButtonConfig(Strings.resendEmail) { controller, button in

            let managedObjectContext = ContextManager.sharedInstance().mainContext
            let accountService = AccountService(managedObjectContext: managedObjectContext)

            let submitButton = button as? NUXButton

            submitButton?.showActivityIndicator(true)

            accountService.requestVerificationEmail({
                submitButton?.showActivityIndicator(false)
                controller.setViewConfiguration(successfullySentVerificationEmailConfig(), animated: true)
            }, failure: { error in
                submitButton?.showActivityIndicator(false)

                var localError = VerificationFailureError.unknown
                if  (error as NSError).domain == WordPressComRestApiErrorDomain {
                    localError = .alreadyVerified
                }
                // if we hit a bad edge-case where the user hits a "resend email" button, but they've already verified
                // their account, we want to show them a nice message explaining what happened.
                // if it was a generic failure (probably bad network), show a different message.

                controller.setViewConfiguration(failureSendingVerificationEmailConfig(with: localError), animated: true)
            })
        }

        let defaultButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
            completion?()
            controller.dismiss(animated: true)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: #imageLiteral(resourceName: "wp-illustration-hand-write"),
                                                     dividerPosition: .bottom,
                                                     defaultButton: defaultButton,
                                                     cancelButton: resendEmailButton,
                                                     moreInfoButton: nil,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    private static func successfullySentVerificationEmailConfig() -> FancyAlertViewController.Config {
        let okButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
            controller.dismiss(animated: true)
        }

        return FancyAlertViewController.Config(titleText: Strings.titleText,
                                               bodyText: Strings.emailSentSuccesfully,
                                               headerImage: #imageLiteral(resourceName: "wp-illustration-hand-write"),
                                               dividerPosition: .bottom,
                                               defaultButton: okButton,
                                               cancelButton: nil,
                                               moreInfoButton: nil,
                                               titleAccessoryButton: nil,
                                               dismissAction: nil)
    }

    private static func failureSendingVerificationEmailConfig(with error: VerificationFailureError) -> FancyAlertViewController.Config {
        let okButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
            controller.dismiss(animated: true)
        }

        let bodyText: String

        switch error {
            case .alreadyVerified: bodyText = Strings.emailSendingFailedAlreadyVerified
            case .unknown: bodyText = Strings.emailSendingFailedGeneric
        }

        return FancyAlertViewController.Config(titleText: Strings.titleText,
                                               bodyText: bodyText,
                                               headerImage: #imageLiteral(resourceName: "wp-illustration-hand-write"),
                                               dividerPosition: .bottom,
                                               defaultButton: okButton,
                                               cancelButton: nil,
                                               moreInfoButton: nil,
                                               titleAccessoryButton: nil,
                                               dismissAction: nil)
    }

    private enum Strings {
        static let titleText = NSLocalizedString("Confirm your email first",
                                                 comment: "Title of alert prompting users to verify their accounts while attempting to publish")

        static let bodyText = NSLocalizedString("You need to verify your account before you can publish a post.\nDon’t worry, your post is safe and will be saved as a draft.",
                                                comment: "Body of alert prompting users to verify their accounts while attempting to publish")

        static let resendEmail = NSLocalizedString("Resend",
                                                   comment: "Title of secondary button on alert prompting verify their accounts while attempting to publish")

        static let ok = NSLocalizedString("OK",
                                          comment: "Title of primary button on alert prompting verify their accounts while attempting to publish")

        static let emailSentSuccesfully = NSLocalizedString("Verification email sent, check your inbox.",
                                                 comment: "Message shown when a verification email was re-sent succesfully")

        static let emailSendingFailedAlreadyVerified = NSLocalizedString("Error sending verification email. Are you already verified?",
                                                                         comment: "Message shown when there was an error trying to re-send email verification and we suspect the user has already verified in the meantime")

        static let emailSendingFailedGeneric = NSLocalizedString("Error sending verification email. Check your connection and try again.",
                                                                 comment: "Generic message shown when there was an error trying to re-send email verification.")

    }
}
