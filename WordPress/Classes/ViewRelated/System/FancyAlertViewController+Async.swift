import UIKit
import SafariServices

private protocol AlertStrings {
    static var titleText: String { get }
    static var bodyText: String { get }
    static var confirmTitle: String { get }
}

extension FancyAlertViewController {

    typealias ButtonConfig = FancyAlertViewController.Config.ButtonConfig

    private struct PublishPostStrings: AlertStrings {
        static let titleText = NSLocalizedString("Publish with Confidence", comment: "Title of alert informing users about the async publishing feature.")
        static let bodyText = NSLocalizedString("You can now leave the editor and your post will save and publish behind the scenes! Give it a try!", comment: "Body text of alert informing users about the async publishing feature.")
        static let confirmTitle = NSLocalizedString("Publish Now", comment: "Publish button shown in alert informing users about the async publishing feature.")
    }

    private struct SchedulePostStrings: AlertStrings {
        static let titleText = NSLocalizedString("Schedule with Confidence", comment: "Title of alert informing users about the async publishing feature, when scheduling a post.")
        static let bodyText = NSLocalizedString("You can now leave the editor and your post will save and schedule behind the scenes! Give it a try!", comment: "Body text of alert informing users about the async publishing feature, when scheduling a post.")
        static let confirmTitle = NSLocalizedString("Schedule Now", comment: "Schedule button shown in alert informing users about the async publishing feature.")
    }

    private struct PublishPageStrings: AlertStrings {
        static let titleText = NSLocalizedString("Publish with Confidence", comment: "Title of alert informing users about the async publishing feature.")
        static let bodyText = NSLocalizedString("You can now leave the editor and your page will save and publish behind the scenes! Give it a try!", comment: "Body text of alert informing users about the async publishing feature, when publishing a page.")
        static let confirmTitle = NSLocalizedString("Publish Now", comment: "Publish button shown in alert informing users about the async publishing feature.")
    }

    private struct SchedulePageStrings: AlertStrings {
        static let titleText = NSLocalizedString("Schedule with Confidence", comment: "Title of alert informing users about the async publishing feature, when scheduling a page.")
        static let bodyText = NSLocalizedString("You can now leave the editor and your page will save and schedule behind the scenes! Give it a try!", comment: "Body text of alert informing users about the async publishing feature, when scheduling a page.")
        static let confirmTitle = NSLocalizedString("Schedule Now", comment: "Schedule button shown in alert informing users about the async publishing feature.")
    }

    private struct GeneralStrings {
        static let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Button title shown in alert informing users about the async publishing feature.")
        static let moreHelpTitle = NSLocalizedString("How does it work?", comment: "Title of the more help button on alert helping users understand their site address")
    }

    static func makeAsyncPostingAlertController(action: PostEditorAction, isPage: Bool, onConfirm: @escaping (() -> Void)) -> FancyAlertViewController {
        let strings = self.strings(for: action, isPage: isPage)

        let confirmButton = ButtonConfig(strings.confirmTitle) { controller, _ in
            controller.dismiss(animated: true, completion: {
                onConfirm()
            })
        }

        let dismissButton = ButtonConfig(GeneralStrings.keepEditingTitle) { controller, _ in
            controller.dismiss(animated: true, completion: nil)
        }

        let moreHelpButton = ButtonConfig(GeneralStrings.moreHelpTitle) { controller, _ in
            guard let url = URL(string: "http://en.blog.wordpress.com/2018/04/23/ios-nine-point-eight/") else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true, completion: nil)
        }

        let image = UIImage(named: "wp-illustration-easy-async")

        let config = FancyAlertViewController.Config(titleText: strings.titleText,
                                                     bodyText: strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: confirmButton,
                                                     cancelButton: dismissButton,
                                                     moreInfoButton: moreHelpButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    private static func strings(for action: PostEditorAction, isPage: Bool) -> AlertStrings.Type {
        switch (action, isPage) {
        case (.schedule, true):
            return SchedulePageStrings.self
        case (.schedule, false):
            return SchedulePostStrings.self
        case (_, true):
            return PublishPageStrings.self
        case (_, false):
            return PublishPostStrings.self
        }
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
