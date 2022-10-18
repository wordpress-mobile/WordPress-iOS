import SwiftUI
import UIKit
import WordPressKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
struct DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    private let blog: Blog
    private let domainType: DomainType
    private let onDismiss: () -> Void

    private var domainSuggestionViewController: RegisterDomainSuggestionsViewController

    init(blog: Blog, domainType: DomainType, onDismiss: @escaping () -> Void) {
        self.blog = blog
        self.domainType = domainType
        self.onDismiss = onDismiss
        self.domainSuggestionViewController = RegisterDomainSuggestionsViewController.instance(site: blog,
                                                                                               domainType: domainType,
                                                                                               includeSupportButton: false)
    }

    func makeUIViewController(context: Context) -> LightNavigationController {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)

        self.domainSuggestionViewController.domainPurchasedCallback = { domain in
            blogService.syncBlogAndAllMetadata(self.blog) { }
            WPAnalytics.track(.domainCreditRedemptionSuccess)
            self.presentDomainCreditRedemptionSuccess(domain: domain)
        }

        let navigationController = LightNavigationController(rootViewController: domainSuggestionViewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: LightNavigationController, context: Context) { }

    private func presentDomainCreditRedemptionSuccess(domain: String) {

        let controller = DomainCreditRedemptionSuccessViewController(domain: domain) { _ in
            self.domainSuggestionViewController.dismiss(animated: true) {
                self.onDismiss()
            }
        }
        domainSuggestionViewController.present(controller, animated: true)
    }
}
