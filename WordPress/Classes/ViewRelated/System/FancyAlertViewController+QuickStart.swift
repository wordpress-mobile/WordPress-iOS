extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("Want a little help getting started?", comment: "Title of alert asking if users want to try out the quick start checklist.")
        static let bodyText = NSLocalizedString("We’ll walk you through the basics of building and growing your site", comment: "Body text of alert asking if users want to try out the quick start checklist.")
        static let allowButtonText = NSLocalizedString("Yes, Help Me", comment: "Allow button title shown in alert asking if users want to try out the quick start checklist.")
        static let notNowText = NSLocalizedString("Not This Time", comment: "Not this time button title shown in alert asking if users want to try out the quick start checklist.")
    }

    private struct UpgradeStrings {
        static let titleText = NSLocalizedString("We’ve made some changes to your checklist", comment: "Title of alert letting users know we've upgraded the quick start checklist.")
        static let bodyText = NSLocalizedString("We’ve added more tasks to help you grow your audience.", comment: "Body text of alert letting users know we've upgraded the quick start checklist.")
        static let okButtonText = NSLocalizedString("OK", comment: "Dismiss button of alert letting users know we've upgraded the quick start checklist")
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "alert"
    }

    /// Create the fancy alert controller for the Quick Start request
    ///
    /// - Returns: FancyAlertViewController of the request
    @objc static func makeQuickStartAlertController(blog: Blog) -> FancyAlertViewController {
        WPAnalytics.track(.quickStartRequestAlertViewed)

        let allowButton = ButtonConfig(Strings.allowButtonText) { controller, _ in
            controller.dismiss(animated: true)

            QuickStartTourGuide.shared.setup(for: blog)

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

    /// Create the fancy alert controller for the Quick Start upgrade notification
    ///
    /// - Returns: FancyAlertViewController of the notice
    @objc static func makeQuickStartUpgradeToV2AlertController(blog: Blog) -> FancyAlertViewController {
        let okButton = ButtonConfig(UpgradeStrings.okButtonText) { controller, _ in
            WPAnalytics.track(.quickStartMigrationDialogPositiveTapped)

            controller.dismiss(animated: true)
        }

        let image = UIImage(named: "wp-illustration-big-checkmark")

        let config = FancyAlertViewController.Config(titleText: UpgradeStrings.titleText,
                                                     bodyText: UpgradeStrings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: okButton,
                                                     cancelButton: nil,
                                                     appearAction: {},
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}
