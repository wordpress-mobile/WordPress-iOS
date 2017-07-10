import UIKit

extension FancyAlertViewController {
    private enum Constants {
        static let successAnimationDuration: TimeInterval = 0.8
    }

    static func siteAddessHelpController() -> FancyAlertViewController {
        struct Strings {
            static let titleText = NSLocalizedString("What's my site address?", comment: "Title of alert helping users understand their site address")
            static let bodyText = NSLocalizedString("Your site address appears in the bar at the the top of the screen when you visit your site in Safari.", comment: "Body text of alert helping users understand their site address")
            static let OK = NSLocalizedString("OK", comment: "Ok button for dismissing alert helping users understand their site address")
            static let moreHelp = NSLocalizedString("Need more help?", comment: "Title of the more help button on alert helping users understand their site address")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let defaultButton = Button(Strings.OK) { controller in
            controller.dismiss(animated: true, completion: nil)
        }

        let moreHelpButton = Button(Strings.moreHelp) { controller in
            // show help
            controller.dismiss(animated: true, completion: nil)
        }

        let image = UIImage(named: "site-address-modal")


        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     headerBackgroundColor: .white,
                                                     defaultButton: defaultButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}
