import UIKit
import SafariServices

extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Publish with Confidence", comment: "Title of alert informing users about the async publishing feature.")
        static let bodyText = NSLocalizedString("You can now leave the editor and your post will save and publish behind the scenes! Give it a try!", comment: "Body text of alert informing users about the async publishing feature.")
        static let publishNow = NSLocalizedString("Publish Now", comment: "Publish button shown in alert informing users about the async publishing feature.")
        static let keepEditing = NSLocalizedString("Keep Editing", comment: "Button title shown in alert informing users about the async publishing feature.")
        static let moreHelp = NSLocalizedString("How does it work?", comment: "Title of the more help button on alert helping users understand their site address")
    }

    static func makeAsyncPostingAlertController(publishAction: @escaping (() -> Void)) -> FancyAlertViewController {

        let publishButton = ButtonConfig(Strings.publishNow) { controller, _ in
            controller.dismiss(animated: true, completion: {
                publishAction()
            })
        }

        let dismissButton = ButtonConfig(Strings.keepEditing) { controller, _ in
            controller.dismiss(animated: true, completion: nil)
        }

        let moreHelpButton = ButtonConfig(Strings.moreHelp) { controller, _ in
            guard let url = URL(string: "http://en.blog.wordpress.com/2018/04/23/ios-nine-point-eight/") else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true, completion: nil)
        }

        let image = UIImage(named: "wp-illustration-easy-async")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: publishButton,
                                                     cancelButton: dismissButton,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

// MARK: - User Defaults

extension UserDefaults {
    private enum Keys: String {
        case asyncPromoWasDisplayed = "AsyncPromoWasDisplayed"
    }

    var asyncPromoWasDisplayed: Bool {
        get {
            return bool(forKey: Keys.asyncPromoWasDisplayed.rawValue)
        }
        set {
            set(newValue, forKey: Keys.asyncPromoWasDisplayed.rawValue)
        }
    }
}
