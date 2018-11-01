import Foundation

/// Utility class that provides a mechanism for presenting the temporary gutenberg alert.
/// This alert is warns the user about editing Aztec posts with Gutenberg, and will be presented
/// whenever the user tries to edit a Gutenberg post, and as long as they don't enable the
/// "Do not show this again" option.
///
@objc class GutenbergAlertPresenter: NSObject {

    private let key = "GutenbergAlertConfiguration.doNotShowAgain"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func presentIfNecessary(
        for post: Post,
        from viewController: UIViewController,
        andDo onComplete: @escaping (Bool) -> ()) {

        guard mustPresent(for: post) else {
            onComplete(true)
            return
        }

        let trackProperties = properties(for: post)

        WPAnalytics.track(
            .gutenbergWarningConfirmDialogShown,
            withProperties: trackProperties)

        let title = NSLocalizedString("Before you continue", comment: "Title of the popup shown when trying to edit a Gutenberg post using our existing editor.")
        let message = NSLocalizedString("We are working on the brand new WordPress editor. You can still edit this post, but we recommend previewing it before publishing.", comment: "Message of the popup shown when trying to edit a Gutenberg post using our existing editor.")
        let editButtonTitle = NSLocalizedString("Edit Post", comment: "Title of the edit post button shown in the popup that comes up when opening a Gutenberg post with our existing editor.")
        let goBackButtonTitle = NSLocalizedString("Go Back", comment: "Title of the go-back button shown in the popup that comes up when opening a Gutenberg post with our existing editor.")
        let learnMoreButtonTitle = NSLocalizedString("Learn More", comment: "Title of the go-back button shown in the popup that comes up when opening a Gutenberg post with our existing editor.")
        let doNotShowAgainSwitchText = NSLocalizedString("Do not show this again", comment: "Text shown in the switch that allows the user to not show again the alert that comes up when opening a Gutenberg post with our existing editor.")

        let editButton = FancyAlertViewController.Config.ButtonConfig(editButtonTitle) { (controller: FancyAlertViewController, button: UIButton) in
            WPAnalytics.track(
                .gutenbergWarningConfirmDialogShownYesTapped,
                withProperties: trackProperties)

            if controller.isBottomSwitchOn() {
                self.doNotShowAgain()
            }

            controller.dismiss(animated: true) {
                onComplete(true)
            }
        }

        let goBackButton = FancyAlertViewController.Config.ButtonConfig(goBackButtonTitle) { (controller: FancyAlertViewController, button: UIButton) in
            WPAnalytics.track(
                .gutenbergWarningConfirmDialogShownCancelTapped,
                withProperties: trackProperties)

            if controller.isBottomSwitchOn() {
                self.doNotShowAgain()
            }

            controller.dismiss(animated: true) {
                onComplete(false)
            }
        }

        let moreInfoButton = FancyAlertViewController.Config.ButtonConfig(learnMoreButtonTitle) { (controller: FancyAlertViewController, button: UIButton) in
            WPAnalytics.track(
                .gutenbergWarningConfirmDialogShownLearnMoreTapped,
                withProperties: trackProperties)

            let url: URL = {
                if post.blog.isAccessibleThroughWPCom() {
                    return URL(string: "https://apps.wordpress.com/gutenberg?flavor=wpcom")!
                } else {
                    return URL(string: "https://apps.wordpress.com/gutenberg?flavor=wporg")!
                }
            }()

            let webViewController = WebViewControllerFactory.controller(url: url)
            let navController = UINavigationController(rootViewController: webViewController)
            navController.modalPresentationStyle = .fullScreen

            controller.present(navController, animated: true, completion: nil)
        }

        let doNotShowAgainSwitchConfig = FancyAlertViewController.Config.SwitchConfig(
            initialValue: false,
            text: doNotShowAgainSwitchText) { (controller, theSwitch) in
                if theSwitch.isOn {
                    WPAnalytics.track(
                        .gutenbergWarningConfirmDialogShownDontShowAgainChecked,
                        withProperties: trackProperties)
                } else {
                    WPAnalytics.track(
                        .gutenbergWarningConfirmDialogShownDontShowAgainUnchecked,
                        withProperties: trackProperties)
                }
        }

        let configuration = FancyAlertViewController.Config(
            titleText: title,
            bodyText: message,
            headerImage: nil,
            dividerPosition: nil,
            defaultButton: editButton,
            cancelButton: goBackButton,
            moreInfoButton: moreInfoButton,
            switchConfig: doNotShowAgainSwitchConfig)

        let alert = FancyAlertViewController.controllerWithConfiguration(configuration: configuration)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = self

        viewController.present(alert, animated: true, completion: nil)
    }

    // MARK: - Presentation Evaluation Logic

    private func mustPresent(for post: Post) -> Bool {
        return canPresentAlert() && isGutenbergPost(post)
    }

    // MARK: - User Defaults

    private func canPresentAlert() -> Bool {
        return !userDefaults.bool(forKey: key)
    }

    private func doNotShowAgain() {
        userDefaults.set(true, forKey: key)
    }

    // MARK: - Gutenber Post Introspection

    private func isGutenbergPost(_ post: Post) -> Bool {
        return post.content?.contains("<!-- wp:") ?? false
    }

    // MARK: - Analytics

    private func properties(for post: Post) -> [AnyHashable: Any] {
        guard let dotComID = post.blog.dotComID else {
            return [:]
        }

        return ["siteId": dotComID]
    }
}

// MARK: - UIViewControllerTransitioningDelegate
//
extension GutenbergAlertPresenter: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
