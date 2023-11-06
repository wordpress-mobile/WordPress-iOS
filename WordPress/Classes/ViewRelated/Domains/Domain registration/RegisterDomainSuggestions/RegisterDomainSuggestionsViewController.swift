import SwiftUI
import UIKit
import WebKit
import WordPressAuthenticator
import WordPressFlux

enum DomainSelectionType {
    case registerWithPaidPlan
    case purchaseWithPaidPlan
    case purchaseSeparately
    case purchaseFromDomainManagement
}

class RegisterDomainSuggestionsViewController: UIViewController {
    typealias DomainPurchasedCallback = ((RegisterDomainSuggestionsViewController, String) -> Void)
    typealias DomainAddedToCartCallback = ((RegisterDomainSuggestionsViewController, String) -> Void)

    @IBOutlet weak var buttonContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!

    private var constraintsInitialized = false

    private var site: Blog?
    var domainPurchasedCallback: DomainPurchasedCallback?
    var domainAddedToCartCallback: DomainAddedToCartCallback?

    private var domain: FullyQuotedDomainSuggestion?
    private var siteName: String?
    private var domainsTableViewController: DomainSuggestionsTableViewController?
    private var domainSelectionType: DomainSelectionType = .registerWithPaidPlan
    private var includeSupportButton: Bool = true
    private var navBarTitle: String = TextContent.title

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

    static func instance(site: Blog?,
                         domainSelectionType: DomainSelectionType = .registerWithPaidPlan,
                         includeSupportButton: Bool = true,
                         title: String = TextContent.title,
                         domainPurchasedCallback: DomainPurchasedCallback? = nil) -> RegisterDomainSuggestionsViewController {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: Constants.viewControllerIdentifier) as! RegisterDomainSuggestionsViewController
        controller.site = site
        controller.domainSelectionType = domainSelectionType
        controller.domainPurchasedCallback = domainPurchasedCallback
        controller.includeSupportButton = includeSupportButton
        controller.siteName = siteNameForSuggestions(for: site)
        controller.navBarTitle = title

        return controller
    }

    private static func siteNameForSuggestions(for site: Blog?) -> String? {
        guard let site else {
            return nil
        }

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
        title = navBarTitle
        WPStyleGuide.configureColors(view: view, tableView: nil)

        /// If this is the first view controller in the navigation controller - show the cancel button
        if navigationController?.children.count == 1 {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                               target: self,
                                               action: #selector(handleCancelButtonTapped))
            navigationItem.leftBarButtonItem = cancelButton
        }

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
        buttonViewContainer.layoutIfNeeded()
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
            vc.domainSelectionType = domainSelectionType
            vc.primaryDomainAddress = site?.primaryDomainAddress

            if site?.hasBloggerPlan == true {
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
        if let site {
            WPAnalytics.track(.domainsSearchSelectDomainTapped, properties: WPAnalytics.domainsProperties(for: site), blog: site)
        } else {
            WPAnalytics.track(.domainsSearchSelectDomainTapped)
        }

        let onFailure: () -> () = { [weak self] in
            self?.displayActionableNotice(title: TextContent.errorTitle, actionTitle: TextContent.errorDismiss)
            self?.setPrimaryButtonLoading(false, afterDelay: 0.25)
        }

        switch domainSelectionType {
        case .registerWithPaidPlan:
            pushRegisterDomainDetailsViewController(domain)
        case .purchaseSeparately:
            setPrimaryButtonLoading(true)
            createCart(
                domain,
                onSuccess: { [weak self] in
                    self?.presentWebViewForCurrentSite(domainSuggestion: domain)
                    self?.setPrimaryButtonLoading(false, afterDelay: 0.25)
                },
                onFailure: onFailure
            )
        case .purchaseWithPaidPlan:
            setPrimaryButtonLoading(true)
            createCart(
                domain,
                onSuccess: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainAddedToCartCallback?(self, domain.domainName)
                    self.setPrimaryButtonLoading(false, afterDelay: 0.25)
                },
                onFailure: onFailure
            )
        case .purchaseFromDomainManagement:
            print("Hello world")
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
        guard let siteID = site?.dotComID?.intValue else {
            DDLogError("Cannot register domains for sites without a dotComID")
            return
        }

        let controller = RegisterDomainDetailsViewController()
        controller.viewModel = RegisterDomainDetailsViewModel(siteID: siteID, domain: domain) { [weak self] name in
            guard let self = self else {
                return
            }

            self.domainPurchasedCallback?(self, name)
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // TODO: Create a counterpart that handles no site
    private func createCart(_ domain: FullyQuotedDomainSuggestion,
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

    static private let checkoutURLPrefix = "https://wordpress.com/checkout"
    static private let checkoutSuccessURLPrefix = "https://wordpress.com/checkout/thank-you/"

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

        let canOpenNewURL = newURL.absoluteString.starts(with: Self.checkoutURLPrefix)

        guard canOpenNewURL else {
            onCancel()
            return
        }

        let domainRegistrationSucceeded = newURL.absoluteString.starts(with: Self.checkoutSuccessURLPrefix)

        if domainRegistrationSucceeded {
            onSuccess(domain)

        }
    }

    private func presentWebViewForCurrentSite(domainSuggestion: FullyQuotedDomainSuggestion) {
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
                self.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainPurchasedCallback?(self, domain)
                })
            }
        }

        WPAnalytics.track(.domainsPurchaseWebviewViewed, properties: WPAnalytics.domainsProperties(for: site), blog: site)

        webViewController.configureSandboxStore { [weak self] in
            self?.present(navController, animated: true)
        }
    }

    private func presentWebViewForNoSite(domainSuggestion: FullyQuotedDomainSuggestion) {
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
                self.navigationController?.popViewController(animated: true)
            }) { domain in
                self.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.domainPurchasedCallback?(self, domain)
                })
            }
        }

        // TODO: Track showing no site checkout

        webViewController.configureSandboxStore { [weak self] in
            self?.navigationController?.pushViewController(webViewController, animated: true)
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
        // storyboard identifiers
        static let storyboardIdentifier = "RegisterDomain"
        static let viewControllerIdentifier = "RegisterDomainSuggestionsViewController"

        static let checkoutWebAddress = "https://wordpress.com/checkout/"
        static let noSiteCheckoutWebAddress = "https://wordpress.com/checkout/no-site?isDomainOnly=1"
        // store sandbox cookie
        static let storeSandboxCookieName = "store_sandbox"
        static let storeSandboxCookieDomain = ".wordpress.com"
    }
}
