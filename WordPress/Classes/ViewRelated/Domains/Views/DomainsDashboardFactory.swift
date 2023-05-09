import Foundation
import SwiftUI

struct DomainsDashboardFactory {
    static func makeDomainsDashboardViewController(blog: Blog) -> UIViewController {
        let viewController = UIHostingController(rootView: DomainsDashboardView(blog: blog))
        viewController.extendedLayoutIncludesOpaqueBars = true
        return viewController
    }

    static func makeDomainsSuggestionViewController(blog: Blog, domainType: DomainType, onDismiss: @escaping () -> Void) -> RegisterDomainSuggestionsViewController {
        let viewController = RegisterDomainSuggestionsViewController.instance(
            site: blog,
            domainType: domainType,
            includeSupportButton: false)

        viewController.domainPurchasedCallback = { domain in
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
