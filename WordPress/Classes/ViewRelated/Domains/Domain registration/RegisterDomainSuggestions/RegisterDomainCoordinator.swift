import Foundation
import AutomatticTracks

class RegisterDomainCoordinator {

    // MARK: Type Aliases

    typealias DomainPurchasedCallback = ((UIViewController, String) -> Void)
    typealias DomainAddedToCartCallback = ((UIViewController, String) -> Void)

    // MARK: Variables

    private let crashLogger: CrashLogging

    var site: Blog?
    var domainPurchasedCallback: DomainPurchasedCallback?
    var domainAddedToCartCallback: DomainAddedToCartCallback?
    var domain: FullyQuotedDomainSuggestion?

    private var webViewURLChangeObservation: NSKeyValueObservation?

    init(site: Blog?,
         domainPurchasedCallback: RegisterDomainCoordinator.DomainPurchasedCallback? = nil,
         crashLogger: CrashLogging = .main) {
        self.site = site
        self.domainPurchasedCallback = domainPurchasedCallback
        self.crashLogger = crashLogger
    }

    // MARK: Public Functions

    func createCart(onSuccess: @escaping () -> (),
                    onFailure: @escaping () -> ()) {
        guard let domain else { return }
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

    func presentWebViewForNoSite(on viewController: UIViewController) {
        guard let domain,
              let url = URL(string: Constants.noSiteCheckoutWebAddress) else {
            crashLogger.logMessage("Failed to present domain checkout webview for no-site.",
                                   level: .error)
            return
        }

        presentCheckoutWebview(on: viewController,
                               domainSuggestion: domain,
                               url: url,
                               title: TextContent.checkoutTitle,
                               shouldPush: true)
    }

    func presentWebViewForCurrentSite(on viewController: UIViewController) {
        guard let domain,
              let site,
              let homeURL = site.homeURL,
              let siteUrl = URL(string: homeURL as String), let host = siteUrl.host,
              let url = URL(string: Constants.checkoutWebAddress + host) else {
            crashLogger.logMessage("Failed to present domain checkout webview for current site.",
                                   level: .error)
            return
        }

        presentCheckoutWebview(on: viewController,
                               domainSuggestion: domain,
                               url: url,
                               title: nil,
                               shouldPush: false)
    }

    func handleNoSiteChoice(on viewController: UIViewController) {
        createCart(
            onSuccess: { [weak self] in
                self?.presentWebViewForNoSite(on: viewController)
            }) {
                viewController.displayActionableNotice(title: TextContent.errorTitle, actionTitle: TextContent.errorDismiss)
            }
    }

    func handleExistingSiteChoice(on viewController: UIViewController) {
        print("handleExistingSiteChoice")
    }

    // MARK: Helpers

    private func presentCheckoutWebview(on viewController: UIViewController,
                                        domainSuggestion: FullyQuotedDomainSuggestion,
                                        url: URL,
                                        title: String?,
                                        shouldPush: Bool) {

        let webViewController = WebViewControllerFactory.controllerWithDefaultAccountAndSecureInteraction(
            url: url,
            source: "domains_register", // TODO: Update source
            title: title)
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
                if shouldPush {
                    viewController.navigationController?.popViewController(animated: true)
                } else {
                    navController.dismiss(animated: true)
                }
            }) { domain in
                viewController.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainPurchasedCallback?(viewController, domain)
                })
            }
        }

        if let site {
            WPAnalytics.track(.domainsPurchaseWebviewViewed, properties: WPAnalytics.domainsProperties(for: site), blog: site)
        } else {
            // TODO: Track showing no site checkout
        }

        webViewController.configureSandboxStore {
            if shouldPush {
                viewController.navigationController?.pushViewController(webViewController, animated: true)
            } else {
                viewController.present(navController, animated: true)
            }
        }
    }

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
