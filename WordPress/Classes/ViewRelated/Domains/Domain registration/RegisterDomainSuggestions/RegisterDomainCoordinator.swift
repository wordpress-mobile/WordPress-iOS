import Foundation

class RegisterDomainCoordinator {

    // MARK: Type Aliases

    typealias DomainPurchasedCallback = ((UIViewController, String) -> Void)
    typealias DomainAddedToCartCallback = ((UIViewController, String) -> Void)

    // MARK: Variables

    var site: Blog?
    var domainPurchasedCallback: DomainPurchasedCallback?
    var domainAddedToCartCallback: DomainAddedToCartCallback?
    var domain: FullyQuotedDomainSuggestion?

    private var webViewURLChangeObservation: NSKeyValueObservation?

    init(site: Blog?) {
        self.site = site
    }

    // MARK: Public Functions

    func createCart(_ domain: FullyQuotedDomainSuggestion,
                    onSuccess: @escaping () -> (),
                    onFailure: @escaping () -> ()) {
        let siteID = site?.dotComID?.intValue
        let proxy = RegisterDomainDetailsServiceProxy()
        proxy.createPersistentDomainShoppingCart(siteID: siteID,
                                                 domainSuggestion: domain.remoteSuggestion(),
                                                 privacyProtectionEnabled: domain.supportsPrivacy ?? false,
                                                 success: { _ in
            onSuccess()
        },
                                                 failure: { _ in
            onFailure()
        })
    }

    func presentWebViewForNoSite(on viewController: UIViewController,
                                 domainSuggestion: FullyQuotedDomainSuggestion) {
        guard let url = URL(string: Constants.noSiteCheckoutWebAddress) else {
            return
        }

        let webViewController = WebViewControllerFactory.controllerWithDefaultAccountAndSecureInteraction(url: url,
                                                                                                          source: "domains_register", // TODO: Update source
                                                                                                          title: TextContent.checkoutTitle)

        // WORKAROUND: The reason why we have to use this mechanism to detect success and failure conditions
        // for domain registration is because our checkout process (for some unknown reason) doesn't trigger
        // call to WKWebViewDelegate methods.
        //
        // This was last checked by @diegoreymendez on 2021-09-22.
        //
        webViewURLChangeObservation = webViewController.webView.observe(\.url, options: .new) { [weak self] _, change in
            guard let self = self,
                  let newURL = change.newValue as? URL else {
                return
            }

            self.handleWebViewURLChange(newURL, domain: domainSuggestion.domainName, onCancel: {
                viewController.navigationController?.popViewController(animated: true)
            }) { domain in
                viewController.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainPurchasedCallback?(viewController, domain)
                })
            }
        }

        // TODO: Track showing no site checkout

        webViewController.configureSandboxStore {
            viewController.navigationController?.pushViewController(webViewController, animated: true)
        }
    }

    func presentWebViewForCurrentSite(on viewController: UIViewController,
                                              domainSuggestion: FullyQuotedDomainSuggestion) {
        guard let site,
              let homeURL = site.homeURL,
              let siteUrl = URL(string: homeURL as String), let host = siteUrl.host,
              let url = URL(string: Constants.checkoutWebAddress + host) else {
            return
        }

        let webViewController = WebViewControllerFactory.controllerWithDefaultAccountAndSecureInteraction(url: url, source: "domains_register")
        let navController = LightNavigationController(rootViewController: webViewController)

        // WORKAROUND: The reason why we have to use this mechanism to detect success and failure conditions
        // for domain registration is because our checkout process (for some unknown reason) doesn't trigger
        // call to WKWebViewDelegate methods.
        //
        // This was last checked by @diegoreymendez on 2021-09-22.
        //
        webViewURLChangeObservation = webViewController.webView.observe(\.url, options: .new) { [weak self] _, change in
            guard let self = self,
                  let newURL = change.newValue as? URL else {
                return
            }

            self.handleWebViewURLChange(newURL, domain: domainSuggestion.domainName, onCancel: {
                navController.dismiss(animated: true)
            }) { domain in
                viewController.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainPurchasedCallback?(viewController, domain)
                })
            }
        }

        WPAnalytics.track(.domainsPurchaseWebviewViewed, properties: WPAnalytics.domainsProperties(for: site), blog: site)

        webViewController.configureSandboxStore {
            viewController.present(navController, animated: true)
        }
    }

    func handleNoSiteChoice(on viewController: UIViewController, domain: FullyQuotedDomainSuggestion) {
        createCart(
            domain,
            onSuccess: { [weak self] in
                self?.presentWebViewForNoSite(on: viewController, domainSuggestion: domain)
            }) {
                viewController.displayActionableNotice(title: TextContent.errorTitle, actionTitle: TextContent.errorDismiss)
            }
    }

    func handleExistingSiteChoice(on viewController: UIViewController, domain: FullyQuotedDomainSuggestion) {
        print("handleExistingSiteChoice")
    }

    // MARK: Helpers

    /// Handles URL changes in the web view.  We only allow the user to stay within certain URLs.  Falling outside these URLs
    /// results in the web view being dismissed.  This method also handles the success condition for a successful domain registration
    /// through said web view.
    ///
    /// - Parameters:
    ///     - newURL: the newly set URL for the web view.
    ///     - domain: the domain the user is purchasing.
    ///     - onCancel: the closure that will be executed if we detect the conditions for cancelling the registration were met.
    ///     - onSuccess: the closure that will be executed if we detect a successful domain registration.
    ///
    private func handleWebViewURLChange(
        _ newURL: URL,
        domain: String,
        onCancel: () -> Void,
        onSuccess: (String) -> Void) {

        let canOpenNewURL = newURL.absoluteString.starts(with: Constants.checkoutWebAddress)

        guard canOpenNewURL else {
            onCancel()
            return
        }

        let domainRegistrationSucceeded = newURL.absoluteString.starts(with: Constants.checkoutSuccessURLPrefix)

        if domainRegistrationSucceeded {
            onSuccess(domain)

        }
    }
}

// MARK: - Constants
extension RegisterDomainCoordinator {

    enum TextContent {
        static let errorTitle = NSLocalizedString("domains.failure.title",
                                                  value: "Sorry, the domain you are trying to add cannot be bought on the Jetpack app at this time.",
                                                  comment: "Content show when the domain selection action fails.")
        static let errorDismiss = NSLocalizedString("domains.failure.dismiss",
                                                    value: "Dismiss",
                                                    comment: "Action shown in a bottom notice to dismiss it.")
        static let checkoutTitle = NSLocalizedString("domains.checkout.title",
                                                     value: "Checkout",
                                                     comment: "Title for the checkout screen.")
    }

    enum Constants {
        static let checkoutWebAddress = "https://wordpress.com/checkout/"
        static let noSiteCheckoutWebAddress = "https://wordpress.com/checkout/no-site?isDomainOnly=1"
        static let checkoutSuccessURLPrefix = "https://wordpress.com/checkout/thank-you/"
    }
}
