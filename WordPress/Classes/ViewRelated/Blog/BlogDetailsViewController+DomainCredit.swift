import Gridicons
import WordPressFlux

extension BlogDetailsViewController {
    @objc func domainCreditSectionViewModel() -> BlogDetailsSection {
        let image = Gridicon.iconOfType(.info)
        let row = BlogDetailsRow(title: NSLocalizedString("Register Domain", comment: "Action to redeem domain credit."),
                                 accessibilityIdentifier: "Register domain from site dashboard",
                                 image: image, imageColor: WPStyleGuide.warningYellow()) { [weak self] in
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
        // TODO-#11467 - subtask - integration with domain registration.
        // Temporarily shows success screen before domain registration is integrated.
        let domain = "lifeoftea.com"
        presentDomainCreditRedemptionSuccess(domain: domain)
    }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain, delegate: self)
        present(controller, animated: true, completion: nil)
    }
}

extension BlogDetailsViewController: DomainCreditRedemptionSuccessViewControllerDelegate {
    func continueButtonPressed() {
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
