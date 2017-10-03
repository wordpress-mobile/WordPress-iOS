//
//  FancyAlerts+VerificationPrompt.swift
//  WordPress
//
//  Created by Jan Klausa on 03.10.17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

extension FancyAlertViewController {

    public static func verificationPromptController() -> FancyAlertViewController {
        let resendEmailButton = FancyAlertViewController.Config.ButtonConfig(Strings.resendEmail) { controller, button in

            //verify email

            let managedObjectContext = ContextManager.sharedInstance().mainContext
            let accountService = AccountService(managedObjectContext: managedObjectContext)

            let submitButton = button as? NUXSubmitButton

            submitButton?.showActivityIndicator(true)

            accountService.requestVerificationEmail({ _ in
                controller.dismiss(animated: true, completion: nil)
                return

            }, failure: { error in
                submitButton?.showActivityIndicator(false)
            })


        }

        let defaultButton = FancyAlertViewController.Config.ButtonConfig(Strings.ok) { controller, _ in
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

    private struct Strings {
        static let titleText = NSLocalizedString("Confirm your email first",
                                                 comment: "Title of alert prompting users to verify their accounts while attempting to publish")

        static let bodyText = NSLocalizedString("You need to verify your account before you can publish a post. Don’t worry, your post is safe and will be saved as a draft.",
                                                comment: "Body of alert prompting users to verify their accounts while attempting to publish")

        static let resendEmail = NSLocalizedString("Resend email",
                                                   comment: "Title of secondary button on alert prompting verify their accounts while attempting to publish")

        static let ok = NSLocalizedString("OK",
                                          comment: "Title of primary button on alert prompting verify their accounts while attempting to publish")

    }


}
