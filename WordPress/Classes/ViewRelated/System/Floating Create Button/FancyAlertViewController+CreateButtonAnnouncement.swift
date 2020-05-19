extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Streamlined navigation", comment: "Title of alert announcing new Create Button feature.")
        static let bodyText = NSLocalizedString("Now there are fewer and better-organized tabs, posting shortcuts, and more, so you can find what you need fast.", comment: "Body text of alert announcing new Create Button feature.")
        static let okayButtonText = NSLocalizedString("Got it!", comment: "Okay button title shown in alert announcing new Create Button feature.")
        static let readMoreButtonText = NSLocalizedString("Learn more", comment: "Read more button title shown in alert announcing new Create Button feature.")
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    /// Create the fancy alert controller for the notification primer
    ///
    /// - Parameter approveAction: block to call when approve is tapped
    /// - Returns: FancyAlertViewController of the primer
    @objc static func makeCreateButtonAnnouncementAlertController(readMoreAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {

        let okayButton = ButtonConfig(Strings.okayButtonText) { controller, _ in
            controller.dismiss(animated: true)
        }

        let readMoreButton = ButtonConfig(Strings.readMoreButtonText) { controller, _ in
            readMoreAction(controller)
        }

        let image = UIImage(named: "wp-illustration-ia-announcement")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: readMoreButton,
                                                     cancelButton: okayButton,
                                                     appearAction: {
                                                        WPAnalytics.track(WPAnalyticsEvent.createAnnouncementModalShown, properties: [Analytics.locationKey: Analytics.alertKey])
                                                     },
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

@objc
extension UserDefaults {
    private enum Keys: String {
        case createButtonAlertWasDisplayed = "CreateButtonAlertWasDisplayed"
    }

    var createButtonAlertWasDisplayed: Bool {
        get {
            return bool(forKey: Keys.createButtonAlertWasDisplayed.rawValue)
        }
        set {
            set(newValue, forKey: Keys.createButtonAlertWasDisplayed.rawValue)
        }
    }
}
