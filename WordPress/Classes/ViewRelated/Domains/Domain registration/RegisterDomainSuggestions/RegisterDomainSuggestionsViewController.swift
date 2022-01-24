import SwiftUI
import UIKit
import WebKit
import WordPressAuthenticator
import WordPressFlux

class RegisterDomainSuggestionsViewController: UIViewController {
    @IBOutlet weak var buttonContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!

    private var constraintsInitialized = false

    private var site: Blog!
    private var domainPurchasedCallback: ((String) -> Void)!

    private var domain: FullyQuotedDomainSuggestion?
    private var siteName: String?
    private var domainsTableViewController: DomainSuggestionsTableViewController?
    private var domainType: DomainType = .registered
    private var includeSupportButton: Bool = true

    private var webViewURLChangeObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        hideButton()
    }

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.view.backgroundColor = .basicBackground
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: TextContent.primaryButtonTitle
        )
        return buttonViewController
    }()

    static func instance(site: Blog,
                         domainType: DomainType = .registered,
                         includeSupportButton: Bool = true,
                         domainPurchasedCallback: @escaping ((String) -> Void)) -> RegisterDomainSuggestionsViewController {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: Constants.viewControllerIdentifier) as! RegisterDomainSuggestionsViewController
        controller.site = site
        controller.domainType = domainType
        controller.domainPurchasedCallback = domainPurchasedCallback
        controller.includeSupportButton = includeSupportButton
        controller.siteName = siteNameForSuggestions(for: site)

        return controller
    }

    private static func siteNameForSuggestions(for site: Blog) -> String? {
        if let siteTitle = site.settings?.name?.nonEmptyString() {
            return siteTitle
        }

        if let siteUrl = site.url {
            let components = URLComponents(string: siteUrl)
            if let firstComponent = components?.host?.split(separator: ".").first {
                return String(firstComponent)
            }
        }

        return nil
    }

    private func configure() {
        title = TextContent.title
        WPStyleGuide.configureColors(view: view, tableView: nil)

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton

        guard includeSupportButton else {
            return
        }

        let supportButton = UIBarButtonItem(title: TextContent.supportButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(handleSupportButtonTapped))
        navigationItem.rightBarButtonItem = supportButton
    }

    // MARK: - Bottom Hideable Button

    /// Shows the domain picking button
    ///
    private func showButton() {
        buttonContainerBottomConstraint.constant = 0
    }

    /// Shows the domain picking button
    ///
    /// - Parameters:
    ///     - animated: whether the transition is animated.
    ///
    private func showButton(animated: Bool) {
        guard animated else {
            showButton()
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { [weak self] in
            guard let self = self else {
                return
            }

            self.showButton()

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func hideButton() {
        buttonContainerBottomConstraint.constant = buttonViewContainer.frame.height
    }

    /// Hides the domain picking button
    ///
    /// - Parameters:
    ///     - animated: whether the transition is animated.
    ///
    func hideButton(animated: Bool) {
        guard animated else {
            hideButton()
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { [weak self] in
            guard let self = self else {
                return
            }

            self.hideButton()

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? DomainSuggestionsTableViewController {
            vc.delegate = self
            vc.siteName = siteName
            vc.blog = site
            vc.domainType = domainType
            vc.freeSiteAddress = site.freeSiteAddress

            if site.hasBloggerPlan {
                vc.domainSuggestionType = .allowlistedTopLevelDomains(["blog"])
            }

            domainsTableViewController = vc
        }
    }

    // MARK: - Nav Bar Button Handling

    @objc private func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @objc private func handleSupportButtonTapped(sender: UIBarButtonItem) {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }

}

// MARK: - DomainSuggestionsTableViewControllerDelegate

extension RegisterDomainSuggestionsViewController: DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: FullyQuotedDomainSuggestion) {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionSelected)
        self.domain = domain
        showButton(animated: true)
    }

    func newSearchStarted() {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionQueried)
        hideButton(animated: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension RegisterDomainSuggestionsViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        guard let domain = domain else {
            return
        }

        WPAnalytics.track(.domainsSearchSelectDomainTapped, properties: WPAnalytics.domainsProperties(for: site), blog: site)

        switch domainType {
        case .registered:
            pushRegisterDomainDetailsViewController(domain)
        case .siteRedirect:
            setPrimaryButtonLoading(true)
            createCartAndPresentWebView(domain)
        default:
            break
        }
    }

    private func setPrimaryButtonLoading(_ isLoading: Bool, afterDelay delay: Double = 0.0) {
        // We're dispatching here so that we can wait until after the webview has been
        // fully presented before we switch the button back to its default state.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.buttonViewController.setBottomButtonState(isLoading: isLoading,
                                                           isEnabled: !isLoading)
        }
    }

    private func pushRegisterDomainDetailsViewController(_ domain: FullyQuotedDomainSuggestion) {
        guard let siteID = site.dotComID?.intValue else {
            DDLogError("Cannot register domains for sites without a dotComID")
            return
        }

        let controller = RegisterDomainDetailsViewController()
        controller.viewModel = RegisterDomainDetailsViewModel(siteID: siteID, domain: domain, domainPurchasedCallback: domainPurchasedCallback)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func createCartAndPresentWebView(_ domain: FullyQuotedDomainSuggestion) {
        guard let siteID = site.dotComID?.intValue else {
            DDLogError("Cannot register domains for sites without a dotComID")
            return
        }

        let proxy = RegisterDomainDetailsServiceProxy()
        proxy.createPersistentDomainShoppingCart(siteID: siteID,
                                                 domainSuggestion: domain.remoteSuggestion(),
                                                 privacyProtectionEnabled: domain.supportsPrivacy ?? false,
                                                 success: { [weak self] _ in
            self?.presentWebViewForCurrentSite(domainSuggestion: domain)
            self?.setPrimaryButtonLoading(false, afterDelay: 0.25)
        },
                                                 failure: { error in })
    }

    static private let checkoutURLPrefix = "https://wordpress.com/checkout"
    static private let checkoutSuccessURLPrefix = "https://wordpress.com/checkout/thank-you/"

    /// Handles URL changes in the web view.  We only allow the user to stay within certain URLs.  Falling outside these URLs
    /// results in the web view being dismissed.  This method also handles the success condition for a successful domain registration
    /// through said web view.
    ///
    /// - Parameters:
    ///     - newURL: the newly set URL for the web view.
    ///     - siteID: the ID of the site we're trying to register the domain against.
    ///     - domain: the domain the user is purchasing.
    ///     - onCancel: the closure that will be executed if we detect the conditions for cancelling the registration were met.
    ///     - onSuccess: the closure that will be executed if we detect a successful domain registration.
    ///
    private func handleWebViewURLChange(
        _ newURL: URL,
        siteID: Int,
        domain: String,
        onCancel: () -> Void,
        onSuccess: (String) -> Void) {

        let canOpenNewURL = newURL.absoluteString.starts(with: Self.checkoutURLPrefix)

        guard canOpenNewURL else {
            onCancel()
            return
        }

        let domainRegistrationSucceeded = newURL.absoluteString.starts(with: Self.checkoutSuccessURLPrefix)

        if domainRegistrationSucceeded {

            let registerDomainService = RegisterDomainDetailsServiceProxy()

            registerDomainService.recordDomainPurchase(
                siteID: siteID,
                domain: domain,
                isPrimaryDomain: false)

            onSuccess(domain)
            return
        }
    }

    private func presentWebViewForCurrentSite(domainSuggestion: FullyQuotedDomainSuggestion) {
        guard let homeURL = site.homeURL,
              let siteUrl = URL(string: homeURL as String), let host = siteUrl.host,
              let url = URL(string: Constants.checkoutWebAddress + host),
              let siteID = site.dotComID?.intValue else {
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

            self.handleWebViewURLChange(newURL, siteID: siteID, domain: domainSuggestion.domainName, onCancel: {
                navController.dismiss(animated: true)
            }) { domain in
                self.dismiss(animated: true, completion: { [weak self] in
                    self?.domainPurchasedCallback(domain)
                })
            }
        }

        WPAnalytics.track(.domainsPurchaseWebviewViewed, properties: WPAnalytics.domainsProperties(for: site), blog: site)

        if let storeSandboxCookie = (HTTPCookieStorage.shared.cookies?.first {

            $0.properties?[.name] as? String == Constants.storeSandboxCookieName &&
            $0.properties?[.domain] as? String == Constants.storeSandboxCookieDomain
        }) {
            // this code will only run if a store sandbox cookie has been set
            let webView = webViewController.webView
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            cookieStore.getAllCookies { [weak self] cookies in

                    var newCookies = cookies
                    newCookies.append(storeSandboxCookie)

                    cookieStore.setCookies(newCookies) {
                        self?.present(navController, animated: true)
                    }
            }
        } else {
            present(navController, animated: true)
        }
    }
}

// MARK: - Constants
extension RegisterDomainSuggestionsViewController {

    enum TextContent {

        static let title = NSLocalizedString("Search domains",
                                             comment: "Search domain - Title for the Suggested domains screen")
        static let primaryButtonTitle = NSLocalizedString("Select domain",
                                                          comment: "Register domain - Title for the Choose domain button of Suggested domains screen")
        static let supportButtonTitle = NSLocalizedString("Help", comment: "Help button")
    }

    enum Constants {
        // storyboard identifiers
        static let storyboardIdentifier = "RegisterDomain"
        static let viewControllerIdentifier = "RegisterDomainSuggestionsViewController"

        static let checkoutWebAddress = "https://wordpress.com/checkout/"
        // store sandbox cookie
        static let storeSandboxCookieName = "store_sandbox"
        static let storeSandboxCookieDomain = ".wordpress.com"
    }
}
