import UIKit
import AutomatticTracks
import Sentry

final class SiteCreationPurchasingWebFlowController {

    // MARK: - Constants

    fileprivate enum Constants {
        static let wordpressBaseURL = "https://wordpress.com"
        static let checkoutWebAddress = "\(wordpressBaseURL)/checkout"
        static let checkoutSuccessURLPrefix = "\(checkoutWebAddress)/thank-you/"
        static let storeSandboxCookieName = "store_sandbox"
        static let storeSandboxCookieDomain = ".wordpress.com"
    }

    // MARK: - Dependencies

    /// The view controller that presents the domain checkout web page.
    weak private var presentingViewController: UIViewController?

    /// The service that interacts with the Backend API.
    private let shoppingCartService: ShoppingCartServiceProtocol

    /// Provides an API to capture errors.
    private let crashLogger: CrashLogging

    /// The domain purchasing web view can be presented from multiple sources.
    /// This property represents this source, and it's used mostly for analytics.
    private let origin: SiteCreationWebViewViewOrigin?

    // MARK: - Execution Variables

    /// Set when a domain checkout web page is presented.
    private weak var presentedViewController: UINavigationController?

    /// Observe url changes and it is set when a domain checkout web page is presented.
    private var webViewURLChangeObservation: NSKeyValueObservation?

    // MARK: - Init

    init(viewController: UIViewController,
         shoppingCartService: ShoppingCartServiceProtocol = ShoppingCartService(),
         crashLogger: CrashLogging = .main,
         origin: SiteCreationWebViewViewOrigin? = nil) {
        self.presentingViewController = viewController
        self.shoppingCartService = shoppingCartService
        self.crashLogger = crashLogger
        self.origin = origin
    }

    // MARK: - API

    func purchase(domain: FullyQuotedDomainSuggestion, planId: Int, site: Blog, completion: CompletionHandler? = nil) {
        purchase(domain: domain.remoteSuggestion(), planId: planId, site: site, completion: completion)
    }

    func purchase(domain: DomainSuggestion, planId: Int, site: Blog, completion: CompletionHandler? = nil) {
        let middleware = self.middleware(for: completion, domain: domain, site: site)
        guard let presentingViewController else {
            middleware(.failure(.internal("The presentingViewController is deallocated")))
            return
        }
        guard let domain = Domain(domain: domain, site: site) else {
            middleware(.failure(.invalidInput))
            return
        }
        self.createCartAndPresentWebView(domain: domain, planId: planId, in: presentingViewController, completion: middleware)
    }

    // MARK: - Private: Completion Middleware

    /// Process the domain purchasing result before handing it over to the caller.
    private func middleware(for completion: CompletionHandler?, domain: DomainSuggestion, site: Blog) -> CompletionHandler {
        return { [weak self] result in
            if let self = self {
                self.handleError(result: result, domain: domain, site: site)
                self.trackCompletionEvents(result: result, domain: domain, site: site)
            }
            if let completion {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    /// Logs the error in case the domain purchasing resulted in a failure.
    private func handleError(result: Result<String, SiteCreationPurchasingError>, domain: DomainSuggestion, site: Blog) {
        guard case let .failure(error) = result, !error.trusted else {
            return
        }
        let userInfo = self.userInfoForError(error, domain: domain, site: site)
        self.crashLogger.logError(error, userInfo: userInfo, level: error.level)
    }

    /// Tracks domain purchasing analytics when it completes.
    private func trackCompletionEvents(result: Result<String, SiteCreationPurchasingError>, domain: DomainSuggestion, site: Blog) {
        guard case .success = result else {
            return
        }
        self.trackDomainPurchasingSucceeded(blog: site)
    }

    // MARK: - Private: Doman Purchasing

    private func createCartAndPresentWebView(domain: Domain, planId: Int, in presentingViewController: UIViewController, completion: CompletionHandler? = nil) {
        self.shoppingCartService.makeSiteCreationShoppingCart(
            siteID: domain.siteID,
            domainSuggestion: domain.underlyingDomain,
            privacyProtectionEnabled: domain.supportsPrivacy,
            planId: planId,
            success: { [weak self] _ in
                self?.presentWebViewForCurrentSite(domain: domain, in: presentingViewController, completion: completion)
            }) { error in
                completion?(.failure(.other(error)))
            }
    }

    private func presentWebViewForCurrentSite(domain: Domain, in presentingViewController: UIViewController, completion: CompletionHandler? = nil) {
        // Clean up properties from previous domain purchasing execution.
        self.cleanupExecutionVariables()

        // WORKAROUND: The reason why we have to use this mechanism to detect success and failure conditions
        // for domain registration is because our checkout process (for some unknown reason) doesn't trigger
        // call to WKWebViewDelegate methods.
        //
        // This was last checked by @diegoreymendez on 2021-09-22.
        //
        var result: Result<String, SiteCreationPurchasingError>?
        let webViewController = WebViewControllerFactory.controllerWithDefaultAccountAndSecureInteraction(
            url: domain.hostURL,
            source: origin?.rawValue ?? ""
        )
        self.webViewURLChangeObservation = webViewController.webView.observe(\.url, options: [.new, .old]) { [weak self] _, change in
            guard let self = self, let newURL = change.newValue as? URL else {
                return
            }
            let oldURL = change.oldValue as? URL
            self.handleWebViewURLChange(newURL, oldURL: oldURL, domain: domain) { innerResult in
                result = innerResult
                self.presentedViewController?.dismiss(animated: true)
            }
        }

        // 1. Inject sandbox store cookie
        // 2. Present a new web view instance or reload the existing one.
        let cookieStore = webViewController.webView.configuration.websiteDataStore.httpCookieStore
        self.injectSandboxStoreCookie(into: cookieStore) { [weak self] _ in
            guard let self else {
                return
            }
            if let presentedViewController = self.presentedViewController {
                presentedViewController.setViewControllers([webViewController], animated: false)
            } else {
                let navController = SiteCreationPurchasingNavigationController(rootViewController: webViewController)
                navController.onDismiss = {
                    let result = result ?? .failure(.canceled)
                    self.completeSiteCreationPurchasing(result: result, completion: completion)
                }
                presentingViewController.present(navController, animated: true)
                self.presentedViewController = navController
            }
            self.trackDomainCheckoutWebViewViewed(blog: domain.underlyingSite)
        }
    }

    /// Calls the completion handler with the result and clean up observation properties.
    private func completeSiteCreationPurchasing(result: Result<String, SiteCreationPurchasingError>, completion: CompletionHandler? = nil) {
        self.cleanupExecutionVariables()
        completion?(result)
    }

    /// Injects the sandbox store cookie into the cookie store.
    private func injectSandboxStoreCookie(into cookieStore: WKHTTPCookieStore, completion: @escaping (Bool) -> Void) {
        if let storeSandboxCookie = (HTTPCookieStorage.shared.cookies?.first {
            $0.properties?[.name] as? String == Constants.storeSandboxCookieName &&
            $0.properties?[.domain] as? String == Constants.storeSandboxCookieDomain
        }) {
            cookieStore.getAllCookies { cookies in
                var newCookies = cookies
                newCookies.append(storeSandboxCookie)
                cookieStore.setCookies(newCookies) {
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }

    /// Handles URL changes in the web view.  We only allow the user to stay within certain URLs.  Falling outside these URLs
    /// results in the web view being dismissed.  This method also handles the success condition for a successful domain registration
    /// through said web view.
    ///
    /// - Parameters:
    ///     - newURL: the newly set URL for the web view.
    ///     - siteID: the ID of the site we're trying to register the domain against.
    ///     - domain: the domain the user is purchasing.
    ///     - completion: the closure that will be executed when the domain registration succeeds or fails.
    ///
    private func handleWebViewURLChange(
        _ newURL: URL,
        oldURL: URL?,
        domain: Domain,
        completion: (Result<String, SiteCreationPurchasingError>) -> Void
    ) {
        let canOpenNewURL = newURL.absoluteString.starts(with: Constants.checkoutWebAddress)
        guard canOpenNewURL else {
            let error = SiteCreationPurchasingError.unsupportedRedirect(fromURL: oldURL, toURL: newURL)
            completion(.failure(error))
            return
        }

        let domainRegistrationSucceeded = newURL.absoluteString.starts(with: Constants.checkoutSuccessURLPrefix)

        if domainRegistrationSucceeded {
            completion(.success(domain.domainName))
        }
    }

    /// Nullifies the variables that were set during a domain purchasing execution. In other words, it nullifies the variables under "Execution Variables" pragma mark.
    private func cleanupExecutionVariables() {
        self.webViewURLChangeObservation?.invalidate()
        self.webViewURLChangeObservation = nil
    }

    /// Metadata to attach to error or track events.
    private func userInfo(domain: DomainSuggestion, site: Blog) -> [String: Any] {
        let homeURL = site.homeURL as String?
        var userInfo: [String: Any] = [
            "siteID": site.dotComID?.intValue as Any,
            "siteHomeURL": homeURL as Any,
            "siteHostURL": URL(string: homeURL ?? "")?.host as Any,
            "domainName": domain.domainName,
            "domainSupportsPrivacy": domain.supportsPrivacy as Any,
            "checkoutWebAddress": Self.Constants.checkoutWebAddress,
        ]
        if let presentingViewController {
            userInfo["presentingViewController"] = String(describing: type(of: presentingViewController))
        }
        return userInfo
    }

    /// Metadata to attach when capturing errors.
    private func userInfoForError(_ error: SiteCreationPurchasingError, domain: DomainSuggestion, site: Blog) -> [String: Any] {
        var userInfo = userInfo(domain: domain, site: site)
        userInfo = userInfo.merging(error.errorUserInfo) { $1 }
        return userInfo
    }

    // MARK: - Types

    typealias CompletionHandler = (Result<String, SiteCreationPurchasingError>) -> Void

    enum SiteCreationPurchasingError: LocalizedError {
        case invalidInput
        case canceled
        case unsupportedRedirect(fromURL: URL?, toURL: URL)
        case `internal`(String)
        case other(Error)
    }

    /// Encapsulates the input needed for the domain purchasing logic.
    fileprivate struct Domain {
        let underlyingDomain: DomainSuggestion
        let underlyingSite: Blog

        let siteID: Int
        let homeURL: URL
        let hostURL: URL

        var domainName: String {
            return underlyingDomain.domainName
        }

        var supportsPrivacy: Bool {
            return underlyingDomain.supportsPrivacy ?? false
        }
    }
}

// MARK: - Analytics Helpers

private extension SiteCreationPurchasingWebFlowController {

    func trackDomainCheckoutWebViewViewed(blog: Blog) {
        let properties = WPAnalytics.domainsProperties(for: blog, origin: origin)
        WPAnalytics.track(.domainsPurchaseWebviewViewed, properties: properties, blog: blog)
    }

    func trackDomainPurchasingSucceeded(blog: Blog) {
        let properties = WPAnalytics.domainsProperties(for: blog, origin: origin)
        WPAnalytics.track(.domainsPurchaseSucceeded, properties: properties, blog: blog)
    }
}

// MARK: - Subtypes Extensions

extension SiteCreationPurchasingWebFlowController.Domain {

    init?(domain: DomainSuggestion, site: Blog) {
        guard let siteID = site.dotComID?.intValue,
              let homeURLString = site.homeURL,
              let homeURL = URL(string: homeURLString as String),
              let hostURLString = homeURL.host,
              let hostURL = URL(string: SiteCreationPurchasingWebFlowController.Constants.checkoutWebAddress + "/\(hostURLString)")
        else {
            return nil
        }
        self.underlyingSite = site
        self.underlyingDomain = domain
        self.siteID = siteID
        self.homeURL = homeURL
        self.hostURL = hostURL
    }
}

extension SiteCreationPurchasingWebFlowController.SiteCreationPurchasingError: CustomNSError, CustomDebugStringConvertible {

    /// Untrusted errors should be monitored and requires our attention.
    var trusted: Bool {
        switch self {
        case .canceled, .other: return true
        default: return false
        }
    }

    var level: SeverityLevel {
        switch self {
        case .unsupportedRedirect: return .warning
        default: return .error
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidInput: return "The input provided is not valid to perform domain purchasing"
        case .canceled: return "Domain purchasing flow is canceled"
        case .unsupportedRedirect: return "Unsupported domain purchasing URL"
        case .internal(let reason): return reason
        case .other(let error): return (error as NSError).localizedDescription
        }
    }

    var errorCode: Int {
        switch self {
        case .canceled: return 400
        case .invalidInput: return 500
        case .internal: return 501
        case .unsupportedRedirect: return 502
        case .other(let error): return 1000 + (error as NSError).code
        }
    }

    static var errorDomain: String {
        return "DomainPurchasingWebFlowError"
    }

    var debugDescription: String {
        let desc = errorDescription ?? String(describing: self)
        return "[\(Self.errorDomain)] \(desc)"
    }

    var errorUserInfo: [String: Any] {
        var userInfo = [String: Any]()
        switch self {
        case .unsupportedRedirect(let fromURL, let toURL):
            userInfo["fromURL"] = fromURL?.absoluteString
            userInfo["toURL"] = toURL.absoluteString
        default:
            break
        }
        return userInfo
    }

    typealias SeverityLevel = SentryLevel
}

// MARK: - Custom Navigation Controller

/// Custom navigation controller to detect when the domain checkout web view is dimissed.
///
/// This way, we guarantee that `onDismiss` will be called whether the screen was dismissed by tapping "X" button, using the swipe down gesture,
/// or even if the system decided to dismiss the screen.
private class SiteCreationPurchasingNavigationController: UINavigationController {

    var onDismiss: (() -> Void)?

    deinit {
        onDismiss?()
    }
}
