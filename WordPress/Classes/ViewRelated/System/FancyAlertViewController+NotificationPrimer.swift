extension FancyAlertViewController {
    private struct Strings {
        static let firstAlertTitleText = NSLocalizedString("Stay in the loop", comment: "Title of the first alert preparing users to grant permission for us to send them push notifications.")
        static let firstAlertBodyText = NSLocalizedString("We'll notify you when you get new followers, comments, and likes. Would you like to allow push notifications?", comment: "Body text of the first alert preparing users to grant permission for us to send them push notifications.")
        static let firstAllowButtonText = NSLocalizedString("Allow notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
        static let secondAlertTitleText = NSLocalizedString("Get your notifications faster", comment: "Title of the second alert preparing users to grant permission for us to send them push notifications.")
        static let secondAlertBodyText = NSLocalizedString("Learn about new comments, likes, and follows in seconds.", comment: "Body text of the first alert preparing users to grant permission for us to send them push notifications.")
        static let secondAllowButtonText = NSLocalizedString("Allow push notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
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
    static func makeNotificationAlertController(titleText: String?,
                                                bodyText: String?,
                                                allowButtonText: String,
                                                seenEvent: WPAnalyticsEvent,
                                                allowEvent: WPAnalyticsEvent,
                                                noEvent: WPAnalyticsEvent,
                                                approveAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {

        let allowButton = ButtonConfig(allowButtonText) { controller, _ in
            approveAction(controller)
            WPAnalytics.track(allowEvent, properties: [Analytics.locationKey: Analytics.alertKey])
        }

        let dismissButton = ButtonConfig(Strings.notNowText) { controller, _ in
            defer {
                WPAnalytics.track(noEvent, properties: [Analytics.locationKey: Analytics.alertKey])
            }
            controller.dismiss(animated: true)
        }

        let image = UIImage(named: "wp-illustration-stay-in-the-loop")

        let config = FancyAlertViewController.Config(titleText: titleText,
                                                     bodyText: bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: allowButton,
                                                     cancelButton: dismissButton,
                                                     appearAction: {
                                                        WPAnalytics.track(seenEvent, properties: [Analytics.locationKey: Analytics.alertKey])
                                                     },
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    static func makeNotificationPrimerAlertController(approveAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {
        return makeNotificationAlertController(titleText: Strings.firstAlertTitleText,
                                               bodyText: Strings.firstAlertBodyText,
                                               allowButtonText: Strings.firstAllowButtonText,
                                               seenEvent: .pushNotificationsPrimerSeen,
                                               allowEvent: .pushNotificationsPrimerAllowTapped,
                                               noEvent: .pushNotificationsPrimerNoTapped,
                                               approveAction: approveAction)
    }

    static func makeNotificationSecondAlertController(approveAction: @escaping ((_ controller: FancyAlertViewController) -> Void)) -> FancyAlertViewController {
        return makeNotificationAlertController(titleText: Strings.secondAlertTitleText,
                                               bodyText: Strings.secondAlertBodyText,
                                               allowButtonText: Strings.secondAllowButtonText,
                                               seenEvent: .secondNotificationsAlertSeen,
                                               allowEvent: .secondNotificationsAlertAllowTapped,
                                               noEvent: .secondNotificationsAlertNoTapped,
                                               approveAction: approveAction)
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
