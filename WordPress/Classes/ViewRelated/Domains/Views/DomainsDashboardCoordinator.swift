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

    static func presentDomainsSuggestions(in dashboardViewController: BlogDashboardViewController,
                                          source: String,
                                          blog: Blog) {
        let domainType: DomainType = blog.canRegisterDomainWithPaidPlan ? .registered : .siteRedirect
        let controller = DomainsDashboardFactory.makeDomainsSuggestionViewController(blog: blog, domainType: domainType) {
            dashboardViewController.navigationController?.popViewController(animated: true)
        }
        controller.navigationItem.largeTitleDisplayMode = .never
        dashboardViewController.show(controller, sender: nil)
    }
}
