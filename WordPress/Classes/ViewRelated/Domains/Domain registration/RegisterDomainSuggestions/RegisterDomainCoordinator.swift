import Foundation
import AutomatticTracks
import WordPressKit

class RegisterDomainCoordinator {

    enum Error: Swift.Error {
        case noDomainWhenCreatingCart
    }

    // MARK: Type Aliases

    typealias DomainPurchasedCallback = ((UIViewController, String) -> Void)
    typealias DomainAddedToCartCallback = ((UIViewController, String, Blog) -> Void)

    // MARK: - Dependencies

    private let domainRegistrationService: RegisterDomainDetailsServiceProxyProtocol

    // MARK: Variables

    private let crashLogger: CrashLogging

    let analyticsSource: String

    var site: Blog?
    var domain: DomainSuggestion?

    var domainPurchasedCallback: DomainPurchasedCallback?
    var domainAddedToCartAndLinkedToSiteCallback: DomainAddedToCartCallback?

    private var webViewURLChangeObservation: NSKeyValueObservation?

    /// Initializes a `RegisterDomainCoordinator` with the specified parameters.
    ///
    /// - Parameters:
    ///   - site: An optional `Blog` object representing the blog associated with the domain registration.
    ///   - domainPurchasedCallback: An optional closure to be called when a domain is successfully purchased.
    ///   - analyticsSource: A string representing the source for analytics tracking. Defaults to `domains_register` if not provided.
    ///   - crashLogger: An instance of `CrashLogging` to handle crash logging. Defaults to `.main` if not provided.
    init(site: Blog?,
         domainPurchasedCallback: RegisterDomainCoordinator.DomainPurchasedCallback? = nil,
         analyticsSource: String = "domains_register",
         crashLogger: CrashLogging = .main,
         domainRegistrationService: RegisterDomainDetailsServiceProxyProtocol = RegisterDomainDetailsServiceProxy()) {
        self.site = site
        self.domainPurchasedCallback = domainPurchasedCallback
        self.crashLogger = crashLogger
        self.analyticsSource = analyticsSource
        self.domainRegistrationService = domainRegistrationService
    }

    // MARK: Public Functions

    /// Adds the selected domain to the cart then launches the checkout webview.
    /// This flow support purchasing domains only, without plans.
    func handlePurchaseDomainOnly(on viewController: UIViewController,
                                  onSuccess: @escaping () -> (),
                                  onFailure: @escaping () -> ()) {
        // TODO: Refactor `handlePurchaseDomainOnly` to use `purchaseDomain` helper.
        createCart { [weak self] result in
            switch result {
            case .success:
                guard let self else { return }
                self.presentCheckoutWebview(on: viewController, title: nil)
                onSuccess()
            case .failure:
                onFailure()
            }
        }
    }

    /// Adds the selected domain to the cart then executes `domainAddedToCartAndLinkedToSiteCallback` if set.
    func addDomainToCartLinkedToCurrentSite(on viewController: UIViewController,
                         onSuccess: @escaping () -> (),
                         onFailure: @escaping () -> ()) {
        // TODO: Refactor `addDomainToCartLinkedToCurrentSite` to use `purchaseDomain` helper.
        guard let blog = site else {
            return
        }
        createCart { [weak self] result in
            switch result {
            case .success(let domain):
                self?.domainAddedToCartAndLinkedToSiteCallback?(viewController, domain.domainName, blog)
                onSuccess()
            case .failure:
                onFailure()
            }
        }
    }

    /// Related to the `purchaseFromDomainManagement` Domain selection type.
    /// Adds the selected domain to the cart then launches the checkout webview
    /// The checkout webview is configured for the domain management flow
    func handleNoSiteChoice(on viewController: UIViewController, choicesViewModel: DomainPurchaseChoicesViewModel?) {
        self.purchaseDomain(for: site, on: viewController) { _ in
            choicesViewModel?.isGetDomainLoading = false
        }
    }

    /// Related to the `purchaseFromDomainManagement` Domain selection type.
    /// Adds the selected domain to the cart then presents a site picker view.
    func handleExistingSiteChoice(on viewController: UIViewController) {
        let config = BlogListConfiguration(
            shouldShowCancelButton: false,
            shouldShowNavBarButtons: false,
            navigationTitle: TextContent.sitePickerNavigationTitle,
            backButtonTitle: TextContent.sitePickerNavigationTitle,
            shouldHideSelfHostedSites: true,
            shouldHideBlogsNotSupportingDomains: true,
            analyticsSource: analyticsSource
        )
        let blogListViewController = BlogListViewController(configuration: config, meScenePresenter: nil)

        blogListViewController.blogSelected = { [weak self] controller, selectedBlog in
            guard let self else {
                return
            }
            controller.showLoading()
            self.purchaseDomain(for: selectedBlog, on: controller) { result in
                controller.hideLoading()
                if case .success = result {
                    self.site = selectedBlog
                }
            }
        }

        viewController.navigationController?.pushViewController(blogListViewController, animated: true)
    }

    func trackDomainPurchasingCompleted() {
        self.track(.purchaseDomainCompleted)
    }

    // MARK: Helpers

    private func purchaseDomain(for site: Blog?, on viewController: UIViewController, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        self.createCart { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let domain):
                if let site, site.canRegisterDomainWithPaidPlan {
                    self.domainAddedToCartAndLinkedToSiteCallback?(viewController, domain.domainName, site)
                } else {
                    self.presentCheckoutWebview(on: viewController, title: TextContent.checkoutTitle)
                }
                completion(.success(()))
            case .failure(let error):
                viewController.displayActionableNotice(title: TextContent.errorTitle, actionTitle: TextContent.errorDismiss)
                completion(.failure(error))
            }
        }
    }

    private func createCart(completion: @escaping (Result<DomainSuggestion, Swift.Error>) -> Void) {
        guard let domain else {
            completion(.failure(Error.noDomainWhenCreatingCart))
            return
        }
        let siteID = site?.dotComID?.intValue
        self.domainRegistrationService.createPersistentDomainShoppingCart(siteID: siteID,
                                                                          domainSuggestion: domain,
                                                                          privacyProtectionEnabled: domain.supportsPrivacy ?? false,
                                                                          success: { _ in
            completion(.success(domain))
        },
                                                                          failure: { error in
            completion(.failure(error))
        })
    }

    private func presentCheckoutWebview(on viewController: UIViewController,
                                        title: String?) {
        guard let domain,
              let url = checkoutURL() else {
            crashLogger.logMessage("Failed to present domain checkout webview.",
                                   level: .error)
            return
        }

        let webViewController = WebViewControllerFactory.controllerWithDefaultAccountAndSecureInteraction(
            url: url,
            source: analyticsSource,
            title: title
        )

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

            self.handleWebViewURLChange(newURL, domain: domain.domainName, onCancel: {
                viewController.dismiss(animated: true)
            }) { domain in
                self.domainPurchasedCallback?(viewController, domain)
                self.trackDomainPurchasingCompleted()
            }
        }

        let properties: [AnyHashable: Any] = {
            if let site {
                return WPAnalytics.domainsProperties(for: site, origin: nil as String?)
            } else {
                return WPAnalytics.domainsProperties(usingCredit: false, origin: nil, domainOnly: true)
            }
        }()
        self.track(.domainsPurchaseWebviewViewed, properties: properties)

        webViewController.configureSandboxStore {
            viewController.navigationController?.pushViewController(webViewController, animated: true)
        }
    }

    private func checkoutURL() -> URL? {
        if let site {
            guard let homeURL = site.homeURL,
                  let siteUrl = URL(string: homeURL as String), let host = siteUrl.host,
                  let url = URL(string: Constants.checkoutWebAddress + host) else {
                return nil
            }
            return url
        } else {
            return URL(string: Constants.noSiteCheckoutWebAddress)
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

    // MARK: - Tracks

    private func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        let defaultProperties: [AnyHashable: Any] = [WPAppAnalyticsKeySource: analyticsSource]

        let properties = defaultProperties.merging(properties ?? [:]) { first, second in
            return first
        }

        if let blog = self.site {
            WPAnalytics.track(event, properties: properties, blog: blog)
        } else {
            WPAnalytics.track(event, properties: properties)
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
        static let sitePickerNavigationTitle = NSLocalizedString("domains.sitePicker.title",
                                                                 value: "Choose Site",
                                                                 comment: "Title of screen where user chooses a site to connect to their selected domain")
    }

    enum Constants {
        static let checkoutWebAddress = "https://wordpress.com/checkout/"
        static let noSiteCheckoutWebAddress = "https://wordpress.com/checkout/no-site?isDomainOnly=1"
        static let checkoutSuccessURLPrefix = "https://wordpress.com/checkout/thank-you/"
    }
}
