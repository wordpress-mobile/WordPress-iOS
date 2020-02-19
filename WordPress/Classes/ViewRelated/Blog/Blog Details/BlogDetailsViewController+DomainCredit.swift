import Gridicons
import WordPressFlux

extension BlogDetailsViewController {
    @objc func domainCreditSectionViewModel() -> BlogDetailsSection {
        let image = Gridicon.iconOfType(.info)
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
        guard let site = JetpackSiteRef(blog: blog) else {
            DDLogError("Error: couldn't initialize `JetpackSiteRef` from blog with ID: \(blog.dotComID?.intValue ?? 0)")
            let cancelActionTitle = NSLocalizedString(
                "OK",
                comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt."
            )
            let alertController = UIAlertController(
                title: NSLocalizedString("Unable to register domain", comment: "Alert title when `JetpackSiteRef` cannot be initialized from a blog during domain credit redemption."),
                message: NSLocalizedString("Something went wrong, please try again.", comment: "Alert message when `JetpackSiteRef` cannot be initialized from a blog during domain credit redemption."),
                preferredStyle: .alert
            )
            alertController.addCancelActionWithTitle(cancelActionTitle, handler: nil)
            present(alertController, animated: true, completion: nil)
            return
        }
        let controller = RegisterDomainSuggestionsViewController
            .instance(site: site, domainPurchasedCallback: { [weak self] domain in
                WPAnalytics.track(.domainCreditRedemptionSuccess)
                self?.presentDomainCreditRedemptionSuccess(domain: domain)
            })
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
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
