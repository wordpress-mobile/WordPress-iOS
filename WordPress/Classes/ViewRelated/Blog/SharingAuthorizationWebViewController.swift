import WebKit
import CoreMedia

/// Used to detect whether a URL matches a particular Publicize authorization success or failure route.
enum PublicizeAuthorizationURLComponents {
    case verifyActionItem
    case denyActionItem
    case requestActionItem
    case stateItem
    case codeItem
    case errorItem

    case authorizationPrefix
    case declinePath
    case accessDenied

    // Special handling for the inconsistent way that services respond to a user's choice to decline
    // oauth authorization.
    // Right now we have no clear way to know if Tumblr fails.  This is something we should try
    // fixing moving forward.
    // Path does not set the action param or call the callback. It forwards to its own URL ending in /decline.
    case userRefused

    // In most cases, we attempt to find a matching URL by checking for a specific URL component
    private var queryItem: URLQueryItem? {
        switch self {
        case .verifyActionItem:
            return URLQueryItem(name: "action", value: "verify")
        case .denyActionItem:
            return URLQueryItem(name: "action", value: "deny")
        case .requestActionItem:
            return URLQueryItem(name: "action", value: "request")
        case .accessDenied:
            return URLQueryItem(name: "error", value: "access_denied")
        case .stateItem:
            return URLQueryItem(name: "state", value: nil)
        case .codeItem:
            return URLQueryItem(name: "code", value: nil)
        case .errorItem:
            return URLQueryItem(name: "error", value: nil)
        case .userRefused:
            return URLQueryItem(name: "oauth_problem", value: "user_refused")
        default:
            return nil
        }
    }

    // In a handful of cases, we're just looking for a substring or prefix in the URL
    private var matchString: String? {
        switch self {
        case .declinePath:
            return "/decline"
        case .authorizationPrefix:
            return "https://public-api.wordpress.com/connect/"
        default:
            return nil
        }
    }

    /// @return True if the url matches the current authorization component
    ///
    func containedIn(_ url: URL) -> Bool {
        if let _ = queryItem {
            return queryItemContainedIn(url)
        }

        return stringContainedIn(url)
    }

    // Checks to see if the current QueryItem is present in the specified URL
    private func queryItemContainedIn(_ url: URL) -> Bool {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
              let queryItem = queryItem else {
                  return false
              }

        return queryItems.contains(where: { urlItem in
            var result = urlItem.name == queryItem.name

            if let value = queryItem.value {
                result = result && (urlItem.value == value)
            }

            return result
        })
    }

    // Checks to see if the current matchString is present in the specified URL
    private func stringContainedIn(_ url: URL) -> Bool {
        guard let matchString = matchString else {
            return false
        }

        switch self {
        case .declinePath:
            return url.path.contains(matchString)
        case .authorizationPrefix:
            return url.absoluteString.hasPrefix(matchString)
        default:
            return url.absoluteString.contains(matchString)
        }
    }
}

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
    enum AuthorizeAction: Int {
        case none
        case unknown
        case request
        case verify
        case deny
    }

    private static let loginURL = "https://wordpress.com/wp-login.php"

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

    func authorizeAction(from url: URL) -> AuthorizeAction {
        // Path oauth declines are handled by a redirect to a path.com URL, so check this first.
        if PublicizeAuthorizationURLComponents.declinePath.containedIn(url) {
            return .deny
        }

        if !url.absoluteString.hasPrefix("https://public-api.wordpress.com/connect/") {
            return .none
        }
//        if !url.absoluteString.hasPrefix(PublicizeAuthorizationURLComponents.authorizationPrefix.rawValue) {
//            return .none
//        }

        if PublicizeAuthorizationURLComponents.requestActionItem.containedIn(url) {
            return .request
        }

        // Check the rest of the various decline ranges
        if PublicizeAuthorizationURLComponents.denyActionItem.containedIn(url) {
            return .deny
        }

        // LinkedIn
        if PublicizeAuthorizationURLComponents.userRefused.containedIn(url) {
            return .deny
        }

        // Facebook and Google+
        if PublicizeAuthorizationURLComponents.accessDenied.containedIn(url) {
            return .deny
        }

        // If we've made it this far and verifyRange is found then we're *probably*
        // verifying the oauth request.  There are edge cases ( :cough: tumblr :cough: )
        // where verification is declined and we get a false positive.
        if PublicizeAuthorizationURLComponents.verifyActionItem.containedIn(url) {
            return .verify
        }

        // Facebook
        if PublicizeAuthorizationURLComponents.stateItem.containedIn(url) && PublicizeAuthorizationURLComponents.codeItem.containedIn(url) {
            return .verify
        }

        // Facebook failure
        if PublicizeAuthorizationURLComponents.stateItem.containedIn(url) && PublicizeAuthorizationURLComponents.errorItem.containedIn(url) {
            return .unknown
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
