import UIKit

extension FancyAlertViewController {
    static func aztecAnnouncementController() -> FancyAlertViewController {
        struct Strings {
            static let titleText = NSLocalizedString("Try the New Editor", comment: "Title of alert prompting users to try the new Aztec editor")
            static let bodyText = NSLocalizedString("The WordPress app now includes a beautiful new editor. Try it out by creating a new post!", comment: "Body text of alert prompting users to try the new Aztec editor")
            static let tryIt = NSLocalizedString("Try It", comment: "Title of the primary button on alert prompting users to try the new Aztec editor")
            static let notNow = NSLocalizedString("Not Now", comment: "Title of the cancel button on alert prompting users to try the new Aztec editor")
            static let whatsNew = NSLocalizedString("What's new?", comment: "Title of more info button on alert prompting users to try the new Aztec editor")
            static let beta = NSLocalizedString("Beta", comment: "Used to indicate a feature of the app currently in beta testing.")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let defaultButton = Button(Strings.tryIt, { controller in
            controller.configuration = aztecAnnouncementSuccessConfig
        })

        let cancelButton = Button(Strings.notNow, { controller in
            controller.dismiss(animated: true, completion: nil)
        })

        let moreInfoButton = Button(Strings.whatsNew, { _ in })
        let titleAccessoryButton = Button(Strings.beta, { _ in })

        let image = UIImage(named: "wp-illustration-hand-write")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     defaultButton: defaultButton, cancelButton: cancelButton, moreInfoButton: moreInfoButton, titleAccessoryButton: titleAccessoryButton)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    private static let aztecAnnouncementSuccessConfig: FancyAlertViewController.Config = {
        struct Strings {
            static let titleText = NSLocalizedString("New Editor Enabled!", comment: "Title of alert informing users that the new Aztec editor has been enabled")
            static let bodyText = NSLocalizedString("Thanks for trying it out! You can switch editor modes at any time in", comment: "Body text of alert informing users that the new Aztec editor has been enabled")
            static let appSettings = NSLocalizedString("Me > App Settings", comment: "Text for button telling user where to find the App Settings section of the app")
            static let beta = NSLocalizedString("Beta", comment: "Used to indicate a feature of the app currently in beta testing.")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let moreInfoButton = Button(Strings.appSettings, { _ in })

        let titleAccessoryButton = Button(Strings.beta, { _ in })

        let image = UIImage(named: "wp-illustration-thank-you")

        return FancyAlertViewController.Config(titleText: Strings.titleText,
                                               bodyText: Strings.bodyText,
                                               headerImage: image,
                                               defaultButton: nil, cancelButton: nil, moreInfoButton: moreInfoButton, titleAccessoryButton: titleAccessoryButton)
    }()
}

// MARK: - User Defaults

extension UserDefaults {
    private enum Keys: String {
        case aztecAnnouncement = "AztecBetaAnnouncementWasDisplayed"
    }

    var aztecAnnouncementWasDisplayed: Bool {
        get {
            return bool(forKey: Keys.aztecAnnouncement.rawValue)
        }
        set {
            set(newValue, forKey: Keys.aztecAnnouncement.rawValue)
        }
    }
}

