extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Want a little help getting started?", comment: "Title of alert asking if users want to try out the quick start checklist.")
        static let bodyText = NSLocalizedString("We’ll walk you through the basics of building and growing your site", comment: "Body text of alert asking if users want to try out the quick start checklist.")
        static let allowButtonText = NSLocalizedString("Yes, help me", comment: "Allow button title shown in alert asking if users want to try out the quick start checklist.")
        static let notNowText = NSLocalizedString("Not This Time", comment: "Not this time button title shown in alert asking if users want to try out the quick start checklist.")
    }

    // MARK: TODO: delete these when the .quickStartV2 feature flag is removed
    private struct StringsV1 {
        static let titleText = NSLocalizedString("Want a little help getting started?", comment: "Title of alert asking if users want to try out the quick start checklist.")
        static let bodyText = NSLocalizedString("Our Quick Start checklist walks you through the basics of setting up a new website.", comment: "Body text of alert asking if users want to try out the quick start checklist.")
        static let allowButtonText = NSLocalizedString("Yes", comment: "Allow button title shown in alert asking if users want to try out the quick start checklist.")
        static let notNowText = NSLocalizedString("Not This Time", comment: "Not this time button title shown in alert asking if users want to try out the quick start checklist.")
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
    @objc static func makeQuickStartAlertController(blog: Blog) -> FancyAlertViewController {
        guard Feature.enabled(.quickStartV2) else {
            return makeQuickStartAlertControllerV1(blog: blog)
        }

        WPAnalytics.track(.quickStartRequestAlertViewed)

        let allowButton = ButtonConfig(Strings.allowButtonText) { controller, _ in
            controller.dismiss(animated: true)

            guard let tourGuide = QuickStartTourGuide.find() else {
                return
            }

            tourGuide.setup(for: blog)

            WPAnalytics.track(.quickStartRequestAlertButtonTapped, withProperties: ["type": "positive"])
        }

        let notNowButton = ButtonConfig(Strings.notNowText) { controller, _ in
            controller.dismiss(animated: true)
            PushNotificationsManager.shared.deletePendingLocalNotifications()
            WPAnalytics.track(.quickStartRequestAlertButtonTapped, withProperties: ["type": "neutral"])
        }

        let image = UIImage(named: "wp-illustration-tasks-complete-audience")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: allowButton,
                                                     cancelButton: notNowButton,
                                                     appearAction: {},
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    // MARK: TODO: delete this when the .quickStartV2 feature flag is removed
    static func makeQuickStartAlertControllerV1(blog: Blog) -> FancyAlertViewController {
        WPAnalytics.track(.quickStartRequestAlertViewed)

        let allowButton = ButtonConfig(StringsV1.allowButtonText) { controller, _ in
            controller.dismiss(animated: true)

            guard let tourGuide = QuickStartTourGuide.find() else {
                return
            }

            tourGuide.setup(for: blog)

            WPAnalytics.track(.quickStartRequestAlertButtonTapped, withProperties: ["type": "positive"])
        }

        let notNowButton = ButtonConfig(StringsV1.notNowText) { controller, _ in
            controller.dismiss(animated: true)
            PushNotificationsManager.shared.deletePendingLocalNotifications()
            WPAnalytics.track(.quickStartRequestAlertButtonTapped, withProperties: ["type": "neutral"])
        }

        let neverButton = ButtonConfig(StringsV1.neverText) { controller, _ in
            UserDefaults.standard.quickStartWasDismissedPermanently = true
            controller.dismiss(animated: true)
            PushNotificationsManager.shared.deletePendingLocalNotifications()
            WPAnalytics.track(.quickStartRequestAlertButtonTapped, withProperties: ["type": "negative"])
        }

        let image = UIImage(named: "wp-illustration-checklist")

        let config = FancyAlertViewController.Config(titleText: StringsV1.titleText,
                                                     bodyText: StringsV1.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: allowButton,
                                                     cancelButton: notNowButton,
                                                     neverButton: neverButton,
                                                     appearAction: {},
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}
