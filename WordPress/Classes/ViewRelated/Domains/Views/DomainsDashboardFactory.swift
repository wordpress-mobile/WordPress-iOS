import Foundation
import SwiftUI

struct DomainsDashboardFactory {
    static func makeDomainsDashboardViewController(blog: Blog) -> UIViewController {
        let viewController = SiteDomainsViewController(blog: blog)
        viewController.extendedLayoutIncludesOpaqueBars = true
        return viewController
    }

    static func makeDomainsSuggestionViewController(blog: Blog, domainSelectionType: DomainSelectionType, onDismiss: @escaping () -> Void) -> RegisterDomainSuggestionsViewController {
        let coordinator = RegisterDomainCoordinator(site: blog)
        let viewController = RegisterDomainSuggestionsViewController.instance(
            coordinator: coordinator,
            domainSelectionType: domainSelectionType,
            includeSupportButton: false)

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

        let domainAddedToCart = FreeToPaidPlansCoordinator.plansFlowAfterDomainAddedToCartBlock(
            customTitle: nil,
            analyticsSource: "site_domains"
        ) { [weak coordinator] controller, domain in
            coordinator?.domainPurchasedCallback?(controller, domain)
            coordinator?.trackDomainPurchasingCompleted()
        }

        coordinator.domainAddedToCartAndLinkedToSiteCallback = domainAddedToCart

        return viewController
    }
}
