extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Stay in the loop", comment: "Title of alert preparing users to grant permission for us to send them push notifications.")
        static let bodyText = NSLocalizedString("We’ll notify you when you get followers, comments and likes. Would you like to enable push notifications?", comment: "Body text of alert preparing users to grant permission for us to send them push notifications.")
        static let allowButtonText = NSLocalizedString("Allow push notifications", comment: "Allow button title shown in alert preparing users to grant permission for us to send them push notifications.")
        static let notNowText = NSLocalizedString("Not now", comment: "Not now button title shown in alert preparing users to grant permission for us to send them push notifications.")
    }

    /// Create the fancy alert controller for the notification primer
    ///
    /// - Parameter approveAction: block to call when approve is tapped
    /// - Returns: FancyAlertViewController of the primer
    @objc static func makeNotificationPrimerAlertController(approveAction: @escaping (() -> Void)) -> FancyAlertViewController {

        let publishButton = ButtonConfig(Strings.allowButtonText) { controller, _ in
            controller.dismiss(animated: true, completion: {
                approveAction()
            })
        }

        let dismissButton = ButtonConfig(Strings.notNowText) { controller, _ in
            controller.dismiss(animated: true, completion: nil)
        }

        let image = UIImage(named: "wp-illustration-easy-async")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: publishButton,
                                                     cancelButton: dismissButton,
                                                     moreInfoButton: nil,
                                                     titleAccessoryButton: nil,
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
    }

    var notificationPrimerAlertWasDisplayed: Bool {
        get {
            return bool(forKey: Keys.notificationPrimerAlertWasDisplayed.rawValue)
        }
        set {
            set(newValue, forKey: Keys.notificationPrimerAlertWasDisplayed.rawValue)
        }
    }
}
