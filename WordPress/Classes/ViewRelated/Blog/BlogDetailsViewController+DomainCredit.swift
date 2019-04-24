import Gridicons

extension BlogDetailsViewController {
    @objc func domainCreditSectionViewModel() -> BlogDetailsSection {
        let image = Gridicon.iconOfType(.info)
        let row = BlogDetailsRow(title: NSLocalizedString("Register Domain", comment: "Action to redeem domain credit."),
                                 accessibilityIdentifier: "Register domain from site dashboard",
                                 image: image, imageColor: WPStyleGuide.warningYellow()) { [weak self] in
                                    self?.showDomainCreditRedemption()
        }
        row.hasNoAccessory = true
        return BlogDetailsSection(title: nil,
                                  rows: [row],
                                  footerTitle: NSLocalizedString("All WordPress.com plans include a custom domain name. Register your free premium domain now.", comment: "Information about redeeming domain credit on site dashboard."),
                                  category: .domainCredit)
    }

    @objc func showDomainCreditRedemption() {
        // TODO-#11467 - subtask - integration with domain registration.
    }
}
