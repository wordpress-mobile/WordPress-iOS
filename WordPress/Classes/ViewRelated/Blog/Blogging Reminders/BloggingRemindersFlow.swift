import Foundation

class BloggingRemindersFlow {
    static let weeklyRemindersKeyPrefix = "blogging-reminder-weekly-"

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

        // TODO: Check whether we've already presented this flow to the user. @frosty
        let flowIntroViewController = BloggingRemindersFlowIntroViewController(for: blog, tracker: tracker)
        let navigationController = BloggingRemindersNavigationController(rootViewController: flowIntroViewController)

        let bottomSheet = BottomSheetViewController(childViewController: navigationController,
                                                    customHeaderSpacing: 0)

        NoticesDispatch.lock()
        bottomSheet.show(from: viewController)
        setHasShownWeeklyRemindersFlow(for: blog)
    }

    private static func hasShownWeeklyRemindersFlow(for blog: Blog) -> Bool {
        let key = Self.weeklyRemindersKeyPrefix + blog.objectID.uriRepresentation().absoluteString
        return UserDefaults.standard.bool(forKey: key)
    }

    private static func setHasShownWeeklyRemindersFlow(for blog: Blog) {
        let key = Self.weeklyRemindersKeyPrefix + blog.objectID.uriRepresentation().absoluteString
        UserDefaults.standard.setValue(true, forKey: key)
    }

    /// By making this private we ensure this can't be instantiated.
    ///
    private init() {
        assertionFailure()
    }
}
