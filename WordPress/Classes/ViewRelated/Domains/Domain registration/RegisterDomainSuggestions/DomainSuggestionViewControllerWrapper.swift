import SwiftUI
import UIKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
final class DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    let site: JetpackSiteRef

    weak var presentingController: RegisterDomainSuggestionsViewController?

    init(site: JetpackSiteRef) {
        self.site = site
    }

    func makeUIViewController(context: Context) -> RegisterDomainSuggestionsViewController {
        let viewController = RegisterDomainSuggestionsViewController
                .instance(site: site, domainPurchasedCallback: { domain in
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
