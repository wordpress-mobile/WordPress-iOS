import SwiftUI
import UIKit
import WordPressData
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
            tracker.screenShown(.main)
            let alert = AlertView {
                AlertHeaderView(title: Strings.introTitle, description: Strings.introDescription)
            } content: {
                Image("reminders-celebration")
            } actions: {
                SetRemindersIntroActionsView(tracker: tracker) {
                    showSettings()
                }
            }
            alert.present(in: presentingViewController)
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

private struct SetRemindersIntroActionsView: View {
    @Environment(\.dismiss) var dismiss
    let tracker: BloggingRemindersTracker
    let action: () -> Void

    var body: some View {
        Button {
            tracker.buttonPressed(button: .continue, screen: .main)
            dismiss()
            action()
        } label: {
            Text(Strings.introButtonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)

        Button(SharedStrings.Button.notNow) {
            tracker.buttonPressed(button: .dismiss, screen: .main)
            dismiss()
        }
    }
}

private enum Strings {
    static let introTitle = NSLocalizedString("bloggingRemindersPrompt.intro.title", value: "Blogging Reminders", comment: "Title of the Blogging Reminders Settings screen.")
    static let introDescription = NSLocalizedString("bloggingRemindersPrompt.intro.details", value: "Set up your blogging reminders on days you want to post.", comment: "Description on the first screen of the Blogging Reminders Settings flow called after post publishing.")
    static let introButtonTitle = NSLocalizedString("bloggingRemindersPrompt.intro.continueButton", value: "Set Reminders", comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}
