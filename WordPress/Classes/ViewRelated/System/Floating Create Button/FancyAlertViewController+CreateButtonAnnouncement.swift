extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Simplified Navigation", comment: "Title of alert announcing new Create Button feature.")
        static let bodyText = NSLocalizedString("We've made our navigation less complex, so it's easier to find the things you need the most.", comment: "Body text of alert announcing new Create Button feature.")
        static let okayButtonText = NSLocalizedString("Okay", comment: "Okay button title shown in alert announcing new Create Button feature.")
        static let readMoreButtonText = NSLocalizedString("Read more on the blog", comment: "Read more button title shown in alert announcing new Create Button feature.")
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    /// Create the fancy alert controller for the notification primer
    ///
    /// - Parameter approveAction: block to call when approve is tapped
    /// - Returns: FancyAlertViewController of the primer
    @objc static func makeCreateButtonAnnouncementAlertController(approveAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {

        let okayButton = ButtonConfig(Strings.okayButtonText) { controller, _ in
            approveAction(controller)
            //TODO: Change this event
//            WPAnalytics.track(.pushNotificationPrimerAllowTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }

        let readMoreButton = ButtonConfig(Strings.readMoreButtonText) { controller, _ in
            defer {
                //TODO: Change this event
//                WPAnalytics.track(.pushNotificationPrimerNoTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
            }
            controller.dismiss(animated: true)
        }

        let image = UIImage(named: "wp-illustration-ia-announcement")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: readMoreButton,
                                                     cancelButton: okayButton,
                                                     appearAction: {
                                                        //TODO: Change event
//                                                        WPAnalytics.track(.pushNotificationPrimerSeen, withProperties: [Analytics.locationKey: Analytics.alertKey])
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
