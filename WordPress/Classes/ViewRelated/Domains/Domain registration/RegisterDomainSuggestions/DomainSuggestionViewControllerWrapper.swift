import SwiftUI
import UIKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
final class DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    let blog: Blog

    weak var presentingController: RegisterDomainSuggestionsViewController?

    init(blog: Blog) {
        self.blog = blog
    }

    func makeUIViewController(context: Context) -> RegisterDomainSuggestionsViewController {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        let viewController = RegisterDomainSuggestionsViewController
                .instance(site: JetpackSiteRef(blog: blog)!, domainPurchasedCallback: { domain in
                    blogService.syncBlogAndAllMetadata(self.blog) { }
                    WPAnalytics.track(.domainCreditRedemptionSuccess)
                    self.presentDomainCreditRedemptionSuccess(domain: domain)
                })
        presentingController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: RegisterDomainSuggestionsViewController, context: Context) {

    }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        guard let presentingController = presentingController else {
            return
        }
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain, delegate: presentingController)
        presentingController.present(controller, animated: true)
    }
}
