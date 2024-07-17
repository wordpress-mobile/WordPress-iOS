import UIKit
import SafariServices
import WordPressUI
import WordPressKit

extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("What's my site address?", comment: "Title of alert helping users understand their site address")
        static let bodyText = NSLocalizedString("Your site address appears in the bar at the top of the screen when you visit your site in Safari.", comment: "Body text of alert helping users understand their site address")
        static let OK = NSLocalizedString("OK", comment: "Ok button for dismissing alert helping users understand their site address")
        static let moreHelp = NSLocalizedString("Need more help?", comment: "Title of the more help button on alert helping users understand their site address")
    }

    typealias ButtonConfig = FancyAlertViewController.Config.ButtonConfig

    private static func defaultButton(onTap: (() -> ())? = nil) -> ButtonConfig {
        return ButtonConfig(Strings.OK) { controller, _ in
            controller.dismiss(animated: true, completion: {
                onTap?()
            })
        }
    }

    static func siteAddressHelpController(
        loginFields: LoginFields,
        sourceTag: WordPressSupportSourceTag,
        moreHelpTapped: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil) -> FancyAlertViewController {

        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller, _ in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard WordPressAuthenticator.shared.delegate?.supportEnabled == true,
                    let viewController = UIApplication.shared.delegate?.window??.topmostPresentedViewController
                else {
                    return
                }

                moreHelpTapped?()
                WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: viewController, sourceTag: sourceTag)
            }
        }

        let image = WordPressAuthenticator.shared.displayImages.siteAddressModalPlaceholder

        let okButton = ButtonConfig(Strings.OK) { controller, _ in
            onDismiss?()
            controller.dismiss(animated: true, completion: nil)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .top,
                                                     defaultButton: okButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: onDismiss)

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    // MARK: - Error Handling

    /// Get an alert for the specified error.
    /// The view is configured differently depending on the kind of error.
    ///
    /// - Parameters:
    ///     - error: An NSError instance
    ///     - loginFields: A LoginFields instance.
    ///     - sourceTag: The sourceTag that is the context of the error.
    ///
    /// - Returns: A FancyAlertViewController instance.
    ///
    static func alertForError(_ originalError: Error, loginFields: LoginFields, sourceTag: WordPressSupportSourceTag) -> FancyAlertViewController {
        let error = originalError as NSError
        var message = error.localizedDescription

        WPAuthenticatorLogError(message)

        if sourceTag == .jetpackLogin && error.domain == WordPressAuthenticator.errorDomain && error.code == NSURLErrorBadURL {
            if WordPressAuthenticator.shared.delegate?.supportEnabled == true {
                // TODO: Placeholder Jetpack login error message. Needs updating with final wording. 2017-06-15 Aerych.
                message = NSLocalizedString("We're not able to connect to the Jetpack site at that URL.  Contact us for assistance.", comment: "Error message shown when having trouble connecting to a Jetpack site.")
                return alertForGenericErrorMessageWithHelpButton(message, loginFields: loginFields, sourceTag: sourceTag)
            }
        }

        if error.domain != WordPressOrgXMLRPCApi.errorDomain && error.code != NSURLErrorBadURL {
            if WordPressAuthenticator.shared.delegate?.supportEnabled == true {
                return alertForGenericErrorMessageWithHelpButton(message, loginFields: loginFields, sourceTag: sourceTag)
            }

            return alertForGenericErrorMessage(message, loginFields: loginFields, sourceTag: sourceTag)
        }

        if error.code == 403 {
            message = NSLocalizedString("Incorrect username or password. Please try entering your login details again.", comment: "An error message shown when a user signed in with incorrect credentials.")
        }

        if message.trim().count == 0 {
            message = NSLocalizedString("Log in failed. Please try again.", comment: "A generic error message for a failed log in.")
        }

        if error.code == NSURLErrorBadURL {
            return alertForBadURL(with: message)
        }

        return alertForGenericErrorMessage(message, loginFields: loginFields, sourceTag: sourceTag)
    }

    /// Shows a generic error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    private static func alertForGenericErrorMessage(_ message: String, loginFields: LoginFields, sourceTag: WordPressSupportSourceTag) -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller, _ in
            controller.dismiss(animated: true) {
                guard let sourceViewController = UIApplication.shared.delegate?.window??.topmostPresentedViewController,
                    let authDelegate = WordPressAuthenticator.shared.delegate
                else {
                    return
                }

                let state = AuthenticatorAnalyticsTracker.shared.state
                authDelegate.presentSupport(from: sourceViewController, sourceTag: sourceTag, lastStep: state.lastStep, lastFlow: state.lastFlow)
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

    /// Shows a generic error message.
    /// If Support is enabled, the view is configured so the user can open Support for assistance.
    ///
    /// - Parameter message: The error message to show.
    /// - Parameter sourceTag: tag of the source of the error
    ///
    static func alertForGenericErrorMessageWithHelpButton(_ message: String, loginFields: LoginFields, sourceTag: WordPressSupportSourceTag, onDismiss: (() -> ())? = nil) -> FancyAlertViewController {

        // If support is not enabled, don't add a Help Button since it won't do anything.
        var moreHelpButton: ButtonConfig?

        if WordPressAuthenticator.shared.delegate?.supportEnabled == false {
            WPAuthenticatorLogInfo("Error Alert: Support not enabled. Hiding Help button.")
        } else {
            moreHelpButton = ButtonConfig(Strings.moreHelp) { controller, _ in
                controller.dismiss(animated: true) {
                    // Find the topmost view controller that we can present from
                    guard let appDelegate = UIApplication.shared.delegate,
                        let window = appDelegate.window,
                        let viewController = window?.topmostPresentedViewController,
                        WordPressAuthenticator.shared.delegate?.supportEnabled == true
                        else {
                            return
                    }

                    WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: viewController, sourceTag: sourceTag)
                }
            }
        }

        let config = FancyAlertViewController.Config(titleText: "",
                                                     bodyText: message,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: defaultButton(onTap: onDismiss),
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    private static func alertForBadURL(with message: String) -> FancyAlertViewController {
        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller, _ in
            controller.dismiss(animated: true) {
                // Find the topmost view controller that we can present from
                guard let viewController = UIApplication.shared.delegate?.window??.topmostPresentedViewController,
                    let url = URL(string: "https://apps.wordpress.org/support/#faq-ios-3")
                    else {
                        return
                }

                let safariViewController = SFSafariViewController(url: url)
                safariViewController.modalPresentationStyle = .pageSheet
                viewController.present(safariViewController, animated: true, completion: nil)
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
