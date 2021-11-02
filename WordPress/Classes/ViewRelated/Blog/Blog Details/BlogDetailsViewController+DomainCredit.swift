import Gridicons
import SwiftUI
import WordPressFlux

extension BlogDetailsViewController {
    @objc func domainCreditSectionViewModel() -> BlogDetailsSection {
        let image = UIImage.gridicon(.info)
        let row = BlogDetailsRow(title: NSLocalizedString("Register Domain", comment: "Action to redeem domain credit."),
                                 accessibilityIdentifier: "Register domain from site dashboard",
                                 image: image,
                                 imageColor: UIColor.warning(.shade20)) { [weak self] in
                                    WPAnalytics.track(.domainCreditRedemptionTapped)
                                    self?.showDomainCreditRedemption()
        }
        row.showsDisclosureIndicator = false
        row.showsSelectionState = false
        return BlogDetailsSection(title: nil,
                                  rows: [row],
                                  footerTitle: NSLocalizedString("All WordPress.com plans include a custom domain name. Register your free premium domain now.", comment: "Information about redeeming domain credit on site dashboard."),
                                  category: .domainCredit)
    }

    @objc func showDomainCreditRedemption() {
        let controller = RegisterDomainSuggestionsViewController
            .instance(site: blog, domainPurchasedCallback: { [weak self] domain in
                WPAnalytics.track(.domainCreditRedemptionSuccess)
                self?.presentDomainCreditRedemptionSuccess(domain: domain)
            })
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain, delegate: self)
        present(controller, animated: true) { [weak self] in
            self?.updateTableViewAndHeader()
        }
    }
}

extension BlogDetailsViewController: DomainCreditRedemptionSuccessViewControllerDelegate {
    func continueButtonPressed(domain: String) {
        dismiss(animated: true) { [weak self] in
            guard let email = self?.accountEmail() else {
                return
            }
            let title = String(format: NSLocalizedString("Verify your email address - instructions sent to %@", comment: "Notice displayed after domain credit redemption success."), email)
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: title)))
        }
    }

    private func accountEmail() -> String? {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            return nil
        }
        return defaultAccount.email
    }
}

// MARK: - Domains Dashboard access from My Site
extension BlogDetailsViewController {

    @objc func makeDomainsDashboardViewController() -> UIViewController {
        UIHostingController(rootView: DomainsDashboardView(blog: self.blog))
    }
}
