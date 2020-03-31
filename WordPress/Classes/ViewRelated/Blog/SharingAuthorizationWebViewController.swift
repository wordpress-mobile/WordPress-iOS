import WebKit

@objc
protocol SharingAuthorizationDelegate: NSObjectProtocol {
    @objc
    func authorize(_ publicizer: PublicizeService, didFailWithError error: NSError)

    @objc
    func authorizeDidSucceed(_ publicizer: PublicizeService)

    @objc
    func authorizeDidCancel(_ publicizer: PublicizeService)
}

@objc
class SharingAuthorizationWebViewController: WPWebViewController {
    /// Classify actions taken by the web API
    ///
    private enum AuthorizeAction: Int {
        case none
        case unknown
        case request
        case verify
        case deny
    }

    private static let loginURL = "https://wordpress.com/wp-login.php"
    private static let authorizationPrefix = "https://public-api.wordpress.com/connect/"
    private static let requestActionParameter = "action=request"
    private static let verifyActionParameter = "action=verify"
    private static let denyActionParameter = "action=deny"

    // Special handling for the inconsistent way that services respond to a user's choice to decline
    // oauth authorization.
    // Right now we have no clear way to know if Tumblr fails.  This is something we should try
    // fixing moving forward.
    // Path does not set the action param or call the callback. It forwards to its own URL ending in /decline.
    private static let declinePath = "/decline"
    private static let userRefused = "oauth_problem=user_refused"
    private static let authorizationDenied = "denied="
    private static let accessDenied = "error=access_denied"

    /// Verification loading -- dismiss on completion
    ///
    private var loadingVerify: Bool = false

    /// Publicize service being authorized
    ///
    private let publicizer: PublicizeService

    private var hosts = [String]()

    private weak var delegate: SharingAuthorizationDelegate?

    @objc
    init(with publicizer: PublicizeService, url: URL, for blog: Blog, delegate: SharingAuthorizationDelegate) {
        self.delegate = delegate
        self.publicizer = publicizer

        super.init(nibName: "WPWebViewController", bundle: nil)

        self.authenticator = RequestAuthenticator(blog: blog)
        self.secureInteraction = true
        self.url = url
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     // MARK: - View Lifecycle

     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)

         cleanupCookies()
     }

    // MARK: - Cookies Management

    /// Saves the host from the specidied URL for cleaning up cookies when done.
    ///
    /// - Parameters:
    ///     - url: the URL to retrieve the host from.
    ///
    func saveHostForCookiesCleanup(from url: URL) {
        guard let host = url.host,
            !host.contains("wordpress"),
            !hosts.contains(host) else {
                return
        }

        let components = host.components(separatedBy: ".")

        // A bit of paranioa here. The components should never be less than two but just in case...
        guard let hostName = components.count > 1 ? components[components.count - 2] : components.first else {
            return
        }

        hosts.append(hostName)
    }

    /// Cleanup cookies
    ///
    func cleanupCookies() {
        let storage = HTTPCookieStorage.shared

        guard let cookies = storage.cookies else {
            // Nothing to cleanup
            return
        }

        for cookie in cookies {
            for host in hosts {
                if cookie.domain.contains(host) {
                    storage.deleteCookie(cookie)
                }
            }
        }
    }

    // MARK: - Misc

    @IBAction
    override func dismiss() {
        guard let delegate = delegate else {
            super.dismiss()
            return
        }

        delegate.authorizeDidCancel(publicizer)
    }

    private func handleAuthorizationAllowed() {
        // Note: There are situations where this can be called in error due to how
        // individual services choose to reply to an authorization request.
        // Delegates should expect to handle a false positive.
        delegate?.authorizeDidSucceed(publicizer)
    }

    private func displayLoadError(error: NSError) {
        delegate?.authorize(self.publicizer, didFailWithError: error)
    }

    // MARK: - URL Interpretation

    private func authorizeAction(from url: URL) -> AuthorizeAction {
        let requested = url.absoluteString

        // Path oauth declines are handled by a redirect to a path.com URL, so check this first.
        if requested.range(of: SharingAuthorizationWebViewController.declinePath) != nil {
            return .deny
        }

        if !requested.hasPrefix(SharingAuthorizationWebViewController.authorizationPrefix) {
            return .none
        }

        if requested.range(of: SharingAuthorizationWebViewController.requestActionParameter) != nil {
            return .request
        }

        // Check the rest of the various decline ranges
        if requested.range(of: SharingAuthorizationWebViewController.denyActionParameter) != nil {
            return .deny
        }

        // LinkedIn
        if requested.range(of: SharingAuthorizationWebViewController.userRefused) != nil {
            return .deny
        }

        // Facebook and Google+
        if requested.range(of: SharingAuthorizationWebViewController.accessDenied) != nil {
            return .deny
        }

        // If we've made it this far and verifyRange is found then we're *probably*
        // verifying the oauth request.  There are edge cases ( :cough: tumblr :cough: )
        // where verification is declined and we get a false positive.
        if requested.range(of: SharingAuthorizationWebViewController.verifyActionParameter) != nil {
            return .verify
        }

        return .unknown
    }
}

// MARK: - WKNavigationDelegate

extension SharingAuthorizationWebViewController {

    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // Prevent a second verify load by someone happy clicking.
        guard !loadingVerify,
            let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
        }

        let action = authorizeAction(from: url)

        switch action {
        case .none:
            fallthrough
        case .unknown:
            fallthrough
        case .request:
            super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
            return
        case .verify:
            loadingVerify = true
            decisionHandler(.allow)
            return
        case .deny:
            decisionHandler(.cancel)
            dismiss()
            return
        }
    }

    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if loadingVerify && (error as NSError).code == NSURLErrorCancelled {
            // Authenticating to Facebook and Twitter can return an false
            // NSURLErrorCancelled (-999) error. However the connection still succeeds.
            handleAuthorizationAllowed()
            return
        }

        super.webView(webView, didFail: navigation, withError: error)
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            saveHostForCookiesCleanup(from: url)
        }

        if loadingVerify {
            handleAuthorizationAllowed()
        } else {
            super.webView(webView, didFinish: navigation)
        }
    }
}
