import UIKit

extension BlogDetailsViewController {
    static func presentBloggingRemindersSettingsFlow(from viewController: UIViewController, for blog: Blog, source: BloggingRemindersTracker.FlowStartSource) {

        let blogType: BloggingRemindersTracker.BlogType = blog.isHostedAtWPcom ? .wpcom : .selfHosted

        let tracker = BloggingRemindersTracker(blogType: blogType)
        tracker.flowStarted(source: source)

        // TODO: Check whether we've already presented this flow to the user. @frosty
        let flowIntroViewController = BloggingRemindersFlowIntroViewController(tracker: tracker)
        let navigationController = BloggingRemindersNavigationController(rootViewController: flowIntroViewController)

        let bottomSheet = BottomSheetViewController(childViewController: navigationController,
                                                    customHeaderSpacing: 0)
        bottomSheet.show(from: viewController)
    }
}
