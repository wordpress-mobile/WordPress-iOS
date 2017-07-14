import UIKit
import wpxmlrpc

extension FancyAlertViewController {
    struct Strings {
        static let titleText = NSLocalizedString("What's my site address?", comment: "Title of alert helping users understand their site address")
        static let bodyText = NSLocalizedString("Your site address appears in the bar at the the top of the screen when you visit your site in Safari.", comment: "Body text of alert helping users understand their site address")
        static let OK = NSLocalizedString("OK", comment: "Ok button for dismissing alert helping users understand their site address")
        static let moreHelp = NSLocalizedString("Need more help?", comment: "Title of the more help button on alert helping users understand their site address")
    }

    typealias ButtonConfig = FancyAlertViewController.Config.ButtonConfig

    private static func defaultButton() -> ButtonConfig {
        return ButtonConfig(Strings.OK) { controller in
            controller.dismiss(animated: true, completion: nil)
        }
    }

    static func siteAddressHelpController() -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard let delegate = UIApplication.shared.delegate,
                    let window = delegate.window,
                    let viewController = window?.topmostPresentedViewController else { return }

                guard HelpshiftUtils.isHelpshiftEnabled() else { return }

                let presenter = HelpshiftPresenter()
                presenter.sourceTag = SupportSourceTag.generalLogin
                presenter.presentHelpshiftConversationWindowFromViewController(viewController,
                                                                               refreshUserDetails: true,
                                                                               completion:nil)
            }
        }

        let image = UIImage(named: "site-address-modal")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .top,
                                                     defaultButton: defaultButton(),
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }


    // MARK: - Error Handling


    /// Get an alert for the specified error message.
    /// The view is configured differently depending on the kind of error.
    ///
    /// - Parameters:
    ///     - error: An NSError instance
    ///     - loginFields: A LoginFields instance.
    ///     - sourceTag: The sourceTag that is the context of the error.
    ///
    /// - Returns: A FancyAlertViewController instance.
    ///
    static func alertForError(_ error: NSError, loginFields: LoginFields, sourceTag: SupportSourceTag) -> FancyAlertViewController {
        var message = error.localizedDescription

        DDLogError(message)

        if sourceTag == .jetpackLogin && error.domain == WordPressAppErrorDomain && error.code == NSURLErrorBadURL {
            if HelpshiftUtils.isHelpshiftEnabled() {
                // TODO: Placeholder Jetpack login error message. Needs updating with final wording. 2017-06-15 Aerych.
                message = NSLocalizedString("We're not able to connect to the Jetpack site at that URL.  Contact us for assistance.", comment: "Error message shown when having trouble connecting to a Jetpack site.")
                return alertForGenericErrorMessageWithHelpshiftButton(message, loginFields: loginFields, sourceTag: sourceTag)
            }
        }

        if error.domain != WPXMLRPCFaultErrorDomain && error.code != NSURLErrorBadURL {
            if HelpshiftUtils.isHelpshiftEnabled() {
                return alertForGenericErrorMessageWithHelpshiftButton(message, loginFields: loginFields, sourceTag: sourceTag)
            } else {
                return alertForGenericErrorMessage(message, sourceTag: sourceTag)
            }
        }

        if error.code == 403 {
            message = NSLocalizedString("Incorrect username or password. Please try entering your login details again.", comment: "An error message shown when a user signed in with incorrect credentials.")
        }

        if message.trim().characters.count == 0 {
            message = NSLocalizedString("Log in failed. Please try again.", comment: "A generic error message for a failed log in.")
        }

        if error.code == NSURLErrorBadURL {
            return alertForBadURLMessage(message)
        }

        return alertForGenericErrorMessage(message, sourceTag: sourceTag)
    }


    /// Shows a generic error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    private static func alertForGenericErrorMessage(_ message: String, sourceTag: SupportSourceTag) -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard let appDelegate = UIApplication.shared.delegate,
                    let window = appDelegate.window,
                    let viewController = window?.topmostPresentedViewController else { return }

                let supportController = SupportViewController()
                supportController.sourceTag = sourceTag

                let navController = UINavigationController(rootViewController: supportController)
                navController.navigationBar.isTranslucent = false
                navController.modalPresentationStyle = .formSheet

                viewController.present(navController, animated: true, completion: nil)
            }
        }

        let config = FancyAlertViewController.Config(titleText: "",
                                                     bodyText: message,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: defaultButton(),
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)
        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }


    /// Shows a generic error message. The view
    /// is configured so the user can open Helpshift for assistance.
    ///
    /// - Parameter message: The error message to show.
    /// - Parameter sourceTag: tag of the source of the error
    ///
    private static func alertForGenericErrorMessageWithHelpshiftButton(_ message: String, loginFields: LoginFields, sourceTag: SupportSourceTag) -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard let appDelegate = UIApplication.shared.delegate,
                    let window = appDelegate.window,
                    let viewController = window?.topmostPresentedViewController else { return }

                guard HelpshiftUtils.isHelpshiftEnabled() else { return }

                let metaData: [String: AnyObject] = [
                    "Source": "Failed login" as AnyObject,
                    "Username": loginFields.username as AnyObject,
                    "SiteURL": loginFields.siteUrl as AnyObject,
                    HelpshiftSupportTagsKey: [sourceTag.rawValue]  as AnyObject
                ]

                HelpshiftSupport.showConversation(viewController, withOptions: [HelpshiftSupportCustomMetadataKey: metaData, "showSearchOnNewConversation": "YES"])
                WPAppAnalytics.track(.supportOpenedHelpshiftScreen)
            }
        }

        let config = FancyAlertViewController.Config(titleText: "",
                                                     bodyText: message,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: defaultButton(),
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)
        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }


    /// Shows a WPWalkthroughOverlayView for a bad url error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    private static func alertForBadURLMessage(_ message: String) -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard let appDelegate = UIApplication.shared.delegate,
                    let window = appDelegate.window,
                    let viewController = window?.topmostPresentedViewController,
                    let url = URL(string: "https://apps.wordpress.org/support/#faq-ios-3"),
                    let webController = WPWebViewController(url: url)
                    else { return }

                let navController = UINavigationController(rootViewController: webController)
                viewController.present(navController, animated: true, completion: nil)
            }
        }

        let config = FancyAlertViewController.Config(titleText: "",
                                                     bodyText: message,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: defaultButton(),
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)
        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

}
