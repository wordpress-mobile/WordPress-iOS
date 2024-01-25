import Foundation
import SwiftUI

struct DomainsDashboardFactory {
    static func makeDomainsDashboardViewController(blog: Blog) -> UIViewController {
        let viewController = SiteDomainsViewController(blog: blog)
        viewController.extendedLayoutIncludesOpaqueBars = true
        return viewController
    }

    static func makeDomainsSuggestionViewController(blog: Blog, domainSelectionType: DomainSelectionType, onDismiss: @escaping () -> Void) -> DomainSelectionViewController {
        let coordinator = RegisterDomainCoordinator(site: blog, analyticsSource: "site_domains")
        let viewController = DomainSelectionViewController(
            service: DomainsServiceAdapter(coreDataStack: ContextManager.shared),
            domainSelectionType: domainSelectionType,
            includeSupportButton: false,
            coordinator: coordinator
        )

        coordinator.domainPurchasedCallback = { viewController, domain in
            let blogService = BlogService(coreDataStack: ContextManager.shared)
            blogService.syncBlogAndAllMetadata(blog) { }
            WPAnalytics.track(.domainCreditRedemptionSuccess)
            let controller = DomainCreditRedemptionSuccessViewController(domain: domain) { _ in
                viewController.dismiss(animated: true) {
                    onDismiss()
                }
            }
            viewController.present(controller, animated: true)
        }

        return viewController
    }
}
