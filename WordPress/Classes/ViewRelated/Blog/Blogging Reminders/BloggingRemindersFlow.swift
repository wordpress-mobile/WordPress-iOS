import Foundation

class BloggingRemindersFlow {
    static let weeklyRemindersKeyPrefix = "blogging-reminder-weekly-"
    static func present(from viewController: UIViewController,
                        for blog: Blog,
                        source: BloggingRemindersTracker.FlowStartSource,
                        alwaysShow: Bool = true) {

        guard alwaysShow || !UserDefaults.standard.bool(forKey: Self.weeklyRemindersKeyPrefix + blog.objectID.uriRepresentation().absoluteString) else {
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
        UserDefaults.standard.setValue(true, forKey: Self.weeklyRemindersKeyPrefix + blog.objectID.uriRepresentation().absoluteString)
    }

    /// By making this private we ensure this can't be instantiated.
    ///
    private init() {
        assertionFailure()
    }
}
