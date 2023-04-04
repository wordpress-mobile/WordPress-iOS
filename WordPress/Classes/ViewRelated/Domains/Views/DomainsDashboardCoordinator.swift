import UIKit

@objc final class DomainsDashboardCoordinator: NSObject {
    @objc(presentDomainsDashboardWithPresenter:source:blog:)
    static func presentDomainsDashboard(with presenter: BlogDetailsPresentationDelegate,
                                        source: String,
                                        blog: Blog) {
        WPAnalytics.trackEvent(.domainsDashboardViewed, properties: [WPAppAnalyticsKeySource: source], blog: blog)
        let controller = DomainsDashboardFactory.makeDomainsDashboardViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presenter.presentBlogDetailsViewController(controller)
    }
}
