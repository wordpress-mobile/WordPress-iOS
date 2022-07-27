import Foundation

class BloggingRemindersFlow {

    typealias DismissClosure = () -> Void

    static func present(from viewController: UIViewController,
                        for blog: Blog,
                        source: BloggingRemindersTracker.FlowStartSource,
                        alwaysShow: Bool = true,
                        delegate: BloggingRemindersFlowDelegate? = nil,
                        onDismiss: DismissClosure? = nil) {

        guard alwaysShow || !hasShownWeeklyRemindersFlow(for: blog) else {
            return
        }

        let blogType: BloggingRemindersTracker.BlogType = blog.isHostedAtWPcom ? .wpcom : .selfHosted

        let tracker = BloggingRemindersTracker(blogType: blogType)
        tracker.flowStarted(source: source)

        let flowStartViewController = makeStartViewController(for: blog,
                                                              tracker: tracker,
                                                              source: source,
                                                              delegate: delegate)
        let navigationController = BloggingRemindersNavigationController(
            rootViewController: flowStartViewController,
            onDismiss: {
                NoticesDispatch.unlock()
                onDismiss?()
            })

        let bottomSheet = BottomSheetViewController(childViewController: navigationController,
                                                    customHeaderSpacing: 0)

        NoticesDispatch.lock()
        bottomSheet.show(from: viewController)
        setHasShownWeeklyRemindersFlow(for: blog)
    }

    /// if the flow has never been seen, it starts with the intro. Otherwise it starts with the calendar settings
    private static func makeStartViewController(for blog: Blog,
                                                tracker: BloggingRemindersTracker,
                                                source: BloggingRemindersTracker.FlowStartSource,
                                                delegate: BloggingRemindersFlowDelegate? = nil) -> UIViewController {

        guard hasShownWeeklyRemindersFlow(for: blog) else {
            return BloggingRemindersFlowIntroViewController(for: blog,
                                                            tracker: tracker,
                                                            source: source,
                                                            delegate: delegate)
        }

        return (try? BloggingRemindersFlowSettingsViewController(for: blog, tracker: tracker, delegate: delegate)) ??
            BloggingRemindersFlowIntroViewController(for: blog, tracker: tracker, source: source, delegate: delegate)
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
