extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Want a little help getting started?", comment: "Title of alert asking if users want to try out the quick start checklist.")
        static let bodyText = NSLocalizedString("Our Quick Start checklist walks you through the basics of setting up a new website.", comment: "Body text of alert asking if users want to try out the quick start checklist.")
        static let allowButtonText = NSLocalizedString("Yes", comment: "Allow button title shown in alert asking if users want to try out the quick start checklist.")
        static let notNowText = NSLocalizedString("Yes", comment: "Not this time button title shown in alert asking if users want to try out the quick start checklist.")
        static let neverText = NSLocalizedString("Never", comment: "Never button title shown in alert asking if users want to try out the quick start checklist.")
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    /// Create the fancy alert controller for the notification primer
    ///
    /// - Parameter approveAction: block to call when approve is tapped
    /// - Returns: FancyAlertViewController of the primer
    @objc static func makeQuickStartAlertController() -> FancyAlertViewController {

        let publishButton = ButtonConfig(Strings.allowButtonText) { controller, _ in
//            approveAction(controller)
            WPAnalytics.track(.pushNotificationPrimerAllowTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }

        let dismissButton = ButtonConfig(Strings.notNowText) { controller, _ in
            defer {
                WPAnalytics.track(.pushNotificationPrimerNoTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
            }
            controller.dismiss(animated: true, completion: nil)
        }

        let image = UIImage(named: "wp-illustration-checklist")

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
        case quickStartChecklistWasDismissedPermanently = "QuickStartChecklistWasDismissedPermanently"
    }

    var quickStartChecklistWasDismissedPermanently: Bool {
        get {
            return bool(forKey: Keys.quickStartChecklistWasDismissedPermanently.rawValue)
        }
        set {
            set(newValue, forKey: Keys.quickStartChecklistWasDismissedPermanently.rawValue)
        }
    }
}
