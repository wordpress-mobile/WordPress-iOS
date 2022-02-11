import Foundation
import WordPressShared

// MARK: - Quick Actions

extension BlogDashboardViewController {

    func showStats() {
        trackQuickActionsEvent(.statsAccessed)

        let controller = StatsViewController()
        controller.blog = blog
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.stats)
    }

    func showPostList() {
        trackQuickActionsEvent(.openedPosts)

        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.blogDetailNavigation)
    }

    func showMediaLibrary() {
        trackQuickActionsEvent(.openedMediaLibrary)

        let controller = MediaLibraryViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.blogDetailNavigation)
    }

    func showPageList() {
        trackQuickActionsEvent(.openedPages)

        let controller = PageListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.pages)
    }

    private func trackQuickActionsEvent(_ event: WPAnalyticsStat) {
        WPAppAnalytics.track(event, withProperties: [WPAppAnalyticsKeyTapSource: "dashboard"], with: blog)
    }
}
