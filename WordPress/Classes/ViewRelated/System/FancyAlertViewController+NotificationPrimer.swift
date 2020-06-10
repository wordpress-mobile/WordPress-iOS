extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Stay in the loop", comment: "Title of alert preparing users to grant permission for us to send them push notifications.")
        static let bodyText = NSLocalizedString("We’ll notify you when you get followers, comments and likes. Would you like to allow push notifications?", comment: "Body text of alert preparing users to grant permission for us to send them push notifications.")
        static let allowButtonText = NSLocalizedString("Allow notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
        static let notNowText = NSLocalizedString("Not now", comment: "Not now button title shown in alert preparing users to grant permission for us to send them push notifications.")
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    /// Create the fancy alert controller for the notification primer
    ///
    /// - Parameter approveAction: block to call when approve is tapped
    /// - Returns: FancyAlertViewController of the primer
    @objc static func makeNotificationPrimerAlertController(approveAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {

        let publishButton = ButtonConfig(Strings.allowButtonText) { controller, _ in
            approveAction(controller)
            WPAnalytics.track(.pushNotificationPrimerAllowTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }

        let dismissButton = ButtonConfig(Strings.notNowText) { controller, _ in
            defer {
                WPAnalytics.track(.pushNotificationPrimerNoTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
            }
            controller.dismiss(animated: true)
        }

        let image = UIImage(named: "wp-illustration-stay-in-the-loop")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: publishButton,
                                                     cancelButton: dismissButton,
                                                     appearAction: {
                                                        WPAnalytics.track(.pushNotificationPrimerSeen, withProperties: [Analytics.locationKey: Analytics.alertKey])
                                                     },
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

// MARK: - User Defaults

@objc
extension UserDefaults {
    private enum Keys: String {
        case notificationPrimerAlertWasDisplayed = "NotificationPrimerAlertWasDisplayed"
        case notificationsTabAccessCount = "NotificationsTabAccessCount"
    }

    var notificationPrimerAlertWasDisplayed: Bool {
        get {
            bool(forKey: Keys.notificationPrimerAlertWasDisplayed.rawValue)
        }
        set {
            set(newValue, forKey: Keys.notificationPrimerAlertWasDisplayed.rawValue)
        }
    }

    var notificationsTabAccessCount: Int {
        get {
            integer(forKey: Keys.notificationsTabAccessCount.rawValue)
        }

        set {
            set(newValue, forKey: Keys.notificationsTabAccessCount.rawValue)
        }
    }
}
