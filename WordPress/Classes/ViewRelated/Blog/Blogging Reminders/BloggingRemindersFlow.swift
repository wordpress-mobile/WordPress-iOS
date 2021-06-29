import Foundation

class BloggingRemindersFlow {

    static func present(from viewController: UIViewController,
                        for blog: Blog,
                        source: BloggingRemindersTracker.FlowStartSource,
                        alwaysShow: Bool = true) {

        guard alwaysShow || !hasShownWeeklyRemindersFlow(for: blog) else {
            return
        }

        let blogType: BloggingRemindersTracker.BlogType = blog.isHostedAtWPcom ? .wpcom : .selfHosted

        let tracker = BloggingRemindersTracker(blogType: blogType)
        tracker.flowStarted(source: source)

        let flowIntroViewController = BloggingRemindersFlowIntroViewController(for: blog, tracker: tracker, source: source)
        let navigationController = BloggingRemindersNavigationController(rootViewController: flowIntroViewController)

        let bottomSheet = BottomSheetViewController(childViewController: navigationController,
                                                    customHeaderSpacing: 0)

        NoticesDispatch.lock()
        bottomSheet.show(from: viewController)
        setHasShownWeeklyRemindersFlow(for: blog)
    }

    // MARK: - Weekly reminders flow presentation status
    //
    // stores a key for each blog in UserDefaults to determine if
    // the flow was presented for the given blog.
    private static func hasShownWeeklyRemindersFlow(for blog: Blog) -> Bool {
        UserDefaults.standard.bool(forKey: weeklyRemindersKey(for: blog))
    }

    private static func setHasShownWeeklyRemindersFlow(for blog: Blog) {
        UserDefaults.standard.setValue(true, forKey: weeklyRemindersKey(for: blog))
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
