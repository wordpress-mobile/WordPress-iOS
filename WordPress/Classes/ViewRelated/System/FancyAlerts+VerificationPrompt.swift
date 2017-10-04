//
//  FancyAlerts+VerificationPrompt.swift
//  WordPress
//
//  Created by Jan Klausa on 03.10.17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

extension FancyAlertViewController {

    public static func verificationPromptController(completion: (() -> Void)?) -> FancyAlertViewController {
        let resendEmailButton = FancyAlertViewController.Config.ButtonConfig(Strings.resendEmail) { controller, button in

            let managedObjectContext = ContextManager.sharedInstance().mainContext
            let accountService = AccountService(managedObjectContext: managedObjectContext)

            let submitButton = button as? NUXSubmitButton

            submitButton?.showActivityIndicator(true)

            accountService.requestVerificationEmail({ _ in
                submitButton?.showActivityIndicator(false)
                controller.setViewConfiguration(successfullySentVerificationEmailConfig(), animated: true)
            }, failure: { error in
                submitButton?.showActivityIndicator(false)
                controller.setViewConfiguration(failureSendingVerificationEmailConfig(), animated: true)
            })
        }

        let defaultButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
            completion?()
            controller.dismiss(animated: true, completion: nil)
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
            controller.dismiss(animated: true, completion: nil)
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

    private static func failureSendingVerificationEmailConfig() -> FancyAlertViewController.Config {
        let okButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
            controller.dismiss(animated: true, completion: nil)
        }

        return FancyAlertViewController.Config(titleText: Strings.titleText,
                                               bodyText: Strings.emailSendingFailed,
                                               headerImage: #imageLiteral(resourceName: "wp-illustration-hand-write"),
                                               dividerPosition: .bottom,
                                               defaultButton: okButton,
                                               cancelButton: nil,
                                               moreInfoButton: nil,
                                               titleAccessoryButton: nil,
                                               dismissAction: nil)
    }

    private struct Strings {
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

        static let emailSendingFailed = NSLocalizedString("Error sending verification email. Are you already verified?",
                                                          comment: "Message shown when there was an error trying to re-send email verification")
    }


}
