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
        let coordinator = RegisterDomainCoordinator(site: blog)
        let controller = RegisterDomainSuggestionsViewController
            .instance(coordinator: coordinator,
                      domainSelectionType: .registerWithPaidPlan,
                      domainPurchasedCallback: { [weak self] _, domain in
                WPAnalytics.track(.domainCreditRedemptionSuccess)
                self?.presentDomainCreditRedemptionSuccess(domain: domain)
            })
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain) { [weak self] _ in
            self?.dismiss(animated: true) {
                guard let email = self?.accountEmail() else {
                    return
                }
                let title = String(format: NSLocalizedString("Verify your email address - instructions sent to %@", comment: "Notice displayed after domain credit redemption success."), email)
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: title)))
            }
        }
        present(controller, animated: true) { [weak self] in
            self?.updateTableView {
                guard
                    let parent = self?.parent as? MySiteViewController,
                    let blog = self?.blog
                else {
                    return
                }
                parent.sitePickerViewController?.blogDetailHeaderView.blog = blog
            }
        }
    }

    private func accountEmail() -> String? {
        guard let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext) else {
            return nil
        }
        return defaultAccount.email
    }
}

// MARK: - Domains Dashboard access from My Site
extension BlogDetailsViewController {

    @objc func makeDomainsDashboardViewController() -> UIViewController {
        let viewController = UIHostingController(rootView: DomainsDashboardView(blog: self.blog))
        viewController.extendedLayoutIncludesOpaqueBars = true
        return viewController
    }
}
