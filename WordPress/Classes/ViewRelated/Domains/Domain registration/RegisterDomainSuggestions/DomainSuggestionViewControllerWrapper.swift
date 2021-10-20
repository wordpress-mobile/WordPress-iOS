import SwiftUI
import UIKit
import WordPressKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
final class DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    @SwiftUI.Environment(\.presentationMode) var presentationMode

    private let blog: Blog
    private let domainType: DomainType
    private let onDismiss: () -> Void

    private weak var domainSuggestionViewController: RegisterDomainSuggestionsViewController?
    private weak var wrapperNavigationController: LightNavigationController?

    init(blog: Blog, domainType: DomainType, onDismiss: @escaping () -> Void) {
        self.blog = blog
        self.domainType = domainType
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> LightNavigationController {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)

        let viewController = RegisterDomainSuggestionsViewController
            .instance(site: blog,
                      domainType: domainType,
                      includeSupportButton: false,
                      domainPurchasedCallback: { domain in
                    blogService.syncBlogAndAllMetadata(self.blog) { }
                    WPAnalytics.track(.domainCreditRedemptionSuccess)
                    self.presentDomainCreditRedemptionSuccess(domain: domain)
                })
        domainSuggestionViewController = viewController
        let navigationController = LightNavigationController(rootViewController: viewController)
        wrapperNavigationController = navigationController
        return navigationController
    }

    func updateUIViewController(_ uiViewController: LightNavigationController, context: Context) { }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        guard let presentingController = domainSuggestionViewController else {
            return
        }
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain, delegate: self)
        presentingController.present(controller, animated: true)
    }
}

/// Handles the action after the domain registration confirmation is dismissed - go back to Domains Dashboard
extension DomainSuggestionViewControllerWrapper: DomainCreditRedemptionSuccessViewControllerDelegate {

    func continueButtonPressed(domain: String) {
        domainSuggestionViewController?.dismiss(animated: true) { [weak self] in
            self?.onDismiss()
        }
    }
}
