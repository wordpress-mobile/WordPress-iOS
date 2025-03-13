import UIKit
import WordPressFlux
import WordPressShared
import WordPressUI

final class BloggingRemindersFlow {
    static func present(
        from presentingViewController: UIViewController,
        for blog: Blog,
        source: BloggingRemindersTracker.FlowStartSource,
        alwaysShow: Bool = true,
        delegate: BloggingRemindersFlowDelegate? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        guard !UITestConfigurator.isEnabled(.disablePrompts) else {
            return
        }
        guard blog.areBloggingRemindersAllowed() else {
            return
        }

        guard alwaysShow || !hasShownWeeklyRemindersFlow(for: blog) else {
            return
        }

        let blogType: BloggingRemindersTracker.BlogType = blog.isHostedAtWPcom ? .wpcom : .selfHosted

        let tracker = BloggingRemindersTracker(blogType: blogType)
        tracker.flowStarted(source: source)

        let showSettings = { [weak presentingViewController] in
            do {
                let settingsVC = try BloggingRemindersFlowSettingsViewController(for: blog, tracker: tracker, delegate: delegate)
                let navigationController = BloggingRemindersNavigationController(rootViewController: settingsVC, onDismiss: {
                    onDismiss?()
                })
                presentingViewController?.present(navigationController, animated: true)
            } catch {
                wpAssertionFailure("Could not instantiate the blogging reminders settings VC", userInfo: ["error": "\(error)"])
            }
        }

        if hasShownWeeklyRemindersFlow(for: blog) {
            showSettings()
        } else {
            let introVC = BloggingRemindersFlowIntroViewController(tracker: tracker) { [weak presentingViewController] in
                presentingViewController?.dismiss(animated: true) {
                    showSettings()
                }
            }
            let navigationVC = UINavigationController(rootViewController: introVC)
            if presentingViewController.traitCollection.horizontalSizeClass == .regular {
                navigationVC.preferredContentSize = CGSize(width: 375, height: 420)
            } else {
                navigationVC.sheetPresentationController?.detents = [.medium()]
                navigationVC.sheetPresentationController?.preferredCornerRadius = 16
            }
            presentingViewController.present(navigationVC, animated: true)
        }

        setHasShownWeeklyRemindersFlow(for: blog)
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    // MARK: - Weekly reminders flow presentation status
    //
    // stores a key for each blog in UserDefaults to determine if
    // the flow was presented for the given blog.
    private static func hasShownWeeklyRemindersFlow(for blog: Blog) -> Bool {
        UserPersistentStoreFactory.instance().bool(forKey: weeklyRemindersKey(for: blog))
    }

    static func setHasShownWeeklyRemindersFlow(for blog: Blog) {
        UserPersistentStoreFactory.instance().set(true, forKey: weeklyRemindersKey(for: blog))
    }

    private static func weeklyRemindersKey(for blog: Blog) -> String {
        // weekly reminders key prefix
        let prefix = "blogging-reminder-weekly-"
        return prefix + blog.objectID.uriRepresentation().absoluteString
    }

    /// By making this private we ensure this can't be instantiated.
    ///
    private init() {
        assertionFailure()
    }
}
